/// Outcome of a payment attempt (Phase 2).
library;

class PaymentOutcome {
  const PaymentOutcome._({
    required this.success,
    this.paymentId,
    this.errorMessage,
    this.errorCode,
  });

  const PaymentOutcome.success({required String paymentId})
    : this._(success: true, paymentId: paymentId);

  const PaymentOutcome.failure({required String message, String? code})
    : this._(success: false, errorMessage: message, errorCode: code);

  final bool success;
  final String? paymentId;

  /// User-facing message (never raw SDK jargon).
  final String? errorMessage;
  final String? errorCode;
}
