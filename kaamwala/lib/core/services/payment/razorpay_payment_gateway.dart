/// Real Razorpay payment gateway (Phase 2).
///
/// Security rules (Phase 4 section 5 / NFR-SEC-04):
///  - The app only ever holds order_id + key_id returned by create-order.
///  - The amount shown is the SERVER-computed paise value; the checkout
///    itself uses the server order (Razorpay displays its own amount).
///  - Signature verification + booking updates happen server-side (webhook
///    + check-payment-status); the SDK's success event only triggers the
///    "checking status" step, never a local state change.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kaamwala/services/razorpay_service.dart';

import 'payment_gateway.dart';
import 'payment_result.dart';

class RazorpayPaymentGateway implements PaymentGateway {
  const RazorpayPaymentGateway();

  @override
  bool get isDemoMode => false;

  @override
  Future<PaymentOutcome> pay({
    required BuildContext context,
    required String orderId,
    required int amountPaise,
    required String bookingRef,
    String? contactPhone,
  }) {
    final completer = Completer<PaymentOutcome>();
    final rzp = RazorpayService();
    rzp.openCheckout(
      orderId: orderId,
      amountPaise: amountPaise,
      name: 'KaamWala',
      description: bookingRef,
      contactPhone: contactPhone,
      onSuccess: (paymentId) {
        rzp.clearListeners();
        completer.complete(
          PaymentOutcome.success(
            paymentId: paymentId.isEmpty ? orderId : paymentId,
          ),
        );
      },
      onError: (msg) {
        rzp.clearListeners();
        final friendly =
            msg.contains('cancelled') || msg.toLowerCase().contains('cancel')
            ? 'Payment was not completed. You can retry.'
            : 'Payment failed. You can retry or try another method.';
        completer.complete(
          PaymentOutcome.failure(message: friendly, code: 'razorpay_error'),
        );
      },
    );
    return completer.future;
  }
}
