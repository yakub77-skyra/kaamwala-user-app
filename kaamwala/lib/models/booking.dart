/// bookings + orders + payouts models - Phase 3 section 7.1 (+ Phase 2 payment).
library;

import 'package:kaamwala/core/constants/app_constants.dart';

class Booking {
  const Booking({
    required this.id,
    required this.ref,
    required this.clientId,
    required this.workerId,
    required this.category,
    required this.description,
    this.serviceDate,
    this.timeSlot = '',
    this.address = '',
    this.status = BookingStatus.paymentPending,
    this.estimateMin = 0,
    this.estimateMax = 0,
    this.bookingFee = AppConstants.bookingFeeRupees,
    this.commissionRate = AppConstants.commissionRate,
    this.commissionAmount = 0,
    this.workerEarning = 0,
    this.clientConfirmed = false,
    this.clientName = '',
    this.workerName = '',
    this.workerPhoto,
    this.createdAt,
    this.liveLat,
    this.liveLng,
    this.liveLocationUpdatedAt,
    this.photoUrls = const [],
    this.paymentStatus = PaymentStatus.pending,
    this.paymentProvider,
    this.paymentOrderId,
    this.paymentId,
    this.paymentSignatureVerified = false,
    this.amountPaise,
    this.bookingFeePaise,
    this.estimateMinPaise,
    this.estimateMaxPaise,
    this.paymentAttempts = 0,
    this.paymentErrorMessage,
    this.paymentExpiresAt,
    this.transactionReference,
    this.cancellationReason,
    this.cancelledAt,
    this.refundStatus,
    this.refundMessage,
  });

  final String id;

  /// Human reference e.g. KW-2026-0148.
  final String ref;
  final String clientId;
  final String workerId;
  final ServiceCategory category;
  final String description;
  final DateTime? serviceDate;
  final String timeSlot;
  final String address;
  final BookingStatus status;
  final num estimateMin;
  final num estimateMax;

  /// Flat Rs.20 convenience fee (Phase 2 business model).
  final num bookingFee;
  final num commissionRate;

  /// Computed SERVER-SIDE only - FR-PAY-04 / NFR-SEC-02.
  final num commissionAmount;
  final num workerEarning;

  /// Gates payout release (Phase 3 sequence diagram).
  final bool clientConfirmed;
  final String clientName;
  final DateTime? createdAt;

  /// Counterpart identity via workers(id, users(...)) embed.
  final String workerName;
  final String? workerPhoto;

  /// Live location sharing (worker -> customer during 'traveling' status).
  final double? liveLat;
  final double? liveLng;
  final DateTime? liveLocationUpdatedAt;

  /// Client-uploaded photos/videos of the job (max 5).
  final List<String> photoUrls;

  // ---- Phase 2 payment fields (server-written, RLS/guard-protected) ----
  final PaymentStatus paymentStatus;

  /// 'razorpay' | 'mock' - set by create-order at booking creation.
  final String? paymentProvider;
  final String? paymentOrderId;
  final String? paymentId;
  final bool paymentSignatureVerified;
  final int? amountPaise;
  final int? bookingFeePaise;
  final int? estimateMinPaise;
  final int? estimateMaxPaise;
  final int paymentAttempts;
  final String? paymentErrorMessage;
  final DateTime? paymentExpiresAt;
  final String? transactionReference;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final RefundStatus? refundStatus;
  final String? refundMessage;

  bool get isSharingLocation =>
      liveLat != null && liveLng != null && status == BookingStatus.traveling;

  bool get canCancel => status.canCancel;

  bool get needsPayment => status.needsPayment;

  /// Whether a refund is expected/applicable (cancelled bookings only).
  RefundStatus get effectiveRefundStatus =>
      refundStatus ??
      (status == BookingStatus.cancelled
          ? RefundStatus.none
          : RefundStatus.none);

  /// User-facing refund line shown on cancelled bookings.
  String? get refundNote {
    if (status != BookingStatus.cancelled) return null;
    return switch (refundStatus) {
      RefundStatus.pending =>
        refundMessage ??
            'Refund initiated — usually reaches your bank in 3-5 business days',
      RefundStatus.processed => 'Refund completed',
      RefundStatus.failed => 'Refund could not be processed. Contact support.',
      RefundStatus.none =>
        paymentStatus == PaymentStatus.paid ? 'Refund not applicable' : null,
      null => null,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    final client = map['users'];
    final workerMap = map['workers'] as Map?;
    final workerUser = workerMap?['users'] as Map?;
    return Booking(
      id: (map['id'] ?? '') as String,
      ref: (map['ref'] ?? '') as String,
      clientId: (map['client_id'] ?? '') as String,
      workerId: (map['worker_id'] ?? '') as String,
      category: ServiceCategory.fromDb(map['category'] as String? ?? 'plumber'),
      description: (map['description'] ?? '') as String,
      serviceDate: DateTime.tryParse((map['service_date'] ?? '') as String),
      timeSlot: (map['time_slot'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      status: BookingStatus.fromDb(
        map['status'] as String? ?? 'payment_pending',
      ),
      estimateMin: (map['estimate_min'] ?? 0) as num,
      estimateMax: (map['estimate_max'] ?? 0) as num,
      bookingFee: (map['booking_fee'] ?? AppConstants.bookingFeeRupees) as num,
      commissionRate:
          (map['commission_rate'] ?? AppConstants.commissionRate) as num,
      commissionAmount: (map['commission_amount'] ?? 0) as num,
      workerEarning: (map['worker_earning'] ?? 0) as num,
      clientConfirmed: (map['client_confirmed'] ?? false) as bool,
      clientName: client is Map ? ((client['name'] ?? '') as String) : '',
      workerName: workerUser is Map
          ? ((workerUser['name'] ?? '') as String)
          : '',
      workerPhoto: workerUser is Map
          ? workerUser['photo_url'] as String?
          : null,
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
      liveLat: (map['live_lat'] as num?)?.toDouble(),
      liveLng: (map['live_lng'] as num?)?.toDouble(),
      liveLocationUpdatedAt: DateTime.tryParse(
        (map['live_location_updated_at'] ?? '') as String,
      ),
      photoUrls: (map['photo_urls'] as List?)?.cast<String>() ?? const [],
      paymentStatus: PaymentStatus.fromDb(
        (map['payment_status'] ?? 'pending') as String,
      ),
      paymentProvider: map['payment_provider'] as String?,
      paymentOrderId: map['payment_order_id'] as String?,
      paymentId: map['payment_id'] as String?,
      paymentSignatureVerified:
          (map['payment_signature_verified'] ?? false) as bool,
      amountPaise: map['amount_paise'] as int?,
      bookingFeePaise: map['booking_fee_paise'] as int?,
      estimateMinPaise: map['estimated_min_paise'] as int?,
      estimateMaxPaise: map['estimated_max_paise'] as int?,
      paymentAttempts: (map['payment_attempts'] ?? 0) as int,
      paymentErrorMessage: map['payment_error_message'] as String?,
      paymentExpiresAt: DateTime.tryParse(
        (map['payment_expires_at'] ?? '') as String,
      ),
      transactionReference: map['transaction_reference'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      cancelledAt: DateTime.tryParse((map['cancelled_at'] ?? '') as String),
      refundStatus: map['refund_status'] == null
          ? null
          : RefundStatus.fromDb(map['refund_status'] as String),
      refundMessage: map['refund_message'] as String?,
    );
  }
}

class PaymentOrder {
  const PaymentOrder({
    required this.id,
    required this.bookingId,
    this.razorpayOrderId = '',
    this.razorpayPaymentId,
    this.amount = AppConstants.bookingFeeRupees,
    this.status = OrderStatus.created,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final num amount;
  final OrderStatus status;
  final DateTime? paidAt;

  factory PaymentOrder.fromMap(Map<String, dynamic> map) => PaymentOrder(
    id: map['id'] as String,
    bookingId: map['booking_id'] as String,
    razorpayOrderId: (map['razorpay_order_id'] ?? '') as String,
    razorpayPaymentId: map['razorpay_payment_id'] as String?,
    amount: (map['amount'] ?? 0) as num,
    status: OrderStatus.values.firstWhere(
      (s) => s.name == (map['status'] ?? 'CREATED'),
      orElse: () => OrderStatus.created,
    ),
    paidAt: DateTime.tryParse((map['paid_at'] ?? '') as String),
  );
}

/// Server response of create-order (both modes): booking + payment order.
/// Amount is SERVER-COMPUTED paise - never trust a client-supplied amount.
class BookingOrderDraft {
  const BookingOrderDraft({
    required this.bookingId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.bookingRef,
    this.mock = false,
    this.keyId = '',
  });

  final String bookingId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String bookingRef;
  final bool mock;
  final String keyId;

  factory BookingOrderDraft.fromMap(Map<String, dynamic> map) =>
      BookingOrderDraft(
        bookingId: (map['booking_id'] ?? '') as String,
        orderId: (map['order_id'] ?? '') as String,
        amountPaise: (map['amount'] ?? 0) as int,
        currency: (map['currency'] ?? 'INR') as String,
        bookingRef: (map['booking_ref'] ?? '') as String,
        mock: (map['mock'] ?? false) as bool,
        keyId: (map['key_id'] ?? '') as String,
      );
}

/// Result of check-payment-status (payment recovery, task 11).
class BookingPaymentStatus {
  const BookingPaymentStatus({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
    required this.paymentStatus,
    required this.paid,
    required this.mock,
    this.orderStatus,
    this.amountPaise,
    this.paymentProvider,
    this.paymentId,
    this.transactionReference,
    this.refundStatus,
    this.refundMessage,
  });

  final String bookingId;
  final String bookingRef;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final bool paid;
  final bool mock;
  final String? orderStatus;
  final int? amountPaise;
  final String? paymentProvider;
  final String? paymentId;
  final String? transactionReference;
  final RefundStatus? refundStatus;
  final String? refundMessage;

  factory BookingPaymentStatus.fromMap(Map<String, dynamic> map) =>
      BookingPaymentStatus(
        bookingId: (map['booking_id'] ?? '') as String,
        bookingRef: (map['booking_ref'] ?? '') as String,
        status: BookingStatus.fromDb(
          map['status'] as String? ?? 'payment_pending',
        ),
        paymentStatus: PaymentStatus.fromDb(
          map['payment_status'] as String? ?? 'pending',
        ),
        paid: (map['paid'] ?? false) as bool,
        mock: (map['mock'] ?? false) as bool,
        orderStatus: map['order_status'] as String?,
        amountPaise: map['amount_paise'] as int?,
        paymentProvider: map['payment_provider'] as String?,
        paymentId: map['payment_id'] as String?,
        transactionReference: map['transaction_reference'] as String?,
        refundStatus: map['refund_status'] == null
            ? null
            : RefundStatus.fromDb(map['refund_status'] as String),
        refundMessage: map['refund_message'] as String?,
      );
}

/// Result of cancel-booking.
class CancelBookingResult {
  const CancelBookingResult({
    required this.cancelled,
    required this.refundStatus,
    this.refundMessage,
    this.refundId,
  });

  final bool cancelled;
  final RefundStatus refundStatus;
  final String? refundMessage;
  final String? refundId;
}

class Payout {
  const Payout({
    required this.id,
    required this.bookingId,
    required this.workerId,
    required this.amount,
    this.status = PayoutStatus.pending,
    this.razorpayPayoutId,
  });

  final String id;
  final String bookingId;
  final String workerId;
  final num amount;
  final PayoutStatus status;
  final String? razorpayPayoutId;

  factory Payout.fromMap(Map<String, dynamic> map) => Payout(
    id: map['id'] as String,
    bookingId: map['booking_id'] as String,
    workerId: map['worker_id'] as String,
    amount: (map['amount'] ?? 0) as num,
    status: PayoutStatus.values.firstWhere(
      (s) => s.name == (map['status'] ?? 'PENDING'),
      orElse: () => PayoutStatus.pending,
    ),
    razorpayPayoutId: map['razorpay_payout_id'] as String?,
  );
}
