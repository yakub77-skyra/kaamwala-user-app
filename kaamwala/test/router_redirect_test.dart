// Routing policy table - every auth stage x representative location.
// Guards the redirect contract the whole app's navigation safety depends on.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';

void main() {
  group('appRedirect', () {
    test('loading & startupError pin to splash', () {
      for (final stage in [AppStage.loading, AppStage.startupError]) {
        expect(appRedirect(stage, '/'), '/');
        expect(appRedirect(stage, '/home'), '/');
        expect(appRedirect(stage, '/w/home'), '/');
      }
    });

    test('onboarding allows only /onboarding', () {
      expect(appRedirect(AppStage.onboarding, '/onboarding'), isNull);
      expect(appRedirect(AppStage.onboarding, '/home'), '/onboarding');
      expect(appRedirect(AppStage.onboarding, '/login/phone'), '/onboarding');
    });

    test('roleSelection pins to /role', () {
      expect(appRedirect(AppStage.roleSelection, '/role'), isNull);
      expect(appRedirect(AppStage.roleSelection, '/home'), '/role');
      expect(appRedirect(AppStage.roleSelection, '/login/phone'), '/role');
      expect(appRedirect(AppStage.roleSelection, '/login/otp'), '/role');
    });

    test('phoneEntry pins to /login/phone', () {
      expect(appRedirect(AppStage.phoneEntry, '/login/phone'), isNull);
      expect(appRedirect(AppStage.phoneEntry, '/home'), '/login/phone');
      expect(appRedirect(AppStage.phoneEntry, '/role'), '/login/phone');
      expect(appRedirect(AppStage.phoneEntry, '/login/otp'), '/login/phone');
    });

    test('worker cannot bypass phone number (no /w/* before verification)', () {
      // A fresh worker who has NOT verified a phone is in phoneEntry stage:
      // any attempt to jump into the worker area is pinned back to /login/phone.
      expect(appRedirect(AppStage.phoneEntry, '/w/register'), '/login/phone');
      expect(appRedirect(AppStage.phoneEntry, '/w/home'), '/login/phone');
      expect(appRedirect(AppStage.phoneEntry, '/w/jobs'), '/login/phone');
    });

    test('worker registration only reachable once in the worker app', () {
      expect(
        appRedirect(
          AppStage.workerApp,
          '/w/register',
          flavor: AppFlavor.partner,
        ),
        isNull,
      );
      // Client in the worker binary cannot reach registration either.
      expect(
        appRedirect(
          AppStage.clientApp,
          '/w/register',
          flavor: AppFlavor.partner,
        ),
        '/wrong-app',
      );
    });

    test(
      'otpVerification pins to /login/otp (phone allowed for change number)',
      () {
        expect(appRedirect(AppStage.otpVerification, '/login/otp'), isNull);
        expect(appRedirect(AppStage.otpVerification, '/home'), '/login/otp');
        expect(appRedirect(AppStage.otpVerification, '/role'), '/login/otp');
        // "Change number" must not be a dead-end (Phase 1 fix).
        expect(appRedirect(AppStage.otpVerification, '/login/phone'), isNull);
      },
    );

    test('clientApp: app routes pass, auth/splash/worker routes -> /home', () {
      for (final ok in [
        '/home',
        '/search',
        '/bookings',
        '/profile',
        '/worker/abc',
        '/book/w1',
        '/payment/b1',
        '/chat/b1',
        '/rate/b1',
      ]) {
        expect(appRedirect(AppStage.clientApp, ok), isNull, reason: ok);
      }
      for (final blocked in [
        '/',
        '/login/phone',
        '/login/otp',
        '/role',
        '/onboarding',
        '/w/home',
        '/w/jobs',
      ]) {
        expect(
          appRedirect(AppStage.clientApp, blocked),
          '/home',
          reason: blocked,
        );
      }
    });

    test('workerApp (partner binary): only /w/* passes; else -> /w/home', () {
      for (final ok in [
        '/w/home',
        '/w/earnings',
        '/w/profile',
        '/w/jobs',
        '/w/job/x',
        '/w/active/y',
      ]) {
        expect(
          appRedirect(AppStage.workerApp, ok, flavor: AppFlavor.partner),
          isNull,
          reason: ok,
        );
      }
      for (final blocked in [
        '/',
        '/login/phone',
        '/login/otp',
        '/role',
        '/onboarding',
        '/home',
        '/bookings',
        '/worker/abc',
      ]) {
        expect(
          appRedirect(AppStage.workerApp, blocked, flavor: AppFlavor.partner),
          '/w/home',
          reason: blocked,
        );
      }
    });
  });

  group('appRedirect flavor gate (two-app split)', () {
    test('customer binary: worker account lands on /wrong-app', () {
      for (final loc in ['/', '/home', '/w/home', '/w/jobs', '/role']) {
        expect(
          appRedirect(AppStage.workerApp, loc, flavor: AppFlavor.customer),
          '/wrong-app',
          reason: loc,
        );
      }
      // /wrong-app itself passes through.
      expect(
        appRedirect(
          AppStage.workerApp,
          '/wrong-app',
          flavor: AppFlavor.customer,
        ),
        isNull,
      );
    });

    test('partner binary: client account lands on /wrong-app', () {
      for (final loc in ['/', '/home', '/search', '/bookings', '/profile']) {
        expect(
          appRedirect(AppStage.clientApp, loc, flavor: AppFlavor.partner),
          '/wrong-app',
          reason: loc,
        );
      }
      expect(
        appRedirect(
          AppStage.clientApp,
          '/wrong-app',
          flavor: AppFlavor.partner,
        ),
        isNull,
      );
    });

    test('partner binary: worker flows unaffected', () {
      expect(
        appRedirect(AppStage.workerApp, '/w/home', flavor: AppFlavor.partner),
        isNull,
      );
      expect(
        appRedirect(AppStage.workerApp, '/home', flavor: AppFlavor.partner),
        '/w/home',
      );
    });

    test('auth stages are flavor-agnostic', () {
      for (final flavor in AppFlavor.values) {
        expect(
          appRedirect(AppStage.phoneEntry, '/x', flavor: flavor),
          '/login/phone',
        );
        expect(
          appRedirect(AppStage.roleSelection, '/x', flavor: flavor),
          '/role',
        );
        expect(appRedirect(AppStage.loading, '/x', flavor: flavor), '/');
      }
    });

    test('default flavor is customer (back-compat for existing callers)', () {
      expect(appRedirect(AppStage.clientApp, '/home'), isNull);
      expect(appRedirect(AppStage.workerApp, '/home'), '/wrong-app');
    });
  });
}
