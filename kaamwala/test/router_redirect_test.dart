// Routing policy table - every auth stage x representative location.
// Guards the redirect contract the whole app's navigation safety depends on.
import 'package:flutter_test/flutter_test.dart';

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
      expect(appRedirect(AppStage.onboarding, '/login'), '/onboarding');
    });

    test('login allows any /login* route (incl. OTP)', () {
      expect(appRedirect(AppStage.login, '/login'), isNull);
      expect(appRedirect(AppStage.login, '/login/otp'), isNull);
      expect(appRedirect(AppStage.login, '/home'), '/login');
      expect(appRedirect(AppStage.login, '/w/home'), '/login');
      expect(appRedirect(AppStage.login, '/role'), '/login');
    });

    test('roleSelection pins to /role', () {
      expect(appRedirect(AppStage.roleSelection, '/role'), isNull);
      expect(appRedirect(AppStage.roleSelection, '/home'), '/role');
      expect(appRedirect(AppStage.roleSelection, '/login/otp'), '/role');
    });

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
        '/login',
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

    test('workerApp: only /w/* passes; everything else -> /w/home', () {
      for (final ok in [
        '/w/home',
        '/w/earnings',
        '/w/profile',
        '/w/jobs',
        '/w/job/x',
        '/w/active/y',
      ]) {
        expect(appRedirect(AppStage.workerApp, ok), isNull, reason: ok);
      }
      for (final blocked in [
        '/',
        '/login',
        '/role',
        '/onboarding',
        '/home',
        '/bookings',
        '/worker/abc',
      ]) {
        expect(
          appRedirect(AppStage.workerApp, blocked),
          '/w/home',
          reason: blocked,
        );
      }
    });
  });
}
