/// Result of an SMS/OTP operation.
library;

class SmsResult {
  const SmsResult({
    required this.success,
    required this.message,
    this.otpDevOnly,
    this.expiresInSeconds = 300,
    this.resendAfterSeconds = 30,
  });

  final bool success;
  final String message;
  final String? otpDevOnly;
  final int expiresInSeconds;
  final int resendAfterSeconds;

  factory SmsResult.success({
    String message = 'OTP sent successfully',
    String? otpDevOnly,
    int expiresInSeconds = 300,
    int resendAfterSeconds = 30,
  }) {
    return SmsResult(
      success: true,
      message: message,
      otpDevOnly: otpDevOnly,
      expiresInSeconds: expiresInSeconds,
      resendAfterSeconds: resendAfterSeconds,
    );
  }

  factory SmsResult.failure({
    required String message,
    int resendAfterSeconds = 30,
  }) {
    return SmsResult(
      success: false,
      message: message,
      resendAfterSeconds: resendAfterSeconds,
    );
  }

  factory SmsResult.rateLimited({
    required String message,
    required int resendAfterSeconds,
  }) {
    return SmsResult(
      success: false,
      message: message,
      resendAfterSeconds: resendAfterSeconds,
    );
  }
}
