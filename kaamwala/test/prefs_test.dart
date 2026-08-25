// PrefsController - local settings persistence (notifications toggle).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaamwala/features/shared/providers/shared_providers.dart';

/// Pumps microtasks until the async _load() lands (channel round-trips need
/// more than fixed Duration.zero delays).
Future<void> _pumpUntilLoaded(ProviderContainer container) async {
  for (var i = 0; i < 200 && !container.read(prefsProvider).loaded; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults: notifications on when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpUntilLoaded(container);

    expect(container.read(prefsProvider).loaded, isTrue);
    expect(container.read(prefsProvider).notificationsOn, isTrue);
  });

  test('setNotificationsOn persists the toggle', () async {
    // NOTE: must run AFTER the defaults test - the shared_preferences mock
    // plugin caches its store on first use, so setMockInitialValues cannot
    // reset it within one process.
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(prefsProvider.notifier).setNotificationsOn(false);

    final sp = await SharedPreferences.getInstance();
    expect(sp.getBool('settings.notifications_on'), false);
  });
}
