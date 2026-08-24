/// FCM push notifications (Phase 4 section 6.2).
///
/// Tokens live in the `push_tokens` table (FR-NOTIF-01); sending happens
/// ONLY from Edge Functions. Everything here degrades gracefully to a no-op
/// until android/app/google-services.json is added - the app must build and
/// run without Firebase configured.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:kaamwala/services/supabase_service.dart';

abstract final class FcmService {
  static bool _initialized = false;

  /// True only after Firebase.initializeApp() succeeded.
  static bool get isAvailable => _initialized;

  /// Safe initialization. Never throws.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      // Background isolate handler - must be registered before use.
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      _initialized = true;
    } on Exception catch (_) {
      _initialized = false;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
    } on Exception catch (_) {}
    // Data-only taps are routed in app layer via getInitialMessage().
  }

  /// Device token, or null when Firebase is unavailable / permission denied.
  static Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      final fcm = FirebaseMessaging.instance;
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return null;
      }
      return await fcm.getToken();
    } on Exception catch (_) {
      return null;
    }
  }

  /// Persists/refreshes the device token (push_tokens_all_self RLS).
  static Future<bool> registerToken(String userId, String token) async {
    if (!SupabaseService.isReady || token.isEmpty) return false;
    try {
      await SupabaseService.client.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}
