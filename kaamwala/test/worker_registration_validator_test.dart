// Worker registration validation rules (Phase 1 - Task 8).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/features/worker/models/worker_registration.dart';

void main() {
  group('name', () {
    test('rejects empty / too short', () {
      expect(WorkerRegistrationValidator.name(''), isNotNull);
      expect(WorkerRegistrationValidator.name('  '), isNotNull);
      expect(WorkerRegistrationValidator.name('Ro'), isNotNull);
    });

    test('accepts >= 3 characters after trim', () {
      expect(WorkerRegistrationValidator.name('Rohit'), isNull);
      expect(WorkerRegistrationValidator.name('  Ram  '), isNull);
    });
  });

  group('city', () {
    test('rejects empty / too short', () {
      expect(WorkerRegistrationValidator.city(''), isNotNull);
      expect(WorkerRegistrationValidator.city('Pu'), isNotNull);
    });

    test('accepts ANY city >= 3 chars (free text, not a hardcoded list)', () {
      expect(WorkerRegistrationValidator.city('Pune'), isNull);
      expect(WorkerRegistrationValidator.city('Mumbai'), isNull);
      expect(WorkerRegistrationValidator.city('Kochi'), isNull);
      expect(WorkerRegistrationValidator.city('Guwahati'), isNull);
      expect(WorkerRegistrationValidator.city('  Nashik  '), isNull);
    });
  });

  group('category', () {
    test('required', () {
      expect(WorkerRegistrationValidator.category(''), isNotNull);
      expect(WorkerRegistrationValidator.category('plumber'), isNull);
    });
  });

  group('price', () {
    test('rejects empty / zero / negative / non-numeric', () {
      expect(WorkerRegistrationValidator.price(''), isNotNull);
      expect(WorkerRegistrationValidator.price('0'), isNotNull);
      expect(WorkerRegistrationValidator.price('-5'), isNotNull);
      expect(WorkerRegistrationValidator.price('abc'), isNotNull);
    });

    test('accepts positive day rates', () {
      expect(WorkerRegistrationValidator.price('300'), isNull);
      expect(WorkerRegistrationValidator.price('1500'), isNull);
    });
  });

  group('documents', () {
    final b1 = Uint8List.fromList([1, 2, 3]);
    final b2 = Uint8List.fromList([4, 5, 6]);

    test('both Aadhaar sides required', () {
      expect(WorkerRegistrationValidator.aadhaarValid(null, null), isFalse);
      expect(WorkerRegistrationValidator.aadhaarValid(b1, null), isFalse);
      expect(WorkerRegistrationValidator.aadhaarValid(null, b2), isFalse);
      expect(WorkerRegistrationValidator.aadhaarValid(b1, b2), isTrue);
    });
  });

  group('work photos', () {
    test('min 2, max 5', () {
      expect(WorkerRegistrationValidator.workPhotosValid(0), isFalse);
      expect(WorkerRegistrationValidator.workPhotosValid(1), isFalse);
      expect(WorkerRegistrationValidator.workPhotosValid(2), isTrue);
      expect(WorkerRegistrationValidator.workPhotosValid(5), isTrue);
      expect(WorkerRegistrationValidator.workPhotosValid(6), isFalse);
    });
  });

  group('step gates', () {
    WorkerRegistrationData validData() {
      final d = WorkerRegistrationData()
        ..name = 'Ramesh Kumar'
        ..city = 'Kochi'
        ..category = 'plumber'
        ..priceMin = 500;
      return d;
    }

    test('step 1 requires name+city+category+price', () {
      expect(WorkerRegistrationValidator.isStep1Valid(validData()), isTrue);
      expect(
        WorkerRegistrationValidator.isStep1Valid(validData()..name = ''),
        isFalse,
      );
      expect(
        WorkerRegistrationValidator.isStep1Valid(validData()..category = ''),
        isFalse,
      );
      expect(
        WorkerRegistrationValidator.isStep1Valid(validData()..priceMin = 0),
        isFalse,
      );
    });

    test('full form gates', () {
      final d = validData();
      expect(WorkerRegistrationValidator.isStep2Valid(d), isFalse);
      expect(WorkerRegistrationValidator.isStep3Valid(d), isFalse);
      expect(WorkerRegistrationValidator.allValid(d), isFalse);

      d.aadharFrontBytes = Uint8List.fromList([1]);
      d.aadharBackBytes = Uint8List.fromList([2]);
      expect(WorkerRegistrationValidator.isStep2Valid(d), isTrue);
      expect(WorkerRegistrationValidator.allValid(d), isFalse);

      d.portfolioBytes.addAll([
        Uint8List.fromList([3]),
        Uint8List.fromList([4]),
      ]);
      expect(WorkerRegistrationValidator.isStep3Valid(d), isTrue);
      expect(WorkerRegistrationValidator.allValid(d), isTrue);
    });
  });
}
