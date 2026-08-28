/// Real SMS Service implementation.
/// 
/// TODO: Integrate with approved SMS API provider (e.g., Twilio, MSG91, TextLocal).
/// This file is a placeholder until SMS API approval is obtained.
library;

import 'package:kaamwala/core/services/sms_service.dart';

/// Real SMS service that will connect to an approved SMS API.
/// 
/// TODO(Phase 1 Section 1):
/// 1. Choose an SMS provider (Twilio, MSG91, TextLocal, etc.)
/// 2. Add HTTP client dependency (e.g., http or dio)
/// 3. Implement the actual API call in [sendOtp]
/// 4. Handle rate limiting, retries, and error responses
/// 5. Store API credentials securely (not in code - use environment variables)
class RealSmsService implements SmsService {
  // TODO: Add your SMS API client instance here
  // Example: final _httpClient = http.Client();
  // TODO: Add API key/credentials (from secure environment, NOT hardcoded)
  // Example: final _apiKey = String.fromEnvironment('KW_SMS_API_KEY');
  // Example: final _senderId = String.fromEnvironment('KW_SMS_SENDER_ID');

  @override
  Future<bool> sendOtp(String phoneNumber) async {
    // TODO: Replace this with actual SMS API integration
    // Example implementation structure:
    //
    // try {
    //   final response = await _httpClient.post(
    //     Uri.parse('https://api.smsprovider.com/send'),
    //     headers: {
    //       'Authorization': 'Bearer $_apiKey',
    //       'Content-Type': 'application/json',
    //     },
    //     body: jsonEncode({
    //       'to': phoneNumber,
    //       'message': 'Your KaamWala OTP is: 123456. Valid for 5 minutes.',
    //       'sender_id': _senderId,
    //     }),
    //   );
    //   return response.statusCode == 200;
    // } catch (e) {
    //   print('RealSmsService.sendOtp failed: $e');
    //   return false;
    // }

    throw UnimplementedError(
      'Real SMS API not approved yet. Use DemoSmsService for development.',
    );
  }
}
