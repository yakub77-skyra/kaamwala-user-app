/// Local draft persistence for the worker registration form.
///
/// Only lightweight basics are stored (name, city, category, price, step) -
/// document images are NOT persisted (sensitive + binary). If the app is
/// killed mid-flow, the user resumes at the saved step with basics intact and
/// re-adds documents/photos.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaamwala/features/worker/models/worker_registration.dart';

class WorkerRegistrationDraft {
  const WorkerRegistrationDraft({
    this.name = '',
    this.city = '',
    this.category = '',
    this.priceMin = 0,
    this.step = 0,
  });

  final String name;
  final String city;
  final String category;
  final int priceMin;

  /// 0-based step the user left off at (0..3).
  final int step;

  bool get isEmpty =>
      name.isEmpty && city.isEmpty && category.isEmpty && priceMin == 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'category': category,
    'priceMin': priceMin,
    'step': step,
  };

  factory WorkerRegistrationDraft.fromJson(Map<String, dynamic> json) =>
      WorkerRegistrationDraft(
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        category: json['category'] as String? ?? '',
        priceMin: (json['priceMin'] as num?)?.toInt() ?? 0,
        step: (json['step'] as num?)?.toInt() ?? 0,
      );

  /// Applies the draft onto a mutable [data] model (images untouched).
  void applyTo(WorkerRegistrationData data) {
    data.name = name;
    data.city = city;
    data.category = category;
    data.priceMin = priceMin;
  }

  static WorkerRegistrationDraft fromData(WorkerRegistrationData data) =>
      WorkerRegistrationDraft(
        name: data.name,
        city: data.city,
        category: data.category,
        priceMin: data.priceMin,
      );
}

/// Read/write helper around SharedPreferences.
abstract final class WorkerRegistrationDraftStore {
  /// SharedPreferences key (exposed for tests/debug).
  static const String debugKey = 'kw.worker.registration.draft.v1';

  static const String _key = debugKey;

  /// Loads the saved draft (null when none).
  static Future<WorkerRegistrationDraft?> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final draft = WorkerRegistrationDraft.fromJson(json);
      if (draft.isEmpty) return null;
      return draft;
    } catch (_) {
      return null; // Corrupt/old draft - start fresh.
    }
  }

  static Future<void> save(WorkerRegistrationDraft draft) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, jsonEncode(draft.toJson()));
    } catch (_) {
      // Best-effort persistence; never crash registration for this.
    }
  }

  /// Removes the draft (called after a successful submit).
  static Future<void> clear() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_key);
    } catch (_) {}
  }
}
