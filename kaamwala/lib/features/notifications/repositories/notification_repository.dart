/// Notifications repository (Phase 3).
///
/// Rows are inserted by DB triggers / Edge Functions only; clients read and
/// mark their own as read (notifications_select/update_self RLS) and can
/// subscribe to realtime inserts for their own feed.
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/notifications/models/app_notification.dart';
import 'package:kaamwala/services/supabase_service.dart';

class NotificationRepository {
  const NotificationRepository();

  Future<Result<List<AppNotification>>> list({int limit = 50}) async {
    if (!SupabaseService.isReady) return const Success([]);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success([]);
    try {
      final rows = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return Success([
        for (final r in rows)
          AppNotification.fromMap(Map<String, dynamic>.from(r)),
      ]);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  Future<Result<int>> unreadCount() async {
    if (!SupabaseService.isReady) return const Success(0);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success(0);
    try {
      final res = await SupabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false)
          .count(CountOption.exact);
      return Success(res.count);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Marks every unread row of mine as read.
  Future<Result<void>> markAllRead() async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success(null);
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
      return const Success(null);
    } catch (e) {
      return Error(mapException(e));
    }
  }

  /// Marks one of my notifications as read.
  Future<Result<void>> markRead(String id) async {
    if (!SupabaseService.isReady) return const Success(null);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const Success(null);
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', uid);
      return const Success(null);
    } catch (e) {
      return const Success(null);
    }
  }

  /// Live feed: realtime inserts of MY notification rows (RLS already
  /// limits delivery to own rows; the filter is defense-in-depth).
  RealtimeChannel subscribeRealtime(
    String uid,
    void Function(AppNotification notification) onInsert,
  ) {
    final channel = SupabaseService.client.channel('notifications:$uid');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) => onInsert(
        AppNotification.fromMap(Map<String, dynamic>.from(payload.newRecord)),
      ),
    );
    channel.subscribe();
    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client.removeChannel(channel);
    } catch (_) {}
  }
}
