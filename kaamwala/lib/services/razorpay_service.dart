/// Razorpay wrapper.
///
/// Security rules (Phase 4 section 5 / NFR-SEC-04):
///  - App only ever receives order_id + key_id from the Edge Function.
///  - Amounts are computed SERVER-SIDE by create-order; the client passes
///    only the booking id and displays what the server returned.
library;

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:kaamwala/core/env/env.dart';
import 'package:kaamwala/models/booking.dart';

typedef PaymentSuccessCallback = void Function(String razorpayPaymentId);
typedef PaymentErrorCallback = void Function(String message);

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;

  void openCheckout({
    required String orderId,
    required int amountPaise,
    required String name,
    required String description,
    required String contactPhone,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = {
      'key': Env.razorpayKeyId, // public key id only
      'amount': amountPaise,
      'order_id': orderId, // created by Edge Function create-order
      'name': name,
      'description': description,
      'prefill': {'contact': contactPhone},
      // UPI-first for India (Phase 1: payment comfort).
      'theme': {'color': '#FF6B35'},
    };
    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _dispose();
    _onSuccess?.call(response.paymentId ?? '');
  }

  void _handleError(PaymentFailureResponse response) {
    _dispose();
    final msg = response.message ?? 'Payment failed. Try again.';
    _onError?.call(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Treated as success handoff; verification still happens via webhook.
    _dispose();
    _onSuccess?.call(response.walletName ?? '');
  }

  void clearListeners() => _dispose();

  void _dispose() {
    _razorpay.clear();
  }
}

/// Helper to build the checkout summary line from a booking (C9 wireframe).
String paymentSummaryFor(Booking booking) =>
    '${booking.ref} - Booking Fee Rs.${booking.bookingFee}';
