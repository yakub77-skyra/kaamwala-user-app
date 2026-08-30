/// Pure booking validation logic (Phase 2 tasks 3 + 20) - no I/O, unit
/// tested. Mirrors the server-side rules in create-order so the UI disables
/// invalid choices before the server rejects them.
library;

import 'package:kaamwala/models/pricing_config.dart';

/// 2-hour booking windows; wire format 'start-end' in 24h hours.
/// Matches the server SLOTS list (create-order).
const List<String> kBookingSlots = [
  '8-10',
  '10-12',
  '12-14',
  '14-16',
  '16-18',
  '18-20',
];

/// Statuses that reserve a worker's slot (overlap check source).
const Set<String> kSlotOccupyingStatuses = {
  'payment_pending',
  'payment_failed',
  'pending_acceptance',
  'pending',
  'accepted',
  'traveling',
  'arrived',
  'in_progress',
};

const int kMinDescriptionChars = 10;
const int kMaxDescriptionChars = 500;
const int kMinAddressChars = 10;
const int kMaxAddressChars = 300;

enum SlotIssue { none, past, tooSoon, tooFar, unknownSlot }

/// Why a date/slot combination is (or isn't) bookable.
class SlotValidation {
  const SlotValidation._(this.issue, {this.reason});

  const SlotValidation.valid() : this._(SlotIssue.none);

  const SlotValidation.invalid(this.issue, {required this.reason});

  final SlotIssue issue;
  final String? reason;

  bool get isValid => issue == SlotIssue.none;
}

/// Parses '8-10' -> 8 (start hour). Null when unknown/malformed.
int? slotStartHour(String slot) {
  if (!kBookingSlots.contains(slot)) return null;
  final start = int.tryParse(slot.split('-').first);
  return start;
}

/// Parses '8-10' -> 10 (end hour).
int? slotEndHour(String slot) {
  final start = slotStartHour(slot);
  return start == null ? null : start + 2;
}

/// Human label: '8-10' -> '8:00 AM - 10:00 AM'.
String slotLabel(String slot) {
  final start = slotStartHour(slot);
  if (start == null) return slot;
  return '${_hourLabel(start)} - ${_hourLabel(start + 2)}';
}

String _hourLabel(int hour24) {
  final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final ampm = hour24 < 12 ? 'AM' : 'PM';
  return '$h:00 $ampm';
}

/// Validates [slot] on [date] against [now] using the pricing lead-time
/// rules (same math as create-order: a slot on today must END at least
/// minLeadMinutes from now).
SlotValidation validateSlot(
  DateTime date,
  String slot, {
  required DateTime now,
  required PricingConfig pricing,
}) {
  final start = slotStartHour(slot);
  if (start == null) {
    return SlotValidation.invalid(
      SlotIssue.unknownSlot,
      reason: 'Please select a valid time slot',
    );
  }
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day.isBefore(today)) {
    return const SlotValidation.invalid(
      SlotIssue.past,
      reason: 'You cannot book a past date',
    );
  }
  final maxDay = today.add(Duration(days: pricing.maxLeadDays));
  if (day.isAfter(maxDay)) {
    return SlotValidation.invalid(
      SlotIssue.tooFar,
      reason: 'Please pick a date within the next ${pricing.maxLeadDays} days',
    );
  }
  if (day == today) {
    // Lead-time rule: the slot must START at least minLeadMinutes from now.
    final slotStartMinutes = start * 60;
    final earliestAllowed = now.hour * 60 + now.minute + pricing.minLeadMinutes;
    if (slotStartMinutes < earliestAllowed) {
      return SlotValidation.invalid(
        SlotIssue.tooSoon,
        reason:
            'Too soon — at least ${pricing.minLeadMinutes} minutes ahead. '
            'Please pick a later slot.',
      );
    }
  }
  return const SlotValidation.valid();
}

/// Which slots are currently selectable for [date] (empty reason = fine).
Map<String, String> slotAvailability(
  DateTime date, {
  required DateTime now,
  required PricingConfig pricing,
  Set<String>? takenSlots,
}) {
  final result = <String, String>{};
  for (final slot in kBookingSlots) {
    final taken = takenSlots?.contains(slot) ?? false;
    final v = validateSlot(date, slot, now: now, pricing: pricing);
    if (taken) {
      result[slot] = 'Already booked';
    } else if (v.isValid) {
      result[slot] = '';
    } else {
      result[slot] = v.reason ?? 'Unavailable';
    }
  }
  return result;
}
