/// Shared Riverpod providers: local preferences only.
///
/// The notification feed lives in
/// `features/notifications/providers/notification_providers.dart` (Phase 3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only UI preferences (persisted on device).
class PrefsState {
  const PrefsState({
    this.loaded = false,
    this.notificationsOn = true,
    this.notificationPermissionAsked = false,
  });

  final bool loaded;
  final bool notificationsOn;

  /// True once the Phase 3 value-prop dialog + system permission flow ran.
  final bool notificationPermissionAsked;
}

class PrefsController extends Notifier<PrefsState> {
  static const _kNotif = 'settings.notifications_on';
  static const _kPermAsked = 'settings.notification_permission_asked';

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
        notificationPermissionAsked: sp.getBool(_kPermAsked) ?? false,
      );
    } catch (_) {
      state = const PrefsState(loaded: true);
    }
  }

  Future<void> setNotificationsOn(bool v) async {
    state = PrefsState(
      loaded: true,
      notificationsOn: v,
      notificationPermissionAsked: state.notificationPermissionAsked,
    );
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kNotif, v);
    } catch (_) {}
  }

  Future<void> setPermissionAsked() async {
    state = PrefsState(
      loaded: true,
      notificationsOn: state.notificationsOn,
      notificationPermissionAsked: true,
    );
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kPermAsked, true);
    } catch (_) {}
  }
}

final prefsProvider = NotifierProvider<PrefsController, PrefsState>(
  PrefsController.new,
);
