/// KaamWala analytics tracking.
/// 
/// Architecture (Phase 1 Section 5):
/// - Simple event logging with debugPrint for now
/// - Can be extended to Firebase Analytics later
/// - Standard event constants for consistency
library;

import 'package:flutter/foundation.dart';

/// Standard analytics event names.
abstract final class KwAnalyticsEvents {
  const KwAnalyticsEvents._();

  // Auth events
  static const String loginStarted = 'login_started';
  static const String otpRequested = 'otp_requested';
  static const String otpVerified = 'otp_verified';
  static const String otpFailed = 'otp_failed';
  static const String logout = 'logout';

  // Onboarding events
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String roleSelected = 'role_selected';

  // Booking events
  static const String bookingStarted = 'booking_started';
  static const String bookingCompleted = 'booking_completed';
  static const String bookingCancelled = 'booking_cancelled';
  static const String paymentInitiated = 'payment_initiated';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';

  // Search events
  static const String searchPerformed = 'search_performed';
  static const String workerViewed = 'worker_viewed';
  static const String workerContacted = 'worker_contacted';

  // Error events
  static const String errorShown = 'error_shown';

  // Support events
  static const String supportContacted = 'support_contacted';
  static const String issueReported = 'issue_reported';
}

/// Simple analytics tracker.
class KwAnalytics {
  static bool _initialized = false;

  /// Initialize analytics (currently no-op, ready for Firebase).
  static void ensureInitialized() {
    _initialized = true;
    debugPrint('📊 KwAnalytics initialized');
  }

  /// Log an analytics event.
  static void logEvent(
    String name, [
    Map<String, dynamic>? params,
  ]) {
    if (!_initialized) {
      debugPrint('⚠️ KwAnalytics not initialized');
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📊 ANALYTICS EVENT: $name');
    if (params != null && params.isNotEmpty) {
      debugPrint('   Parameters: $params');
    }
    debugPrint('   Timestamp: $timestamp');
  }

  /// Record an error for analytics.
  static void recordError(
    Object error, [
    StackTrace? stack,
    Map<String, dynamic>? context,
  ]) {
    if (!_initialized) return;

    debugPrint('📊 ANALYTICS ERROR: ${error.runtimeType}');
    debugPrint('   Message: $error');
    if (context != null && context.isNotEmpty) {
      debugPrint('   Context: $context');
    }
    if (stack != null) {
      debugPrint('   Stack: $stack');
    }
  }

  /// Set a user property (e.g., role, city).
  static void setUserProperty(
    String name,
    String value,
  ) {
    if (!_initialized) return;
    debugPrint('📊 ANALYTICS USER PROPERTY: $name = $value');
  }

  /// Set the current user ID.
  static void setUserId(String userId) {
    if (!_initialized) return;
    debugPrint('📊 ANALYTICS USER ID: $userId');
  }
}
