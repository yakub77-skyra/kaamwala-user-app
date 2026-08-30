/// Domain constants - Phase 2 PRD (business model, categories, statuses).
library;

import 'package:flutter/material.dart';

/// 4 launch categories only - Phase 1 lesson: not all 12.
enum ServiceCategory {
  plumber('Plumber', Icons.plumbing),
  electrician('Electrician', Icons.electrical_services),
  painter('Painter', Icons.format_paint),
  carpenter('Carpenter', Icons.carpenter);

  const ServiceCategory(this.labelEn, this.icon);
  final String labelEn;
  final IconData icon;

  static ServiceCategory fromDb(String value) =>
      ServiceCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => ServiceCategory.plumber,
      );

  String get dbValue => name;
}

/// Booking lifecycle - Phase 2: payment states split from acceptance states.
/// payment_pending -> (paid) -> pending_acceptance -> accepted -> ...
/// payment_failed (retryable) | cancelled (by client, pre-acceptance).
/// `pending` is a legacy alias kept for pre-Phase-2 rows.
enum BookingStatus {
  paymentPending('Pending Payment'),
  paymentFailed('Payment Failed'),
  pendingAcceptance('Waiting for Worker'),
  pending('Pending'),
  accepted('Accepted'),
  traveling('Started Travel'),
  arrived('Arrived'),
  inProgress('Work In Progress'),
  completed('Completed'),
  cancelled('Cancelled'),
  declined('Declined');

  const BookingStatus(this.label);
  final String label;

  static BookingStatus fromDb(String value) => BookingStatus.values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => BookingStatus.paymentPending,
  );

  /// Wire format MUST match the bookings_guard trigger literals
  /// ('in_progress', 'payment_pending', ... not Dart camelCase) -
  /// regression-pinned by test/booking_model_test.dart.
  String get dbValue => switch (this) {
    BookingStatus.inProgress => 'in_progress',
    BookingStatus.paymentPending => 'payment_pending',
    BookingStatus.paymentFailed => 'payment_failed',
    BookingStatus.pendingAcceptance => 'pending_acceptance',
    final s => s.name,
  };

  /// Slot-reserving statuses: while a booking is in one of these, the
  /// worker's slot counts as taken for the overlap check.
  bool get occupiesSlot =>
      this == BookingStatus.paymentPending ||
      this == BookingStatus.paymentFailed ||
      this == BookingStatus.pendingAcceptance ||
      this == BookingStatus.pending ||
      isActive;

  bool get isActive =>
      this != BookingStatus.completed &&
      this != BookingStatus.cancelled &&
      this != BookingStatus.declined;

  /// Booking needs (or failed) payment: user can pay/retry.
  bool get needsPayment =>
      this == BookingStatus.paymentPending ||
      this == BookingStatus.paymentFailed;

  /// User can cancel: only before the worker accepts (full refund rule).
  bool get canCancel =>
      needsPayment ||
      this == BookingStatus.pendingAcceptance ||
      this == BookingStatus.pending;
}

/// Booking payment_status column - tracks the money state of a booking.
enum PaymentStatus {
  pending('Payment pending'),
  paid('Paid'),
  failed('Payment failed'),
  refunded('Refunded');

  const PaymentStatus(this.label);
  final String label;

  static PaymentStatus fromDb(String value) => PaymentStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => PaymentStatus.pending,
  );
}

/// Refund state on a cancelled booking.
enum RefundStatus {
  none('No refund applicable'),
  pending('Refund initiated'),
  processed('Refund completed'),
  failed('Refund could not be processed');

  const RefundStatus(this.label);
  final String label;

  static RefundStatus fromDb(String? value) => RefundStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => RefundStatus.none,
  );
}

/// Order status - Phase 3 section 7 orders table.
enum OrderStatus { created, paid, failed, refunded }

/// Payout status - Phase 3 section 7 payouts table.
enum PayoutStatus { pending, processing, success, failed }

abstract final class AppConstants {
  /// Flat convenience fee in rupees - v2 lesson: no fee tiers.
  static const int bookingFeeRupees = 20;

  /// Worker commission - worker keeps 90% (Phase 1 pillar: Fair Pay).
  static const double commissionRate = 0.10;

  static const String appTagline =
      'Find a verified worker in 30 seconds. Pay by UPI. Done.';
  static const String appName = 'KaamWala';
}
