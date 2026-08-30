/// Riverpod providers for SMS gateway.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/env/env.dart';
import 'package:kaamwala/core/services/sms/mock_sms_gateway.dart';
import 'package:kaamwala/core/services/sms/sms_gateway.dart';

/// Provider for the SMS gateway implementation.
///
/// Selection rules (all in [Env]):
///  - KW_SMS_PROVIDER == 'mock'            -> MockSmsGateway
///  - no KW_SMS_API_KEY set                -> MockSmsGateway (default dev)
///  - KW_ENABLE_DEMO_OTP == true           -> MockSmsGateway
///
/// So with an empty/absent SMS config the app ALWAYS runs in mock mode;
/// a real key is only used once KW_ENABLE_DEMO_OTP=false AND a provider +
/// key are present. Screens never construct gateways; they only use
/// [smsGatewayProvider], so swapping in a real provider later (MSG91,
/// Twilio, ...) is a change confined to this file.
final smsGatewayProvider = Provider<SmsGateway>((ref) {
  final useMock =
      Env.smsProvider == 'mock' || Env.smsApiKey.isEmpty || Env.enableDemoOtp;

  if (useMock) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '🔧 [SMS] Using MockSmsGateway (KW_SMS_PROVIDER=${Env.smsProvider}, '
        'apiKey=${Env.smsApiKey.isEmpty ? 'empty' : 'set'}, '
        'demoOtp=${Env.enableDemoOtp})',
      );
    }
    return MockSmsGateway();
  }

  // Phase 1 ships only the mock gateway. A real implementation (MSG91 /
  // Twilio) plugs in here - the SmsGateway interface + SmsResult stay the
  // same, and no screen or auth-flow needs to change.
  // TODO(Phase 1b/real SMS): implement and register
  //   switch (Env.smsProvider) {
  //     case 'msg91': return Msg91SmsGateway(
  //         apiKey: Env.smsApiKey, senderId: Env.smsSenderId);
  //     case 'twilio': return TwilioSmsGateway(apiKey: Env.smsApiKey, ...);
  //     default: return MockSmsGateway();
  //   }
  if (kDebugMode) {
    // ignore: avoid_print
    print(
      '⚠️ SMS provider "${Env.smsProvider}" not implemented yet - '
      'falling back to MockSmsGateway',
    );
  }
  return MockSmsGateway();
});

/// Provider for the demo mode flag.
final smsDemoModeProvider = Provider<bool>((ref) {
  final gateway = ref.watch(smsGatewayProvider);
  return gateway.isDemoMode;
});

/// Provider for the current OTP purpose (login vs registration).
final otpPurposeProvider = StateProvider<OtpPurpose>((ref) => OtpPurpose.login);
