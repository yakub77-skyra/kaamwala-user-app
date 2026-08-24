/// Notifications repository (S1) - reads the server-populated feed.
///
/// Rows are inserted by DB triggers / Edge Functions only; clients read and
/// mark their own as read (notifications_select/update_self RLS).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

class NotificationsRepository {
  const NotificationsRepository();

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
}
