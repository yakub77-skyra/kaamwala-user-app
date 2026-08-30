// MockSmsGateway behaviour (Phase 1 - Task 2/5):
// send -> verify round-trip, wrong-code errors, expired codes, resend
// cooldown, resend budget, max wrong attempts, demo OTP visibility.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/services/sms/mock_sms_gateway.dart';
import 'package:kaamwala/core/services/sms/sms_gateway.dart';
import 'package:kaamwala/core/services/sms/sms_result.dart';

const _phone = '+919876543210';
const _purpose = OtpPurpose.login;

void main() {
  late SmsOtpStore store;
  late MockSmsGateway gateway;

  setUp(() {
    store = SmsOtpStore(
      otpExpiry: const Duration(seconds: 5),
      resendCooldown: const Duration(seconds: 2),
      maxResendsPerWindow: 3,
      maxVerifyAttempts: 3,
    );
    gateway = MockSmsGateway(store: store);
  });

  group('sendOtp', () {
    test('returns success with a 6-digit dev OTP', () async {
      final r = await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      expect(r.success, isTrue);
      expect(r.otpDevOnly, isNotNull);
      expect(r.otpDevOnly!.length, 6);
      expect(RegExp(r'^\d{6}$').hasMatch(r.otpDevOnly!), isTrue);
      expect(r.expiresInSeconds, greaterThan(0));
      expect(r.resendAfterSeconds, greaterThan(0));
    });

    test('otpFor() surfaces the stored OTP (demo banner source)', () async {
      final r = await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      expect(gateway.otpFor(_phone, _purpose), r.otpDevOnly);
    });

    test('isDemoMode is always true', () {
      expect(gateway.isDemoMode, isTrue);
    });
  });

  group('verifyOtp', () {
    test('correct OTP verifies and is consumed', () async {
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final otp = gateway.otpFor(_phone, _purpose)!;

      final ok = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: otp,
        purpose: _purpose,
      );
      expect(ok.success, isTrue);

      // Consumed: a second verification with the same code fails.
      final again = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: otp,
        purpose: _purpose,
      );
      expect(again.success, isFalse);
    });

    test('wrong OTP returns a clear error', () async {
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final r = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: '000000',
        purpose: _purpose,
      );
      expect(r.success, isFalse);
      expect(r.message.toLowerCase(), contains('invalid'));
    });

    test('expired OTP is rejected (cleanup: no in-progress OTP)', () async {
      store = SmsOtpStore(
        otpExpiry: const Duration(milliseconds: 50),
        resendCooldown: const Duration(seconds: 1),
        maxResendsPerWindow: 3,
        maxVerifyAttempts: 3,
      );
      gateway = MockSmsGateway(store: store);
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final otp = gateway.otpFor(_phone, _purpose)!;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final r = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: otp,
        purpose: _purpose,
      );
      expect(r.success, isFalse);
      expect(r.message.toLowerCase(), contains('no otp'));
    });

    test('too many wrong attempts locks verification', () async {
      store = SmsOtpStore(
        otpExpiry: const Duration(seconds: 30),
        resendCooldown: const Duration(milliseconds: 100),
        maxResendsPerWindow: 3,
        maxVerifyAttempts: 3,
      );
      gateway = MockSmsGateway(store: store);
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final otp = gateway.otpFor(_phone, _purpose)!;

      for (var i = 0; i < 3; i++) {
        final r = await gateway.verifyOtp(
          phoneE164: _phone,
          otp: '111111',
          purpose: _purpose,
        );
        expect(r.success, isFalse);
      }

      // Even the correct code is now rejected until a new OTP is sent.
      final locked = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: otp,
        purpose: _purpose,
      );
      expect(locked.success, isFalse);
      expect(locked.message.toLowerCase(), contains('too many wrong'));

      // A fresh OTP resets the lock.
      final resent = await gateway.resendOtp(
        phoneE164: _phone,
        purpose: _purpose,
      );
      expect(resent.success, isTrue);
      final ok = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: gateway.otpFor(_phone, _purpose)!,
        purpose: _purpose,
      );
      expect(ok.success, isTrue);
    });
  });

  group('resend / rate limiting', () {
    test('resend within cooldown is rate limited with wait time', () async {
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final r = await gateway.resendOtp(phoneE164: _phone, purpose: _purpose);
      expect(r.success, isFalse);
      expect(r.resendAfterSeconds, greaterThan(0));
    });

    test('resend after cooldown issues a fresh OTP', () async {
      store = SmsOtpStore(
        otpExpiry: const Duration(seconds: 30),
        resendCooldown: const Duration(milliseconds: 100),
        maxResendsPerWindow: 3,
        maxVerifyAttempts: 3,
      );
      gateway = MockSmsGateway(store: store);
      final first = await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final second = await gateway.resendOtp(
        phoneE164: _phone,
        purpose: _purpose,
      );
      expect(second.success, isTrue);
      expect(second.otpDevOnly, isNot(first.otpDevOnly));
    });

    test('resend budget is capped (no infinite spamming)', () async {
      store = SmsOtpStore(
        otpExpiry: const Duration(minutes: 5),
        resendCooldown: const Duration(milliseconds: 1),
        maxResendsPerWindow: 3,
        maxVerifyAttempts: 3,
      );
      gateway = MockSmsGateway(store: store);

      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      for (var i = 0; i < 2; i++) {
        final r = await gateway.resendOtp(phoneE164: _phone, purpose: _purpose);
        expect(r.success, isTrue);
      }
      final blocked = await gateway.resendOtp(
        phoneE164: _phone,
        purpose: _purpose,
      );
      expect(blocked.success, isFalse);
      expect(blocked.message.toLowerCase(), contains('too many'));
    });

    test('per-phone keys isolate OTPs (changing number is safe)', () async {
      await gateway.sendOtp(phoneE164: _phone, purpose: _purpose);
      final other = await gateway.sendOtp(
        phoneE164: '+919000000001',
        purpose: _purpose,
      );
      expect(other.success, isTrue);
      expect(gateway.otpFor(_phone, _purpose), isNotNull);
    });
  });

  test('SmsResult factories carry the expected shape', () {
    final ok = SmsResult.success(otpDevOnly: '123456');
    expect(ok.success, isTrue);
    expect(ok.otpDevOnly, '123456');
    expect(ok.expiresInSeconds, 300);
    expect(ok.resendAfterSeconds, 30);

    final limited = SmsResult.rateLimited(
      message: 'slow down',
      resendAfterSeconds: 45,
    );
    expect(limited.success, isFalse);
    expect(limited.resendAfterSeconds, 45);
  });
}
