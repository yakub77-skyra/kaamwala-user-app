/// Abstract SMS gateway interface for OTP delivery.
/// Implementations can use different providers (Mock, MSG91, Twilio, etc.)
library;

import 'sms_result.dart';

/// Purpose of the OTP - used for analytics and potential different handling.
enum OtpPurpose { login, registration, passwordReset, phoneVerification }

abstract interface class SmsGateway {
  /// Sends an OTP to the given phone number.
  /// Returns [SmsResult] with success status and optional dev-only OTP.
  Future<SmsResult> sendOtp({
    required String phoneE164,
    required OtpPurpose purpose,
  });

  /// Verifies an OTP for the given phone number.
  /// Returns [SmsResult] with success status.
  Future<SmsResult> verifyOtp({
    required String phoneE164,
    required String otp,
    required OtpPurpose purpose,
  });

  /// Resends an OTP to the given phone number.
  /// Returns [SmsResult] with success status and optional dev-only OTP.
  Future<SmsResult> resendOtp({
    required String phoneE164,
    required OtpPurpose purpose,
  });

  /// Whether this gateway is in demo/mock mode.
  bool get isDemoMode;
}
