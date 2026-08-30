/// Worker registration data + validation rules.
///
/// Pure Dart (no Flutter imports) so every rule is unit-testable and the
/// screen only drives UI state from these results.
library;

import 'dart:typed_data';

/// Everything collected across the 4 registration steps.
class WorkerRegistrationData {
  String name = '';
  String city = '';
  String category = '';
  int priceMin = 0;
  Uint8List? aadharFrontBytes;
  Uint8List? aadharBackBytes;

  /// Work photos (min 2, max 5, CS-05) -> PUBLIC portfolios bucket.
  final List<Uint8List> portfolioBytes = [];
}

/// Step-agnostic validation rules for the registration form.
///
/// Every rule returns an error message (or null when valid) so screens can
/// render it inline, and `isStepNValid` gate the Next/Submit buttons.
abstract final class WorkerRegistrationValidator {
  static const int minNameLength = 3;
  static const int minCityLength = 3;
  static const int minWorkPhotos = 2;
  static const int maxWorkPhotos = 5;

  /// Name: required, trimmed, >= 3 chars.
  static String? name(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < minNameLength) {
      return 'Name must be at least $minNameLength characters';
    }
    return null;
  }

  /// City: required, trimmed, >= 3 chars. Any city is accepted (free text).
  static String? city(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Enter your city';
    if (v.length < minCityLength) {
      return 'City must be at least $minCityLength characters';
    }
    return null;
  }

  /// Category: one of the 4 service categories must be picked.
  static String? category(String raw) =>
      raw.isEmpty ? 'Select your work type' : null;

  /// Day rate: required and > 0.
  static String? price(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Enter your starting day rate';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Enter an amount greater than 0';
    if (n > 100000) return 'Enter an amount up to ₹1,00,000';
    return null;
  }

  /// Aadhaar front/back: both required (identity verification).
  static bool aadhaarValid(Uint8List? front, Uint8List? back) =>
      front != null && back != null;

  /// Work photos: min 2, max 5.
  static bool workPhotosValid(int count) =>
      count >= minWorkPhotos && count <= maxWorkPhotos;

  /// Full state checks used to enable Next/Submit.
  static bool isStep1Valid(WorkerRegistrationData d) =>
      name(d.name) == null &&
      city(d.city) == null &&
      category(d.category) == null &&
      price(d.priceMin.toString()) == null;

  static bool isStep2Valid(WorkerRegistrationData d) =>
      aadhaarValid(d.aadharFrontBytes, d.aadharBackBytes);

  static bool isStep3Valid(WorkerRegistrationData d) =>
      workPhotosValid(d.portfolioBytes.length);

  static bool allValid(WorkerRegistrationData d) =>
      isStep1Valid(d) && isStep2Valid(d) && isStep3Valid(d);
}
