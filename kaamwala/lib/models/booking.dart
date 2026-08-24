/// bookings + orders + payouts models - Phase 3 section 7.1.
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
    this.status = BookingStatus.pending,
    this.estimateMin = 0,
    this.estimateMax = 0,
    this.bookingFee = AppConstants.bookingFeeRupees,
    this.commissionRate = AppConstants.commissionRate,
    this.commissionAmount = 0,
    this.workerEarning = 0,
    this.clientConfirmed = false,
    this.clientName = '',
    this.createdAt,
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

  bool get canCancel => status == BookingStatus.pending;

  factory Booking.fromMap(Map<String, dynamic> map) {
    final client = map['users'];
    return Booking(
      id: map['id'] as String,
      ref: (map['ref'] ?? '') as String,
      clientId: map['client_id'] as String,
      workerId: map['worker_id'] as String,
      category: ServiceCategory.fromDb(map['category'] as String? ?? 'plumber'),
      description: (map['description'] ?? '') as String,
      serviceDate: DateTime.tryParse((map['service_date'] ?? '') as String),
      timeSlot: (map['time_slot'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      status: BookingStatus.fromDb(map['status'] as String? ?? 'pending'),
      estimateMin: (map['estimate_min'] ?? 0) as num,
      estimateMax: (map['estimate_max'] ?? 0) as num,
      bookingFee: (map['booking_fee'] ?? AppConstants.bookingFeeRupees) as num,
      commissionRate:
          (map['commission_rate'] ?? AppConstants.commissionRate) as num,
      commissionAmount: (map['commission_amount'] ?? 0) as num,
      workerEarning: (map['worker_earning'] ?? 0) as num,
      clientConfirmed: (map['client_confirmed'] ?? false) as bool,
      clientName: client is Map ? ((client['name'] ?? '') as String) : '',
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
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
