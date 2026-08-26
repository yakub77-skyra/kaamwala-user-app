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

/// Booking lifecycle - FR-CLIENT-06 / FR-WORKER-07.
enum BookingStatus {
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
    orElse: () => BookingStatus.pending,
  );

  /// Wire format MUST match the bookings_guard trigger literals
  /// ('in_progress', not Dart's camelCase 'inProgress') - regression-pinned
  /// by test/booking_model_test.dart.
  String get dbValue => switch (this) {
    BookingStatus.inProgress => 'in_progress',
    final s => s.name,
  };

  bool get isActive =>
      this != BookingStatus.completed &&
      this != BookingStatus.cancelled &&
      this != BookingStatus.declined;
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
