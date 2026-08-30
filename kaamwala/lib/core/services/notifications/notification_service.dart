/// Notification service abstraction (Phase 3).
///
/// One interface, two modes:
///  - [MockNotificationService]: local/in-app banners + notification center
///    rows. No push keys needed - the app always works.
///  - Future: an FcmNotificationService (or similar) that additionally
///    surfaces system push. Swap the provider in `notification_providers.dart`
///    without touching any UI.
library;

import 'dart:async';

import 'package:kaamwala/features/notifications/models/app_notification.dart';

abstract class NotificationService {
  /// True when this build uses local/in-app notifications only.
  bool get isMock;

  /// Human-readable provider name for debug markers.
  String get providerName;

  /// In-app banner feed the host widget renders (only real feeds emit).
  Stream<AppNotification> get banners;

  /// Asks for SYSTEM notification permission (Android 13+). In mock mode
  /// this is a no-op - in-app banners need no permission. Never throws.
  Future<void> requestPermission();

  /// Pushes an in-app banner for a freshly received notification. The banner
  /// host decides whether to actually show it (suppression rules).
  void showBanner(AppNotification notification);
}

/// Marker for the pre-permission explanation dialog flow.
enum PermissionAnswer { notAsked, granted, denied }
