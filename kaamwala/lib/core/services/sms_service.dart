/// SMS Service abstraction for OTP delivery.
/// 
/// This interface allows swapping between demo and real SMS providers.
/// 
/// Architecture (Phase 1 Section 1):
/// - [DemoSmsService]: Returns hardcoded OTP 123456 for development
/// - [RealSmsService]: Integrates with approved SMS API (TODO)
library;

/// Abstract service for sending OTP via SMS.
abstract class SmsService {
  /// Sends an OTP to the given phone number.
  /// Returns true if the SMS was sent successfully.
  Future<bool> sendOtp(String phoneNumber);
}
