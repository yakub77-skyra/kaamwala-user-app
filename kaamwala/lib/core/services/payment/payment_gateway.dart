/// Abstract payment gateway interface (Phase 2).
/// Implementations: MockPaymentGateway (dev) / RazorpayPaymentGateway (prod).
/// The final amount is ALWAYS the server-computed paise value from
/// create-order; gateways only present it, never recalculate it.
library;

import 'package:flutter/widgets.dart';

import 'payment_result.dart';

abstract interface class PaymentGateway {
  /// Opens the payment UI for the given server-created order.
  /// [amountPaise] is the server-computed amount (never client-derived).
  /// Returns a [PaymentOutcome]: success with payment id, or failure with a
  /// user-facing message + optional machine code.
  Future<PaymentOutcome> pay({
    required BuildContext context,
    required String orderId,
    required int amountPaise,
    required String bookingRef,
    String? contactPhone,
  });

  /// Whether this gateway is demo/mock (drives the DEV/MOCK badge).
  bool get isDemoMode;
}
