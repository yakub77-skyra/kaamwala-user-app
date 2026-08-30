/// Server-side pricing config (platform_config['pricing']) - Phase 2 task 7.
/// The DB is the source of truth; [defaults] only kick in when the config
/// row is absent (legacy/degraded mode).
library;

import 'package:kaamwala/core/constants/app_constants.dart';

class PricingConfig {
  const PricingConfig({
    required this.bookingFeePaise,
    required this.minLeadMinutes,
    required this.maxLeadDays,
    required this.cancellationPolicy,
    required this.refundTimeline,
  });

  static const PricingConfig defaults = PricingConfig(
    bookingFeePaise: AppConstants.bookingFeeRupees * 100,
    minLeadMinutes: 30,
    maxLeadDays: 30,
    cancellationPolicy:
        'Free cancellation before the worker accepts your booking. '
        'The booking fee is refunded in full.',
    refundTimeline:
        'Refunds are initiated immediately on cancellation and usually '
        'reach your bank in 3-5 business days.',
  );

  /// Booking fee in PAISE - all payment math stays in paise (no floats).
  final int bookingFeePaise;
  final int minLeadMinutes;
  final int maxLeadDays;
  final String cancellationPolicy;
  final String refundTimeline;

  int get bookingFeeRupees => bookingFeePaise ~/ 100;

  factory PricingConfig.fromMap(Map<String, dynamic> map) {
    final legacyFee = map['booking_fee_rupees'];
    final rawFee =
        _firstInt(map['booking_fee_paise']) ??
        (legacyFee is num ? legacyFee.toInt() * 100 : null);
    return PricingConfig(
      // Fee must be positive; anything else falls back (mirrors server).
      bookingFeePaise: (rawFee != null && rawFee > 0)
          ? rawFee
          : defaults.bookingFeePaise,
      minLeadMinutes:
          _firstInt(map['min_lead_minutes']) ?? defaults.minLeadMinutes,
      maxLeadDays: _firstInt(map['max_lead_days']) ?? defaults.maxLeadDays,
      cancellationPolicy:
          (map['cancellation_policy'] as String?)?.isNotEmpty == true
          ? map['cancellation_policy'] as String
          : defaults.cancellationPolicy,
      refundTimeline: (map['refund_timeline'] as String?)?.isNotEmpty == true
          ? map['refund_timeline'] as String
          : defaults.refundTimeline,
    );
  }

  static int? _firstInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
