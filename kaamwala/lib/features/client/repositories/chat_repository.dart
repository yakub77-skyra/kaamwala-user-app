/// Chat + reviews repositories (FR-CHAT-01..05, FR-CLIENT-08).
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

class ChatRepository {
  const ChatRepository();

  /// Loads last 50 messages (FR-CHAT-04).
  Future<Result<List<ChatMessage>>> history(String bookingId) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('chat_messages')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(50);
      final msgs = [for (final r in rows) ChatMessage.fromMap(r)].reversed
          .toList();
      return Success(msgs);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<void>> send({
    required String bookingId,
    required String senderId,
    required String content,
  }) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.from('chat_messages').insert({
        'booking_id': bookingId,
        'sender_id': senderId,
        'message_type': ChatMessage.typeText,
        'content': content,
      });
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Marks the counterpart's messages as read (FR-CHAT-03 read receipts).
  Future<Result<void>> markRead({
    required String bookingId,
    required String readerId,
  }) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('booking_id', bookingId)
          .neq('sender_id', readerId)
          .eq('is_read', false);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Realtime subscription on chat_messages for one booking (FR-CHAT-02).
  RealtimeChannel subscribe(String bookingId, void Function() onChange) {
    return SupabaseService.client
        .channel('chat:$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: bookingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static Future<void> unsubscribe(RealtimeChannel channel) =>
      SupabaseService.isReady
      ? SupabaseService.client.removeChannel(channel)
      : Future.value();
}

class ReviewsRepository {
  const ReviewsRepository();

  /// One review per booking (UNIQUE constraint enforces immutability at DB).
  Future<Result<void>> submitReview(Review review) async {
    if (!SupabaseService.isReady) return const Success(null);
    try {
      await SupabaseService.client.from('reviews').insert({
        'booking_id': review.bookingId,
        'worker_id': review.workerId,
        'client_id': review.clientId,
        'rating': review.rating,
        'text': review.text,
        'tags': review.tags,
      });
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<List<Review>>> forWorker(String workerId) async {
    if (!SupabaseService.isReady) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .limit(20);
      return Success([for (final r in rows) Review.fromMap(r)]);
    } catch (e) {
      return Error(mapException(e));
    }
  }
}
