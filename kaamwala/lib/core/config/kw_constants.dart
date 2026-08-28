/// Centralized app constants.
/// 
/// All magic numbers and configuration values live here.
/// Architecture (Phase 1 Section 5): No hardcoded values scattered in code.
library;

abstract final class KwConstants {
  const KwConstants._();

  /// Demo mode OTP for testing (FR-AUTH-01).
  static const String demoOtp = '123456';

  /// Booking fee in paise (₹20.00).
  static const int bookingFeePaise = 2000;

  /// Maximum number of photos allowed per booking.
  static const int maxBookingPhotos = 5;

  /// Search debounce delay in milliseconds.
  static const int searchDebounceMs = 300;

  /// OTP resend cooldown in seconds.
  static const int otpResendSeconds = 30;

  /// OTP expiry time in seconds (5 minutes).
  static const int otpExpirySeconds = 5 * 60;

  /// Maximum OTP resend attempts per hour.
  static const int otpResendLimitPerHour = 3;

  /// Avatar image max size in KB.
  static const int avatarMaxSizeKB = 500;

  /// Avatar image quality (0-100).
  static const int avatarQuality = 80;

  /// Cache duration for worker list in seconds.
  static const int workerListCacheSeconds = 300;

  /// Location update interval in seconds.
  static const int locationUpdateIntervalSeconds = 60;

  /// Minimum app version required (for force update).
  static const String minAppVersion = '1.0.0';
}
