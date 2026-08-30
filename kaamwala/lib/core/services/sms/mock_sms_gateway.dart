/// Mock SMS gateway for development and testing.
/// Stores OTPs in memory and simulates network delay.
///
/// The store is pluggable so tests can inject tiny expiries/limits; the app
/// uses [SmsOtpStore.instance] so codes survive across screens (phone entry
/// sends, OTP screen verifies/resends).
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'sms_gateway.dart';
import 'sms_result.dart';

/// In-memory OTP store with expiration, resend cooldown and attempt limits.
class SmsOtpStore {
  SmsOtpStore({
    this.otpExpiry = const Duration(minutes: 5),
    this.resendCooldown = const Duration(seconds: 30),
    this.maxResendsPerWindow = 3,
    this.maxVerifyAttempts = 3,
  });

  /// Shared instance used by the app (a long-lived singleton so OTPs survive
  /// navigation between phone entry and OTP screens).
  static final SmsOtpStore instance = SmsOtpStore();

  final Duration otpExpiry;
  final Duration resendCooldown;
  final int maxResendsPerWindow;
  final int maxVerifyAttempts;

  final Map<String, _OtpEntry> _store = {};

  String _generateOtp() {
    final random = Random.secure();
    // 6 digits (100000..999999)
    return (random.nextInt(900000) + 100000).toString();
  }

  void _cleanup() {
    final now = DateTime.now();
    _store.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }

  SmsResult sendOtp({required String phoneE164, required OtpPurpose purpose}) {
    _cleanup();
    final key = '$phoneE164:${purpose.name}';
    final existing = _store[key];

    // Resend cooldown (also covers double-tap send).
    if (existing != null) {
      final now = DateTime.now();
      final timeSinceLastSend = now.difference(existing.sentAt).inSeconds;
      if (timeSinceLastSend < resendCooldown.inSeconds) {
        return SmsResult.rateLimited(
          message:
              'Please wait ${resendCooldown.inSeconds - timeSinceLastSend}s before resending',
          resendAfterSeconds: resendCooldown.inSeconds - timeSinceLastSend,
        );
      }

      // Max resends per window (1h).
      final windowStart = DateTime.now().subtract(const Duration(hours: 1));
      if (existing.resendCount >= maxResendsPerWindow &&
          existing.firstSentAt.isAfter(windowStart)) {
        return SmsResult.rateLimited(
          message: 'Too many resend attempts. Please try again in an hour.',
          resendAfterSeconds: 3600,
        );
      }
    }

    final otp = _generateOtp();
    final now = DateTime.now();

    _store[key] = _OtpEntry(
      otp: otp,
      sentAt: now,
      expiresAt: now.add(otpExpiry),
      resendCount: (existing?.resendCount ?? 0) + 1,
      firstSentAt: existing?.firstSentAt ?? now,
      purpose: purpose,
      verifyFails: 0,
      lockedUntil: null,
    );

    // Log OTP in debug mode (developers never need to watch the console
    // to test - the UI shows a DEMO banner as well).
    if (kDebugMode) {
      debugPrint('🔐 [MOCK SMS] OTP for $phoneE164 (${purpose.name}): $otp');
      debugPrint(
        '   Expires in ${otpExpiry.inMinutes}m, sends left: ${(maxResendsPerWindow - _store[key]!.resendCount).clamp(0, maxResendsPerWindow)}',
      );
    }

    return SmsResult.success(
      message: 'OTP sent to $phoneE164',
      otpDevOnly: kDebugMode ? otp : null,
      expiresInSeconds: otpExpiry.inSeconds,
      resendAfterSeconds: resendCooldown.inSeconds,
    );
  }

  SmsResult verifyOtp({
    required String phoneE164,
    required String otp,
    required OtpPurpose purpose,
  }) {
    _cleanup();
    final key = '$phoneE164:${purpose.name}';
    final entry = _store[key];

    if (entry == null) {
      return SmsResult.failure(
        message: 'No OTP in progress. Please request a new one.',
        resendAfterSeconds: 0,
      );
    }

    if (entry.lockedUntil != null &&
        DateTime.now().isBefore(entry.lockedUntil!)) {
      return SmsResult.failure(
        message: 'Too many wrong attempts. Resend a new OTP to try again.',
        resendAfterSeconds: 0,
      );
    }

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return SmsResult.failure(
        message: 'OTP expired. Please request a new one.',
        resendAfterSeconds: 0,
      );
    }

    if (entry.otp != otp) {
      final fails = entry.verifyFails + 1;
      if (fails >= maxVerifyAttempts) {
        entry.lockedUntil = DateTime.now().add(otpExpiry);
        return SmsResult.failure(
          message: 'Too many wrong attempts. Please resend a new OTP before trying again.',
          resendAfterSeconds: 0,
        );
      }
      entry.verifyFails = fails;
      return SmsResult.failure(
        message: 'Invalid OTP. Please try again.',
        resendAfterSeconds: resendCooldown.inSeconds,
      );
    }

    // Success - remove the used OTP.
    _store.remove(key);

    if (kDebugMode) {
      debugPrint('✅ [MOCK SMS] OTP verified for $phoneE164 (${purpose.name})');
    }

    return SmsResult.success(
      message: 'OTP verified successfully',
      expiresInSeconds: 0,
      resendAfterSeconds: 0,
    );
  }

  SmsResult resendOtp({
    required String phoneE164,
    required OtpPurpose purpose,
  }) {
    // Resend is the same as send; we preserve firstSentAt for the window count.
    return sendOtp(phoneE164: phoneE164, purpose: purpose);
  }

  /// The OTP currently outstanding for this phone/purpose (dev visibility).
  String? otpFor(String phoneE164, OtpPurpose purpose) {
    _cleanup();
    return _store['$phoneE164:${purpose.name}']?.otp;
  }

  bool get isDemoMode => true;

  /// Clears all stored OTPs (useful for testing).
  void clear() => _store.clear();

  /// Remaining seconds on the current OTP (or null when none).
  int? getRemainingSeconds(String phoneE164, OtpPurpose purpose) {
    _cleanup();
    final entry = _store['$phoneE164:${purpose.name}'];
    if (entry == null) return null;
    return entry.expiresAt.difference(DateTime.now()).inSeconds;
  }

  /// Sends left for the current hour (resend budget).
  int getResendsLeft(String phoneE164, OtpPurpose purpose) {
    _cleanup();
    final entry = _store['$phoneE164:${purpose.name}'];
    if (entry == null) return maxResendsPerWindow;
    final windowStart = DateTime.now().subtract(const Duration(hours: 1));
    if (entry.firstSentAt.isBefore(windowStart)) return maxResendsPerWindow;
    return (maxResendsPerWindow - entry.resendCount).clamp(
      0,
      maxResendsPerWindow,
    );
  }
}

class _OtpEntry {
  _OtpEntry({
    required this.otp,
    required this.sentAt,
    required this.expiresAt,
    required this.resendCount,
    required this.firstSentAt,
    required this.purpose,
    required this.verifyFails,
    required this.lockedUntil,
  });

  final String otp;
  final DateTime sentAt;
  final DateTime expiresAt;
  final int resendCount;
  final DateTime firstSentAt;
  final OtpPurpose purpose;
  int verifyFails;
  DateTime? lockedUntil;
}

/// Mock SMS gateway implementation - the Phase-1 default.
class MockSmsGateway implements SmsGateway {
  MockSmsGateway({SmsOtpStore? store}) : _store = store ?? SmsOtpStore.instance;

  final SmsOtpStore _store;

  @override
  Future<SmsResult> sendOtp({
    required String phoneE164,
    required OtpPurpose purpose,
  }) async {
    // Simulate network delay.
    await Future.delayed(const Duration(milliseconds: 500));
    return _store.sendOtp(phoneE164: phoneE164, purpose: purpose);
  }

  @override
  Future<SmsResult> verifyOtp({
    required String phoneE164,
    required String otp,
    required OtpPurpose purpose,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _store.verifyOtp(phoneE164: phoneE164, otp: otp, purpose: purpose);
  }

  @override
  Future<SmsResult> resendOtp({
    required String phoneE164,
    required OtpPurpose purpose,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _store.resendOtp(phoneE164: phoneE164, purpose: purpose);
  }

  @override
  bool get isDemoMode => true;

  /// OTP currently stored for this phone/purpose (demo banner on OTP screen).
  String? otpFor(String phoneE164, OtpPurpose purpose) =>
      _store.otpFor(phoneE164, purpose);

  /// Clears all stored OTPs (useful for testing).
  void clear() => _store.clear();

  int? getRemainingSeconds(String phoneE164, OtpPurpose purpose) =>
      _store.getRemainingSeconds(phoneE164, purpose);

  int getResendsLeft(String phoneE164, OtpPurpose purpose) =>
      _store.getResendsLeft(phoneE164, purpose);
}
