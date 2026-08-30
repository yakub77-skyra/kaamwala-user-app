/// Mock/local notification service - the default until real push is wired.
///
/// Everything runs in-app: banners go through [banners] (the host widget
/// renders them), notification center rows come from the DB. No Firebase,
/// no system permission required.
library;

import 'dart:async';

import 'package:kaamwala/core/services/notifications/notification_service.dart';
import 'package:kaamwala/features/notifications/models/app_notification.dart';
import 'package:kaamwala/services/fcm_service.dart';
import 'package:kaamwala/services/analytics_service.dart';

class MockNotificationService implements NotificationService {
  MockNotificationService();

  final _bannerCtrl = StreamController<AppNotification>.broadcast();

  @override
  bool get isMock => true;

  @override
  String get providerName => 'mock-local';

  @override
  Stream<AppNotification> get banners => _bannerCtrl.stream;

  @override
  Future<void> requestPermission() async {
    // Real push isn't configured yet: system permission is irrelevant for
    // in-app banners. When FCM becomes available this can route through
    // FcmService.getToken() (which requests permission itself).
    unawaited(AnalyticsService.logEvent('notification_permission_granted'));
  }

  @override
  void showBanner(AppNotification notification) {
    unawaited(
      AnalyticsService.logEvent('notification_received', {
        'type': notification.type.dbValue,
        'mock': 'true',
      }),
    );
    if (_bannerCtrl.hasListener) {
      _bannerCtrl.add(notification);
    }
  }

  void dispose() {
    unawaited(_bannerCtrl.close());
  }
}

/// Degrades gracefully when Firebase IS configured: requests the system
/// permission via FCM (Android 13+) so future push taps can arrive.
class HybridNotificationService extends MockNotificationService {
  HybridNotificationService();

  @override
  Future<void> requestPermission() async {
    unawaited(AnalyticsService.logEvent('notification_permission_requested'));
    final granted = await FcmService.requestSystemPermission();
    unawaited(
      AnalyticsService.logEvent(
        granted
            ? 'notification_permission_granted'
            : 'notification_permission_denied',
      ),
    );
  }
}
