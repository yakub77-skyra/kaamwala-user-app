/// Shared Riverpod providers: notification feed + local preferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/shared/repositories/notifications_repository.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

final notificationsRepoProvider = Provider(
  (_) => const NotificationsRepository(),
);

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.loading = false,
  });

  final List<AppNotification> items;
  final int unread;
  final bool loading;

  bool get isEmpty => items.isEmpty && !loading;
}

class NotificationsController extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    if (!SupabaseService.isReady) return const NotificationsState();
    final repo = ref.read(notificationsRepoProvider);
    final listRes = await repo.list();
    final countRes = await repo.unreadCount();
    return NotificationsState(
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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> markAllRead() async {
    final current = state.value ?? const NotificationsState();
    // optimistic
    state = AsyncData(NotificationsState(items: current.items, unread: 0));
    await ref.read(notificationsRepoProvider).markAllRead();
    await refresh();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

/// Local-only UI preferences (persisted on device).
class PrefsState {
  const PrefsState({this.loaded = false, this.notificationsOn = true});

  final bool loaded;
  final bool notificationsOn;
}

class PrefsController extends Notifier<PrefsState> {
  static const _kNotif = 'settings.notifications_on';

  @override
  PrefsState build() {
    _load();
    return const PrefsState();
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      state = PrefsState(
        loaded: true,
        notificationsOn: sp.getBool(_kNotif) ?? true,
      );
    } catch (_) {
      state = const PrefsState(loaded: true);
    }
  }

  Future<void> setNotificationsOn(bool v) async {
    state = PrefsState(loaded: true, notificationsOn: v);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kNotif, v);
    } catch (_) {}
  }
}

final prefsProvider = NotifierProvider<PrefsController, PrefsState>(
  PrefsController.new,
);

/// Re-export so screens can import one file for shared providers.
typedef NotificationItem = AppNotification;
