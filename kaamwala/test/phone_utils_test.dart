// Phone validation/normalization rules (Phase 1 - Task 4).
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/services/phone/phone_utils.dart';

void main() {
  group('isValidIndianMobile', () {
    test('accepts plain 10-digit numbers', () {
      expect(isValidIndianMobile('9876543210'), isTrue);
      expect(isValidIndianMobile('0123456789'), isTrue);
    });

    test('accepts 91-prefixed 12-digit numbers', () {
      expect(isValidIndianMobile('919876543210'), isTrue);
      expect(isValidIndianMobile('+919876543210'), isTrue);
    });

    test('accepts formatted input (spaces/dashes)', () {
      expect(isValidIndianMobile('+91 98765 43210'), isTrue);
      expect(isValidIndianMobile('98765-43210'), isTrue);
    });

    test('rejects empty / short / long / non-numeric', () {
      expect(isValidIndianMobile(''), isFalse);
      expect(isValidIndianMobile('123'), isFalse);
      expect(isValidIndianMobile('987654321'), isFalse);
      expect(isValidIndianMobile('98765432101'), isFalse);
      expect(isValidIndianMobile('abcdefghij'), isFalse);
      expect(isValidIndianMobile('1234567890a'), isFalse);
    });
  });

  group('normalizePhoneE164', () {
    test('normalizes plain 10-digit to +91', () {
      expect(normalizePhoneE164('9876543210'), '+919876543210');
    });

    test('normalizes 91-prefixed to +91', () {
      expect(normalizePhoneE164('919876543210'), '+919876543210');
      expect(normalizePhoneE164('+919876543210'), '+919876543210');
    });

    test('strips spaces and formatting', () {
      expect(normalizePhoneE164('+91 98765 43210'), '+919876543210');
      expect(normalizePhoneE164('98765-43210'), '+919876543210');
    });
  });

  group('maskPhoneE164', () {
    test('masks middle digits, keeps last 4', () {
      expect(maskPhoneE164('+919876543210'), '+91 ••••• 3210');
    });
  });

  group('normalizeCity', () {
    test('trims and title-cases', () {
      expect(normalizeCity('  pUNE '), 'Pune');
      expect(normalizeCity('MUMBAI'), 'Mumbai');
      expect(normalizeCity('new delhi'), 'New Delhi');
      expect(normalizeCity(''), '');
    });
  });
}
