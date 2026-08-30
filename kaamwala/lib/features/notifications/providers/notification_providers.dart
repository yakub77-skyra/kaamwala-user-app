/// Notification providers (Phase 3).
///
/// - [notificationServiceProvider]: the active NotificationService. Swap the
///   constructor here to adopt a real push provider - no UI changes needed.
/// - [notificationCenterProvider]: live feed (list + unread) backed by the
///   notifications table + realtime inserts. Kept alive app-wide.
/// - [pendingDeepLinkProvider]: route stored until the user authenticates.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/core/services/notifications/mock_notification_service.dart';
import 'package:kaamwala/core/services/notifications/notification_service.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/notifications/models/app_notification.dart';
import 'package:kaamwala/features/notifications/repositories/notification_repository.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

final notificationRepoProvider = Provider(
  (_) => const NotificationRepository(),
);

/// Single place to swap the notification backend (mock today, FCM later).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => HybridNotificationService(),
);

/// Route to open once the user is authenticated (notification tap before
/// login / during onboarding).
final pendingDeepLinkProvider = StateProvider<String?>((_) => null);

class NotificationCenterState {
  const NotificationCenterState({
    this.items = const [],
    this.unread = 0,
    this.loading = false,
  });

  final List<AppNotification> items;
  final int unread;
  final bool loading;

  bool get isEmpty => items.isEmpty && !loading;

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    int? unread,
    bool? loading,
  }) => NotificationCenterState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    loading: loading ?? this.loading,
  );
}

class NotificationCenterController
    extends AsyncNotifier<NotificationCenterState> {
  NotificationRepository get _repo => ref.read(notificationRepoProvider);

  RealtimeChannel? _channel;

  @override
  Future<NotificationCenterState> build() async {
    // Rebuild on auth change -> subscription follows the signed-in user.
    ref.watch(authControllerProvider);
    final uid = SupabaseService.currentUserId;
    if (uid == null) return const NotificationCenterState();
    final listRes = await _repo.list();
    final countRes = await _repo.unreadCount();
    _subscribe(uid);
    ref.onDispose(() {
      final ch = _channel;
      _channel = null;
      if (ch != null) unawaited(NotificationRepository.unsubscribe(ch));
    });
    return NotificationCenterState(
      items: switch (listRes) {
        Success(:final data) => data,
        _ => const [],
      },
      unread: switch (countRes) {
        Success(:final data) => data,
        _ => 0,
      },
    );
  }

  void _subscribe(String uid) {
    final ch = _repo.subscribeRealtime(uid, (notification) {
      final current = state.value ?? const NotificationCenterState();
      state = AsyncData(
        current.copyWith(
          items: [notification, ...current.items],
          unread: current.unread + 1,
        ),
      );
      ref.read(notificationServiceProvider).showBanner(notification);
    });
    _channel = ch;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> markAllRead() async {
    final current = state.value ?? const NotificationCenterState();
    state = AsyncData(
      current.copyWith(unread: 0, items: _allRead(current.items)),
    );
    await _repo.markAllRead();
    await refresh();
  }

  /// Marks a single notification read (tap). Optimistic, never blocks nav.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final current = state.value ?? const NotificationCenterState();
    state = AsyncData(
      current.copyWith(
        items: [
          for (final n in current.items)
            n.id == notification.id ? n.copyWith(isRead: true) : n,
        ],
        unread: current.unread > 0 ? current.unread - 1 : 0,
      ),
    );
    await _repo.markRead(notification.id);
  }

  static List<AppNotification> _allRead(List<AppNotification> items) => [
    for (final n in items) n.copyWith(isRead: true),
  ];
}

/// Root-level, kept alive for the whole session (banner host + bell watch it).
final notificationCenterProvider =
    AsyncNotifierProvider<
      NotificationCenterController,
      NotificationCenterState
    >(NotificationCenterController.new);

/// Unread badge count for the bell / tabs. Recomputes from the live feed.
final notificationUnreadProvider = Provider<int>((ref) {
  final state = ref.watch(notificationCenterProvider).value;
  return state?.unread ?? 0;
});

/// Opens a notification (from banner tap or the center): mark read, navigate,
/// or park the route until login completes.
Future<void> openNotification(
  WidgetRef ref,
  AppNotification notification,
) async {
  unawaited(
    AnalyticsService.logEvent('notification_opened', {
      'type': notification.type.dbValue,
      'mock': ref.read(notificationServiceProvider).isMock ? 'true' : 'false',
    }),
  );
  unawaited(
    ref.read(notificationCenterProvider.notifier).markRead(notification),
  );
  final route = notification.resolveRoute();
  final stage = ref.read(authControllerProvider).stage;
  final authed = stage == AppStage.clientApp || stage == AppStage.workerApp;
  if (!authed) {
    ref.read(pendingDeepLinkProvider.notifier).state = route;
    return;
  }
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null) ctx.go(route);
}
