/// Demo SMS Service implementation for development.
/// 
/// This service simulates SMS delivery by printing the OTP to console.
/// Use this during development until a real SMS API is approved.
library;

import 'package:kaamwala/core/services/sms_service.dart';

/// Demo SMS service that always succeeds and prints OTP to console.
/// 
/// The OTP is always 123456 for testing purposes.
class DemoSmsService implements SmsService {
  @override
  Future<bool> sendOtp(String phoneNumber) async {
    // Always succeed in demo mode
    print('📱 DEMO SMS: OTP for $phoneNumber is 123456');
    return true;
  }
}
