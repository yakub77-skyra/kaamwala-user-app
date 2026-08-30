/// Chat screen (Phase 3) - text/image/location messages, typing indicator,
/// delivery ticks, pagination, connection banner, optimistic send + retry.
///
/// All state lives in [chatControllerProvider]; this widget only renders.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_image_picker.dart';
import 'package:kaamwala/features/chat/models/chat_message.dart';
import 'package:kaamwala/features/chat/providers/chat_providers.dart';
import 'package:kaamwala/features/chat/widgets/chat_widgets.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _localImages = <String, Uint8List>{};
  bool _nearBottom = true;

  String get _bookingId => widget.bookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(AnalyticsService.logEvent('chat_opened'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatControllerProvider(_bookingId).notifier).onAppResumed();
    }
  }

  // ---------------- send actions ----------------

  Future<void> _sendText() async {
    final notifier = ref.read(chatControllerProvider(_bookingId).notifier);
    final text = _ctrl.text;
    _ctrl.clear();
    notifier.typingStopped();
    final ok = await notifier.sendText(text);
    if (!ok && mounted && text.trim().isNotEmpty) {
      _snack('Could not send. Tap the message to retry.');
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picked = await KwImagePicker.instance.pickSingle(source);
      if (!mounted) return;
      final id = await ref
          .read(chatControllerProvider(_bookingId).notifier)
          .sendImage(
            ImageDraft(
              bytes: picked.bytes,
              mimeType: picked.mimeType,
              name: picked.originalName,
            ),
          );
      if (id != null && mounted) {
        setState(() => _localImages[id] = picked.bytes);
      }
    } on ImagePickError catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _resendImage(ChatMessage m) async {
    try {
      final picked = await KwImagePicker.instance.pickSingle(
        ImageSource.gallery,
      );
      if (!mounted) return;
      setState(() => _localImages[m.id] = picked.bytes);
      await ref
          .read(chatControllerProvider(_bookingId).notifier)
          .resendImage(
            ImageDraft(
              bytes: picked.bytes,
              mimeType: picked.mimeType,
              name: picked.originalName,
            ),
            m.id,
          );
    } on ImagePickError catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _shareLocation() async {
    final location = await _resolveLocation();
    if (location == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share your location?'),
        content: Text(
          'Send your current location so the other person can find you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.location_on_rounded, size: 18),
            label: const Text('Share location'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(chatControllerProvider(_bookingId).notifier)
        .sendLocation(location);
  }

  Future<LocationDraft?> _resolveLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Location is off. Turn it on and try again.');
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          _snack('Location permission denied. Enable it from Settings.');
          return null;
        case LocationPermission.deniedForever:
          _snack('Location is blocked for this app. Enable it in Settings.');
          return null;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          break;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 12),
        ),
      );
      String? label;
      try {
        final marks = await Geocoding().placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        final m = marks.firstOrNull;
        if (m != null) {
          label = [
            m.street,
            m.locality ?? m.subAdministrativeArea ?? m.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } on Exception catch (_) {
        label = null;
      }
      return LocationDraft(
        lat: pos.latitude,
        lng: pos.longitude,
        label: (label == null || label.isEmpty) ? null : label,
        accuracy: pos.accuracy,
      );
    } on TimeoutException {
      _snack('Taking too long to find your location. Try again.');
      return null;
    } on Exception {
      _snack('Could not get your location. Try again.');
      return null;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- attachment sheet ----------------

  Future<void> _showAttachSheet() async {
    final action = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              subtitle: const Text('Send a picture of the job'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: const Text('jpg, png or webp • up to 5 MB'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.my_location_rounded),
              title: const Text('Share location'),
              subtitle: const Text('Send your current address once'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_shareLocation());
              },
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    await _pickAndSendImage(action);
  }

  // ---------------- input handling ----------------

  void _onInputChanged(String _) {
    ref.read(chatControllerProvider(_bookingId).notifier).typingChanged();
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider(_bookingId));
    final booking = ref.watch(bookingByIdProvider(_bookingId));
    final myId = SupabaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _AppBarTitle(booking: booking.value),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ConnectionStrip(chat: chat),
            Expanded(
              child: chat.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  onRetry: () =>
                      ref.refresh(chatControllerProvider(_bookingId).future),
                ),
                data: (state) {
                  final msgs = state.messages;
                  if (state.initialError && msgs.isEmpty) {
                    return _ErrorState(
                      onRetry: () => ref.refresh(
                        chatControllerProvider(_bookingId).future,
                      ),
                    );
                  }
                  if (msgs.isEmpty) {
                    return _EmptyState(
                      onSuggestion: (text) {
                        if (text == 'location') {
                          unawaited(_shareLocation());
                        } else {
                          _ctrl.text = text;
                          _ctrl.selection = TextSelection.collapsed(
                            offset: text.length,
                          );
                          ref
                              .read(chatControllerProvider(_bookingId).notifier)
                              .typingChanged();
                        }
                      },
                    );
                  }
                  return Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels <= 40 &&
                              n.metrics.pixels == n.metrics.minScrollExtent) {
                            ref
                                .read(
                                  chatControllerProvider(_bookingId).notifier,
                                )
                                .loadOlder();
                          }
                          final nearBottom =
                              n.metrics.maxScrollExtent - n.metrics.pixels <
                              120;
                          if (nearBottom != _nearBottom) {
                            setState(() => _nearBottom = nearBottom);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            KwSpacing.lg,
                            KwSpacing.sm,
                            KwSpacing.lg,
                            KwSpacing.md,
                          ),
                          itemCount: msgs.length,
                          itemBuilder: (context, i) => _bubble(msgs[i], myId),
                        ),
                      ),
                      if (!_nearBottom)
                        Positioned(
                          right: KwSpacing.md,
                          bottom: KwSpacing.md,
                          child: FloatingActionButton.small(
                            heroTag: 'scroll-bottom-$_bookingId',
                            tooltip: 'Jump to latest',
                            onPressed: _jumpToBottom,
                            child: const Icon(Icons.arrow_downward_rounded),
                          ),
                        ),
                      if (state.loadingOlder)
                        const Positioned(
                          top: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (ref
                .watch(chatControllerProvider(_bookingId))
                .maybeWhen(data: (s) => s.otherTyping, orElse: () => false))
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: KwSpacing.lg),
                  child: const TypingIndicator(),
                ),
              ),
            _InputBar(
              controller: _ctrl,
              onChanged: _onInputChanged,
              onSend: _sendText,
              onAttach: _showAttachSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, String? myId) {
    final mine = myId != null && m.senderId == myId;
    return ChatBubble(
      message: m,
      mine: mine,
      localImageBytes: m.type == ChatMessageType.image
          ? _localImages[m.id]
          : null,
      onRetry: () {
        if (m.type == ChatMessageType.image) {
          unawaited(_resendImage(m));
        } else {
          ref.read(chatControllerProvider(_bookingId).notifier).retry(m);
        }
      },
    );
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }
}

/// App bar: counterpart avatar + name + booking context.
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.booking});

  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final name = booking?.workerName ?? '';
    final category = booking?.category.labelEn ?? '';
    final date = booking?.serviceDate;
    final sub = [
      if (category.isNotEmpty) category,
      if (date != null) '${date.day}/${date.month}/${date.year}',
      if (booking?.ref != null) booking!.ref,
    ].join(' • ');
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: KwColors.primaryLight,
          child: Icon(
            Icons.person_rounded,
            size: 19,
            color: KwColors.primary.withValues(alpha: .8),
          ),
        ),
        const SizedBox(width: KwSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? 'Chat' : name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thin banner under the app bar when realtime is down.
class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.chat});

  final AsyncValue<ChatState> chat;

  @override
  Widget build(BuildContext context) {
    final state = chat.value;
    if (state == null || state.connection == ChatConnectionState.connected) {
      return const SizedBox.shrink();
    }
    final reconnecting = state.connection == ChatConnectionState.reconnecting;
    return Material(
      color: KwColors.warningLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.lg,
          vertical: 6,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: KwColors.warning,
              ),
            ),
            const SizedBox(width: KwSpacing.sm),
            Text(
              reconnecting
                  ? 'Chat connection lost. Reconnecting…'
                  : 'You are offline. Messages will retry when back.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: KwColors.muted),
          const SizedBox(height: KwSpacing.md),
          Text(
            'Could not load this conversation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: KwSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Empty state + quick reply chips.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  static const _chips = [
    ('Are you available?', 'text'),
    ('When can you come?', 'text'),
    ('Please share your location.', 'location'),
    ('I’m on the way.', 'text'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(KwSpacing.lg),
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 48,
          color: KwColors.muted,
        ),
        const SizedBox(height: KwSpacing.md),
        Text(
          'Start the conversation',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Messages, photos and location are only visible to the two of you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: KwColors.muted),
        ),
        const SizedBox(height: KwSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: KwSpacing.sm,
          runSpacing: KwSpacing.sm,
          children: [
            for (final (label, kind) in _chips)
              ActionChip(
                label: Text(label),
                onPressed: () =>
                    onSuggestion(kind == 'location' ? 'location' : label),
              ),
          ],
        ),
      ],
    );
  }
}

/// Text field + attach + send.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: KwSpacing.xs,
        right: KwSpacing.sm,
        top: KwSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + KwSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: KwColors.surface,
        border: Border(top: BorderSide(color: KwColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Attach photo or location',
            onPressed: onAttach,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Message…',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KwSpacing.lg,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: KwSpacing.xs),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, _) => IconButton.filled(
              tooltip: 'Send message',
              style: IconButton.styleFrom(
                backgroundColor: v.text.trim().isEmpty
                    ? KwColors.fill
                    : KwColors.primary,
              ),
              onPressed: v.text.trim().isEmpty ? null : onSend,
              icon: Icon(
                Icons.send_rounded,
                size: 20,
                color: v.text.trim().isEmpty ? KwColors.muted : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
