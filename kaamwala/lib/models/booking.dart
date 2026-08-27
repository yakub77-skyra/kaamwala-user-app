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
    this.workerName = '',
    this.workerPhoto,
    this.createdAt,
    this.liveLat,
    this.liveLng,
    this.liveLocationUpdatedAt,
    this.photoUrls = const [],
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

  bool get isSharingLocation =>
      liveLat != null && liveLng != null && status == BookingStatus.traveling;

  bool get canCancel => status == BookingStatus.pending;

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
      workerName: workerUser is Map
          ? ((workerUser['name'] ?? '') as String)
          : '',
      workerPhoto: workerUser is Map
          ? workerUser['photo_url'] as String?
          : null,
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
      liveLat: (map['live_lat'] as num?)?.toDouble(),
      liveLng: (map['live_lng'] as num?)?.toDouble(),
      liveLocationUpdatedAt:
          DateTime.tryParse((map['live_location_updated_at'] ?? '') as String),
      photoUrls: (map['photo_urls'] as List?)?.cast<String>() ?? const [],
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
