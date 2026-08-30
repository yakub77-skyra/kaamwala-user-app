// Phase 2 task 7/20: pricing comes from platform_config with a safe
// fallback chain - the booking fee must never be a UI-hardcoded surprise.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/models/pricing_config.dart';

void main() {
  group('PricingConfig.fromMap', () {
    test('structured pricing row wins', () {
      final p = PricingConfig.fromMap({
        'booking_fee_paise': 3000,
        'min_lead_minutes': 60,
        'max_lead_days': 14,
        'cancellation_policy': 'Custom policy',
        'refund_timeline': 'Custom timeline',
      });
      expect(p.bookingFeePaise, 3000);
      expect(p.bookingFeeRupees, 30);
      expect(p.minLeadMinutes, 60);
      expect(p.maxLeadDays, 14);
      expect(p.cancellationPolicy, 'Custom policy');
      expect(p.refundTimeline, 'Custom timeline');
    });

    test('legacy booking_fee_rupees key is honoured', () {
      final p = PricingConfig.fromMap({'booking_fee_rupees': 20});
      expect(p.bookingFeePaise, 2000);
      expect(p.bookingFeeRupees, 20);
    });

    test('missing config falls back to defaults (Rs.20 = 2000 paise)', () {
      final p = PricingConfig.fromMap({});
      expect(p.bookingFeePaise, 2000);
      expect(p.bookingFeeRupees, 20);
      expect(p.minLeadMinutes, 30);
      expect(p.maxLeadDays, 30);
      expect(p.cancellationPolicy, isNotEmpty);
      expect(p.refundTimeline, isNotEmpty);
    });

    test('string numbers parse (PostgREST may return strings)', () {
      final p = PricingConfig.fromMap({'booking_fee_paise': '2500'});
      expect(p.bookingFeePaise, 2500);
    });

    test('invalid fee falls back to the default, never zero/negative', () {
      final p = PricingConfig.fromMap({'booking_fee_paise': -5});
      expect(p.bookingFeePaise, 2000);
    });

    test('defaults mirror the platform constant (single source of truth)', () {
      expect(PricingConfig.defaults.bookingFeePaise, 20 * 100);
    });
  });
}
