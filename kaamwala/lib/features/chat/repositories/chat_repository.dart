/// Chat repository - all Supabase chat access (Phase 3).
///
/// Owns: history + pagination, idempotent inserts, read marking, unread
/// counts, realtime (postgres changes + typing broadcast) and chat image
/// uploads. The controller (chat_providers.dart) owns subscription
/// lifecycle; this class never leaks raw Supabase types to the UI.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/chat/models/chat_message.dart';
import 'package:kaamwala/services/supabase_service.dart';

class ChatRepository {
  const ChatRepository();

  static const int pageSize = 30;

  /// Latest [limit] messages ascending; pass [before] to page older.
  Future<Result<List<ChatMessage>>> history(
    String bookingId, {
    DateTime? before,
    int limit = ChatRepository.pageSize,
  }) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      var q = SupabaseService.client
          .from('chat_messages')
          .select()
          .eq('booking_id', bookingId);
      if (before != null) {
        q = q.lt('created_at', before.toUtc().toIso8601String());
      }
      final rows = await q.order('created_at', ascending: false).limit(limit);
      return Success(
        [
          for (final r in rows)
            ChatMessage.fromMap(Map<String, dynamic>.from(r)),
        ].reversed.toList(),
      );
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Inserts a message with a client-generated id (idempotent: re-inserting
  /// the same id on retry never creates a duplicate). Returns the server row.
  Future<Result<ChatMessage>> insertMessage(ChatMessage message) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      final rows = await SupabaseService.client
          .from('chat_messages')
          .insert(message.toInsertMap())
          .select()
          .maybeSingle();
      if (rows == null) return const Error(ServerFailure('Message not stored'));
      return Success(ChatMessage.fromMap(Map<String, dynamic>.from(rows)));
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Marks every counterpart message of this booking as read. Only touches
  /// read-tracking fields (chat_messages_guard allows those).
  Future<Result<void>> markRead({
    required String bookingId,
    required String readerId,
  }) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client
          .from('chat_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
            'status': ChatMessageStatus.read.dbValue,
          })
          .eq('booking_id', bookingId)
          .neq('sender_id', readerId)
          .isFilter('read_at', null);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Unread counterpart messages for me in this booking.
  Future<Result<int>> unreadCount({
    required String bookingId,
    required String uid,
  }) async {
    if (!SupabaseService.isReady) return const Success(0);
    try {
      final res = await SupabaseService.client
          .from('chat_messages')
          .select('id')
          .eq('booking_id', bookingId)
          .neq('sender_id', uid)
          .isFilter('read_at', null)
          .neq('message_type', ChatMessageType.system.dbValue)
          .count(CountOption.exact);
      return Success(res.count);
    } catch (e) {
      return const Success(0);
    }
  }

  /// User id of the OTHER participant of this booking (receiver of my
  /// messages). Works from either side via the workers embed.
  Future<Result<String?>> counterpartId(String bookingId) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      final row = await SupabaseService.client
          .from('bookings')
          .select('client_id, workers(user_id)')
          .eq('id', bookingId)
          .maybeSingle();
      if (row == null) return const Success(null);
      final myId = SupabaseService.currentUserId;
      if (myId == null) return const Success(null);
      final clientId = (row['client_id'] ?? '') as String;
      final workerUserId =
          ((row['workers'] as Map?)?['user_id'] ?? '') as String;
      return Success(clientId == myId ? workerUserId : clientId);
    } catch (e) {
      return const Success(null);
    }
  }

  /// Uploads a compressed chat image to `chat_images/chat/<booking>/<id>.ext`
  /// (private bucket; participant-only RLS). Returns the object path.
  Future<Result<String>> uploadImage({
    required String bookingId,
    required String messageId,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    if (!SupabaseService.isReady) {
      return const Error(ServerFailure('Backend not configured'));
    }
    try {
      final ext = switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };
      final path = 'chat/$bookingId/$messageId.$ext';
      await SupabaseService.client.storage
          .from('chat_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          )
          .timeout(const Duration(seconds: 60));
      onProgress?.call(1);
      return Success(path);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Short-lived signed URL so a participant can display a private image.
  /// Expires after an hour - the widget re-resolves on rebuild.
  Future<Result<String?>> signedImageUrl(String path) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      final url = await SupabaseService.client.storage
          .from('chat_images')
          .createSignedUrl(path, 3600);
      return Success(url);
    } catch (e) {
      return const Success(null);
    }
  }

  /// Subscribes to realtime for one booking: postgres inserts/updates on
  /// chat_messages + broadcast typing events. The returned channel is owned
  /// by the caller (must be removed with [unsubscribe]).
  RealtimeChannel subscribe(
    String bookingId, {
    required void Function(ChatMessage message) onInsert,
    required void Function(ChatMessage message) onUpdate,
    required void Function(String userId, bool typing) onTyping,
    required void Function(RealtimeSubscribeStatus status, Object? error)
    onStatus,
  }) {
    final channel = SupabaseService.client.channel('chat:$bookingId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'booking_id',
        value: bookingId,
      ),
      callback: (payload) => onInsert(
        ChatMessage.fromMap(Map<String, dynamic>.from(payload.newRecord)),
      ),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'booking_id',
        value: bookingId,
      ),
      callback: (payload) => onUpdate(
        ChatMessage.fromMap(Map<String, dynamic>.from(payload.newRecord)),
      ),
    );
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        final typing = (payload['is_typing'] ?? false) as bool;
        if (userId != null) onTyping(userId, typing);
      },
    );
    channel.subscribe(onStatus);
    return channel;
  }

  /// Sends a typing event on [channel] (broadcast; never persisted).
  void sendTyping(
    RealtimeChannel channel, {
    required String userId,
    required bool typing,
  }) {
    channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': userId, 'is_typing': typing},
    );
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client.removeChannel(channel);
    } catch (_) {}
  }
}
