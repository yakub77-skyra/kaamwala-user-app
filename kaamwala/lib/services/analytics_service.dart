/// Firebase Analytics + Crashlytics wrapper.
///
/// Same degradation policy as FcmService: every method is a safe no-op until
/// Firebase.initializeApp() succeeds, so the app builds and runs without
/// Firebase configured (tests, missing google-services.json).
///
/// FcmService OWNS the single Firebase.initializeApp() call; this service
/// piggybacks on it so the default app is never initialized twice.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:kaamwala/services/fcm_service.dart';

abstract final class AnalyticsService {
  static bool _initialized = false;

  static bool get isAvailable => _initialized;

  /// Arms global error handlers and enables analytics. Never throws.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await FcmService.ensureInitialized();
    if (!FcmService.isAvailable) return;
    try {
      // Uncaught Flutter framework errors -> Crashlytics as fatal.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Uncaught async/platform errors -> Crashlytics as fatal.
      PlatformDispatcher.instance.onError = (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
        return true;
      };
      _initialized = true;
    } on Exception catch (_) {
      _initialized = false;
    }
  }

  /// Funnel event. Name must be lowercase snake_case (Analytics requirement).
  static Future<void> logEvent(
    String name, [
    Map<String, Object>? params,
  ]) async {
    if (!_initialized) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } on Exception catch (_) {}
  }

  /// Audience dimension for segmentation (client vs worker).
  static Future<void> setUserRole(String role) async {
    if (!_initialized) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'role',
        value: role,
      );
    } on Exception catch (_) {}
  }

  /// Non-fatal error report - used at the mapException boundary so every
  /// repository failure surfaces in Crashlytics with context.
  static Future<void> recordError(dynamic e, StackTrace? stack) async {
    if (!_initialized) return;
    try {
      await FirebaseCrashlytics.instance.recordError(e, stack);
    } on Exception catch (_) {}
  }
}
