// Phase 2 task 20: booking validation (dates, slots, lead time) - pure logic.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/services/booking/booking_validator.dart';
import 'package:kaamwala/models/pricing_config.dart';

void main() {
  const pricing = PricingConfig.defaults;
  final now = DateTime(2026, 8, 30, 9, 15); // 9:15 AM

  group('slot parsing + labels', () {
    test('parses start/end hours', () {
      expect(slotStartHour('8-10'), 8);
      expect(slotStartHour('18-20'), 18);
      expect(slotEndHour('10-12'), 12);
      expect(slotStartHour('99-100'), isNull);
      expect(slotStartHour(''), isNull);
    });

    test('labels are human-readable 12h windows', () {
      expect(slotLabel('8-10'), '8:00 AM - 10:00 AM');
      expect(slotLabel('14-16'), '2:00 PM - 4:00 PM');
      expect(slotLabel('12-14'), '12:00 PM - 2:00 PM');
    });
  });

  group('validateSlot', () {
    test('rejects past dates', () {
      final v = validateSlot(
        DateTime(2026, 8, 29),
        '10-12',
        now: now,
        pricing: pricing,
      );
      expect(v.isValid, isFalse);
      expect(v.issue, SlotIssue.past);
    });

    test('rejects today slots that start within the lead time', () {
      // 9:15 + 30min lead -> earliest slot START is 9:45.
      expect(
        validateSlot(now, '8-10', now: now, pricing: pricing).issue,
        SlotIssue.tooSoon,
      );
      // 10-12 starts at 10:00 >= 9:45 -> fine.
      expect(
        validateSlot(now, '10-12', now: now, pricing: pricing).isValid,
        isTrue,
      );
    });

    test('respects a larger lead time', () {
      const longLead = PricingConfig(
        bookingFeePaise: 2000,
        minLeadMinutes: 120,
        maxLeadDays: 30,
        cancellationPolicy: 'x',
        refundTimeline: 'y',
      );
      // 9:15 + 120min -> 11:15; 10-12 (starts 10:00) is too soon.
      expect(
        validateSlot(now, '10-12', now: now, pricing: longLead).issue,
        SlotIssue.tooSoon,
      );
      // 12-14 (starts 12:00) is fine.
      expect(
        validateSlot(now, '12-14', now: now, pricing: longLead).isValid,
        isTrue,
      );
      expect(
        validateSlot(now, '8-10', now: now, pricing: longLead).issue,
        SlotIssue.tooSoon,
      );
    });

    test('rejects dates beyond max lead days', () {
      final v = validateSlot(
        now.add(const Duration(days: 31)),
        '10-12',
        now: now,
        pricing: pricing,
      );
      expect(v.issue, SlotIssue.tooFar);
      expect(
        validateSlot(
          now.add(const Duration(days: 5)),
          '10-12',
          now: now,
          pricing: pricing,
        ).isValid,
        isTrue,
      );
    });

    test('rejects unknown slot strings', () {
      expect(
        validateSlot(now, '3-4', now: now, pricing: pricing).issue,
        SlotIssue.unknownSlot,
      );
    });
  });

  group('slotAvailability', () {
    test('marks taken + too-soon slots with reasons', () {
      final map = slotAvailability(
        now,
        now: now,
        pricing: pricing,
        takenSlots: {'12-14'},
      );
      expect(map['12-14'], 'Already booked');
      expect(map['8-10'], isNotEmpty); // too soon
      expect(map['10-12'], isEmpty); // available
    });
  });

  group('constants', () {
    test('slot occupying statuses match the server list', () {
      expect(
        kSlotOccupyingStatuses,
        containsAll(['payment_pending', 'accepted', 'in_progress']),
      );
      expect(kSlotOccupyingStatuses, isNot(contains('completed')));
      expect(kSlotOccupyingStatuses, isNot(contains('cancelled')));
    });

    test('min address/description lengths enforced by UI constants', () {
      expect(kMinDescriptionChars, 10);
      expect(kMinAddressChars, 10);
    });
  });
}
