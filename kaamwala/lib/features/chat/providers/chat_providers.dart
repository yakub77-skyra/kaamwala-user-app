/// Chat providers - the single place that owns chat state per booking.
///
/// [ChatController] is autoDispose + family(bookingId): it loads history,
/// owns the realtime channel (cleanup on dispose), tracks connection state
/// with backoff re-subscription, optimistic send/retry with idempotent ids,
/// typing (debounced broadcast), pagination and unread counts. Screens only
/// read state and call high-level actions.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/chat/chat_helpers.dart';
import 'package:kaamwala/features/chat/models/chat_message.dart';
import 'package:kaamwala/features/chat/repositories/chat_repository.dart';
import 'package:kaamwala/features/shared/providers/connectivity_provider.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

final chatRepoProvider = Provider((_) => const ChatRepository());

enum ChatConnectionState { connecting, connected, disconnected, reconnecting }

class ChatState {
  const ChatState({
    this.messages = const [],
    this.connection = ChatConnectionState.connecting,
    this.otherTyping = false,
    this.loadingOlder = false,
    this.hasMore = true,
    this.initialError = false,
    this.unread = 0,
  });

  final List<ChatMessage> messages;
  final ChatConnectionState connection;
  final bool otherTyping;
  final bool loadingOlder;
  final bool hasMore;
  final bool initialError;
  final int unread;

  bool get disconnected => connection == ChatConnectionState.disconnected;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatConnectionState? connection,
    bool? otherTyping,
    bool? loadingOlder,
    bool? hasMore,
    bool? initialError,
    int? unread,
  }) => ChatState(
    messages: messages ?? this.messages,
    connection: connection ?? this.connection,
    otherTyping: otherTyping ?? this.otherTyping,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    hasMore: hasMore ?? this.hasMore,
    initialError: initialError ?? this.initialError,
    unread: unread ?? this.unread,
  );
}

class ChatController extends AutoDisposeFamilyAsyncNotifier<ChatState, String> {
  ChatRepository get _repo => ref.read(chatRepoProvider);

  String get _bookingId => arg;

  String? _myId;
  String? _receiverId;
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _typingExpiry;
  TypingDebouncer? _typingDebouncer;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _everConnected = false;
  bool _hasMore = true;
  DateTime? _oldest;

  @override
  Future<ChatState> build(String bookingId) async {
    _disposed = false;
    _myId = SupabaseService.currentUserId;
    final initial = await _loadPage(before: null);
    _hasMore = initial.messages.length == ChatRepository.pageSize;
    _oldest = initial.messages.isEmpty
        ? null
        : initial.messages.first.createdAt;
    _startRealtime();
    ref.onDispose(_dispose);
    // Network drop -> reconnect when the device comes back.
    ref.listen(connectivityProvider, (prev, online) {
      if (online && _channel == null) _scheduleReconnect();
    });
    unawaited(_resolveReceiver());
    unawaited(_markRead());
    return ChatState(
      messages: initial.messages,
      initialError: initial.error,
      hasMore: _hasMore,
      unread: initial.unread,
    );
  }

  // ---------------- realtime + connection ----------------

  void _startRealtime() {
    if (_disposed) return;
    _typingDebouncer = TypingDebouncer(
      onChange: (typing) {
        final ch = _channel;
        final uid = _myId;
        if (ch == null || uid == null) return;
        _repo.sendTyping(ch, userId: uid, typing: typing);
        unawaited(
          AnalyticsService.logEvent(
            typing ? 'typing_started' : 'typing_stopped',
          ),
        );
      },
    );
    final ch = _repo.subscribe(
      _bookingId,
      onInsert: _onInsert,
      onUpdate: _onUpdate,
      onTyping: _onTypingEvent,
      onStatus: _onStatus,
    );
    _channel = ch;
  }

  void _onStatus(RealtimeSubscribeStatus status, Object? error) {
    if (_disposed) return;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        final wasConnected = _everConnected;
        _everConnected = true;
        _set(connection: ChatConnectionState.connected);
        // Refresh on every re-subscription (socket drops / resubscribe), not
        // on the first join (initial load already fetched).
        if (wasConnected) unawaited(_refreshAfterReconnect());
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
        _set(connection: ChatConnectionState.reconnecting);
        _scheduleReconnect();
      case RealtimeSubscribeStatus.closed:
        _set(connection: ChatConnectionState.disconnected);
        _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final delay = Duration(
      milliseconds: 1000 * (1 << _reconnectAttempt.clamp(0, 4)),
    );
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () {
      if (_disposed) return;
      // Resubscribe on a fresh channel (subscribe() is one-shot per channel).
      final old = _channel;
      _channel = null;
      if (old != null) unawaited(ChatRepository.unsubscribe(old));
      _startRealtime();
    });
  }

  Future<void> _refreshAfterReconnect() async {
    unawaited(AnalyticsService.logEvent('chat_reconnected'));
    final page = await _loadPage(before: null);
    final current = state.value;
    if (current == null || _disposed) return;
    _set(messages: mergeMessages(current.messages, page.messages));
    unawaited(_markRead());
  }

  void _onInsert(ChatMessage message) {
    if (_disposed) return;
    final current = state.value;
    if (current == null) return;
    var unread = current.unread;
    if (_isMine(message) == false &&
        !message.isSystem &&
        message.readAt == null) {
      unread++;
    }
    _set(messages: mergeMessages(current.messages, [message]), unread: unread);
    // Viewer is inside the conversation -> instantly read the new message.
    unawaited(_markRead());
  }

  void _onUpdate(ChatMessage message) {
    if (_disposed) return;
    final current = state.value;
    if (current == null) return;
    final old = current.messages.where((m) => m.id == message.id).firstOrNull;
    var unread = current.unread;
    if (old != null &&
        old.readAt == null &&
        message.readAt != null &&
        _isMine(message) == false &&
        unread > 0) {
      unread--;
    }
    _set(messages: mergeMessages(current.messages, [message]), unread: unread);
  }

  void _onTypingEvent(String userId, bool typing) {
    if (_disposed || userId == _myId) return;
    _typingExpiry?.cancel();
    if (typing) {
      _set(otherTyping: true);
      _typingExpiry = Timer(const Duration(seconds: 4), () {
        if (!_disposed) _set(otherTyping: false);
      });
    } else {
      _set(otherTyping: false);
    }
  }

  // ---------------- sending ----------------

  Future<bool> sendText(String raw) async {
    final uid = _myId;
    final String text;
    try {
      text = validateTextDraft(raw);
    } on DraftValidationException {
      return false;
    }
    if (uid == null) return false;
    final local = ChatMessage(
      id: chatLocalId(),
      bookingId: _bookingId,
      senderId: uid,
      receiverId: _receiverId,
      type: ChatMessageType.text,
      content: text,
      status: ChatMessageStatus.sending,
      isLocal: true,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
    _appendLocal(local);
    unawaited(AnalyticsService.logEvent('message_sent', {'type': 'text'}));
    final ok = await _deliver(local);
    if (ok) unawaited(AnalyticsService.logEvent('text_message_sent'));
    return ok;
  }

  /// Sends a photo with optimistic UI. Returns the local message id (needed
  /// by the UI to display the picked bytes); null only when not signed in.
  Future<String?> sendImage(ImageDraft draft) async {
    final uid = _myId;
    if (uid == null) return null;
    final local = ChatMessage(
      id: chatLocalId(),
      bookingId: _bookingId,
      senderId: uid,
      receiverId: _receiverId,
      type: ChatMessageType.image,
      content: 'Photo',
      status: ChatMessageStatus.sending,
      isLocal: true,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      uploadProgress: 0,
    );
    _appendLocal(local);
    unawaited(AnalyticsService.logEvent('chat_image_upload_started'));
    final path = await _uploadImage(local, draft);
    if (_disposed) return local.id;
    if (path == null) {
      _failLocal(local.id);
      unawaited(AnalyticsService.logEvent('chat_image_upload_failed'));
      return local.id;
    }
    final withUrl = local.copyWith(imageUrl: path, thumbnailUrl: path);
    _replaceLocal(local.id, withUrl);
    final ok = await _deliver(withUrl);
    if (ok) unawaited(AnalyticsService.logEvent('image_message_sent'));
    return local.id;
  }

  /// Re-uploads + re-delivers a failed image message with the SAME id
  /// (idempotent). The UI re-picks the photo and passes it here.
  Future<bool> resendImage(ImageDraft draft, String messageId) async {
    final current = state.value;
    final m = current?.messages.where((x) => x.id == messageId).firstOrNull;
    if (m == null) return false;
    final local = m.copyWith(
      status: ChatMessageStatus.sending,
      uploadProgress: 0,
      isLocal: true,
    );
    _replaceLocal(messageId, local);
    unawaited(AnalyticsService.logEvent('message_retry_tapped'));
    unawaited(AnalyticsService.logEvent('chat_image_upload_started'));
    final path = await _uploadImage(local, draft);
    if (_disposed) return false;
    if (path == null) {
      _failLocal(messageId);
      unawaited(AnalyticsService.logEvent('chat_image_upload_failed'));
      return false;
    }
    final withUrl = local.copyWith(imageUrl: path, thumbnailUrl: path);
    _replaceLocal(messageId, withUrl);
    final ok = await _deliver(withUrl);
    if (ok) unawaited(AnalyticsService.logEvent('image_message_sent'));
    return ok;
  }

  Future<bool> sendLocation(LocationDraft draft) async {
    final uid = _myId;
    if (uid == null) return false;
    final local = ChatMessage(
      id: chatLocalId(),
      bookingId: _bookingId,
      senderId: uid,
      receiverId: _receiverId,
      type: ChatMessageType.location,
      content: draft.label ?? 'Location',
      locationLat: draft.lat,
      locationLng: draft.lng,
      locationLabel: draft.label,
      metadata: draft.accuracy == null
          ? const {}
          : {'accuracy': draft.accuracy},
      status: ChatMessageStatus.sending,
      isLocal: true,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
    );
    _appendLocal(local);
    unawaited(AnalyticsService.logEvent('chat_location_shared'));
    final ok = await _deliver(local);
    if (ok) unawaited(AnalyticsService.logEvent('location_message_sent'));
    return ok;
  }

  Future<String?> _uploadImage(ChatMessage local, ImageDraft draft) async {
    final res = await _repo.uploadImage(
      bookingId: _bookingId,
      messageId: local.id,
      bytes: draft.bytes,
      mimeType: draft.mimeType,
      onProgress: (p) {
        if (!_disposed) {
          _updateLocal(local.id, (m) => m.copyWith(uploadProgress: p));
        }
      },
    );
    return switch (res) {
      Success(:final data) => data,
      Error() => null,
    };
  }

  /// Inserts the server row and reconciles the local copy. Idempotent via the
  /// client-generated id - a retry after a network hiccup never duplicates.
  Future<bool> _deliver(ChatMessage local) async {
    final res = await _repo.insertMessage(local);
    if (_disposed) return false;
    return switch (res) {
      Success(:final data) => _finalize(local.id, data),
      Error() => _failLocal(local.id),
    };
  }

  bool _finalize(String localId, ChatMessage serverRow) {
    final current = state.value;
    if (current == null) return false;
    _set(messages: mergeMessages(current.messages, [serverRow]));
    return true;
  }

  bool _failLocal(String id) {
    _updateLocal(id, (m) => m.copyWith(status: ChatMessageStatus.failed));
    unawaited(AnalyticsService.logEvent('message_send_failed'));
    return false;
  }

  /// Retries a failed message (same id -> idempotent server insert).
  Future<bool> retry(ChatMessage message) async {
    if (!message.isFailed) return false;
    unawaited(AnalyticsService.logEvent('message_retry_tapped'));
    final retrying = message.copyWith(status: ChatMessageStatus.sending);
    _updateLocal(message.id, (_) => retrying);
    if (retrying.type == ChatMessageType.image &&
        (retrying.imageUrl == null || retrying.imageUrl!.isEmpty)) {
      // Original bytes were never persisted - the UI must re-pick the photo.
      _updateLocal(
        message.id,
        (m) => m.copyWith(status: ChatMessageStatus.failed),
      );
      return false;
    }
    return _deliver(retrying);
  }

  // ---------------- history / read ----------------

  Future<({List<ChatMessage> messages, bool error, int unread})> _loadPage({
    required DateTime? before,
  }) async {
    final history = await _repo.history(_bookingId, before: before);
    final uid = _myId;
    return switch (history) {
      Success(:final data) => (
        messages: data,
        error: false,
        unread: uid == null
            ? 0
            : switch (await _repo.unreadCount(
                bookingId: _bookingId,
                uid: uid,
              )) {
                Success(:final data) => data,
                Error() => 0,
              },
      ),
      Error() => (messages: <ChatMessage>[], error: true, unread: 0),
    };
  }

  Future<void> loadOlder() async {
    final current = state.value;
    if (current == null || current.loadingOlder || !_hasMore) return;
    _set(loadingOlder: true);
    final page = await _loadPage(before: _oldest);
    if (_disposed) return;
    if (page.messages.length < ChatRepository.pageSize) _hasMore = false;
    if (page.messages.isNotEmpty) _oldest = page.messages.first.createdAt;
    _set(
      messages: mergeMessages(current.messages, page.messages),
      loadingOlder: false,
      hasMore: _hasMore,
    );
  }

  Future<void> _markRead() async {
    final uid = _myId;
    if (uid == null) return;
    await _repo.markRead(bookingId: _bookingId, readerId: uid);
    if (_disposed) return;
    final current = state.value;
    if (current != null && current.unread != 0) {
      _set(unread: 0);
    }
    // Badges on other screens (booking list, job cards) must catch up.
    ref.invalidate(chatUnreadProvider(_bookingId));
  }

  Future<void> _resolveReceiver() async {
    final uid = _myId;
    if (uid == null) return;
    final res = await _repo.counterpartId(_bookingId);
    if (_disposed) return;
    if (res case Success(:final data) when data != null) {
      _receiverId = data;
    }
  }

  /// Called by the screen on app resume (foreground) - resubscribe if the
  /// channel died and refresh recent messages.
  Future<void> onAppResumed() async {
    if (_disposed) return;
    if (_channel == null) {
      _scheduleReconnect();
    }
    await _refreshAfterReconnect();
  }

  /// Screen input changed - debounces the typing broadcast.
  void typingChanged() {
    _typingDebouncer?.onKeystroke();
  }

  void typingStopped() {
    _typingDebouncer?.stop();
  }

  // ---------------- state helpers ----------------

  bool? _isMine(ChatMessage m) => _myId == null ? null : m.senderId == _myId;

  void _appendLocal(ChatMessage m) {
    final current = state.value;
    if (current == null) return;
    _set(messages: mergeMessages(current.messages, [m]));
  }

  void _updateLocal(String id, ChatMessage Function(ChatMessage) fn) {
    final current = state.value;
    if (current == null) return;
    _set(messages: [for (final m in current.messages) m.id == id ? fn(m) : m]);
  }

  void _replaceLocal(String id, ChatMessage replacement) =>
      _updateLocal(id, (_) => replacement);

  void _set({
    List<ChatMessage>? messages,
    ChatConnectionState? connection,
    bool? otherTyping,
    bool? loadingOlder,
    bool? hasMore,
    bool? initialError,
    int? unread,
  }) {
    final current = state.value ?? const ChatState();
    state = AsyncData(
      current.copyWith(
        messages: messages,
        connection: connection,
        otherTyping: otherTyping,
        loadingOlder: loadingOlder,
        hasMore: hasMore,
        initialError: initialError,
        unread: unread,
      ),
    );
  }

  void _dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _typingExpiry?.cancel();
    _typingDebouncer?.dispose();
    final ch = _channel;
    _channel = null;
    if (ch != null) unawaited(ChatRepository.unsubscribe(ch));
  }
}

final chatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(ChatController.new);

/// Unread counterpart-message count for a booking (badges on chat buttons).
final chatUnreadProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  bookingId,
) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return 0;
  final res = await ref
      .watch(chatRepoProvider)
      .unreadCount(bookingId: bookingId, uid: uid);
  return switch (res) {
    Success(:final data) => data,
    Error() => 0,
  };
});
