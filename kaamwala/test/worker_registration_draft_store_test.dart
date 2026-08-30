// Draft persistence for worker registration (Phase 1 - Task 10).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaamwala/features/worker/models/worker_registration.dart';
import 'package:kaamwala/features/worker/services/worker_registration_draft_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save -> load round-trip keeps name/city/category/price/step', () async {
    await WorkerRegistrationDraftStore.save(
      const WorkerRegistrationDraft(
        name: 'Ramesh',
        city: 'Kochi',
        category: 'plumber',
        priceMin: 500,
        step: 2,
      ),
    );
    final draft = await WorkerRegistrationDraftStore.load();
    expect(draft, isNotNull);
    expect(draft!.name, 'Ramesh');
    expect(draft.city, 'Kochi');
    expect(draft.category, 'plumber');
    expect(draft.priceMin, 500);
    expect(draft.step, 2);
  });

  test('load returns null when nothing saved / corrupt data', () async {
    expect(await WorkerRegistrationDraftStore.load(), isNull);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(WorkerRegistrationDraftStore.debugKey, 'not json');
    expect(await WorkerRegistrationDraftStore.load(), isNull);
  });

  test('empty draft is not treated as a resume point', () async {
    await WorkerRegistrationDraftStore.save(const WorkerRegistrationDraft());
    expect(await WorkerRegistrationDraftStore.load(), isNull);
  });

  test('clear removes the draft', () async {
    await WorkerRegistrationDraftStore.save(
      const WorkerRegistrationDraft(name: 'Ramesh', city: 'Pune'),
    );
    await WorkerRegistrationDraftStore.clear();
    expect(await WorkerRegistrationDraftStore.load(), isNull);
  });

  test('applyTo fills the mutable form model (images untouched)', () {
    final data = WorkerRegistrationData()..priceMin = 999;
    const draft = WorkerRegistrationDraft(
      name: 'Ramesh',
      city: 'Pune',
      category: 'painter',
      priceMin: 700,
      step: 1,
    );
    draft.applyTo(data);
    expect(data.name, 'Ramesh');
    expect(data.city, 'Pune');
    expect(data.category, 'painter');
    expect(data.priceMin, 700);
    expect(data.portfolioBytes, isEmpty);
  });
}
