/// Riverpod provider for the payment gateway (Phase 2 task 17).
///
/// Selection mirrors the SMS pattern (see sms_providers.dart):
///  - KW_PAYMENT_PROVIDER == 'mock'          -> MockPaymentGateway
///  - no KW_RAZORPAY_KEY_ID set              -> MockPaymentGateway
///  - KW_ENABLE_DEMO_PAYMENT == true         -> MockPaymentGateway
///
/// NOTE: the AUTHORITATIVE mock/real decision is server-side (create-order
/// creates a `mock_` order only when RZP keys are absent on the function).
/// Screens must trust `order.mock` for checkout presentation and use this
/// provider only for the demo badge / default gateway.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/env/env.dart';
import 'package:kaamwala/core/services/payment/mock_payment_gateway.dart';
import 'package:kaamwala/core/services/payment/payment_gateway.dart';
import 'package:kaamwala/core/services/payment/razorpay_payment_gateway.dart';

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  if (Env.useMockPayment) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '🔧 [PAY] Using MockPaymentGateway (KW_PAYMENT_PROVIDER='
        '${Env.paymentProvider}, key=${Env.razorpayKeyId.isEmpty ? 'empty' : 'set'}, '
        'demoPayment=${Env.enableDemoPayment})',
      );
    }
    return const MockPaymentGateway();
  }
  return const RazorpayPaymentGateway();
});
