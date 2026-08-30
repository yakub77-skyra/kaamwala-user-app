/// OTP verification screen.
/// Uses the SMS gateway abstraction; in mock/demo mode the OTP is surfaced
/// via a dev-only banner and the console.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:kaamwala/core/services/phone/phone_utils.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_button.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/sms/mock_sms_gateway.dart';
import 'package:kaamwala/core/services/sms/sms_providers.dart';
import 'package:kaamwala/core/services/sms/sms_gateway.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';
import 'package:kaamwala/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala/models/user_profile.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

const _otpExpirySeconds = 5 * 60;

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _remaining = _otpExpirySeconds;
  bool _busy = false;
  String? _error;

  String get _phone =>
      ref.read(onboardingControllerProvider).phoneE164 ?? '+910000000000';

  bool get _isWorker => ref.read(onboardingControllerProvider).asWorker;

  OtpPurpose get _purpose =>
      _isWorker ? OtpPurpose.registration : OtpPurpose.login;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // In demo/mock mode the OTP was already stored by the phone screen - show
    // it in a banner immediately (no re-send, so the resend cooldown is not
    // burned and the countdown starts clean).
    Future<void>.microtask(() {
      final gateway = ref.read(smsGatewayProvider);
      if (gateway is MockSmsGateway) {
        final otp = gateway.otpFor(_phone, _purpose);
        if (otp != null) _showDemoBanner(otp);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _otpExpirySeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  /// Resends the OTP through the gateway (real gateways also re-issue via
  /// Supabase Auth). The countdown restarts on success.
  Future<void> _sendCode() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final gateway = ref.read(smsGatewayProvider);
    final result = await gateway.resendOtp(
      phoneE164: _phone,
      purpose: _purpose,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      _startTimer();
      unawaited(AnalyticsService.logEvent('otp_requested', {'via': 'resend'}));
      if (result.otpDevOnly != null) {
        _showDemoBanner(result.otpDevOnly!);
      }
    } else {
      _showSnack(result.message);
      if (result.resendAfterSeconds > 0) {
        setState(() => _remaining = result.resendAfterSeconds);
      }
    }
  }

  Future<void> _resend() async {
    if (_busy || _remaining > 0) return;
    await _sendCode();
  }

  Future<void> _verify() async {
    if (_busy || _ctrl.text.length < 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final gateway = ref.read(smsGatewayProvider);
    final repo = const AuthRepository();
    UserProfile? profile;
    bool verified = false;

    if (gateway.isDemoMode) {
      // Mock provider: verify the code we generated in-app. No Supabase
      // session is created - the app keeps running in demo mode.
      final r = await gateway.verifyOtp(
        phoneE164: _phone,
        otp: _ctrl.text.trim(),
        purpose: _purpose,
      );
      if (!mounted) return;
      if (!r.success) {
        setState(() {
          _busy = false;
          _error = r.message;
        });
        _ctrl.clear();
        return;
      }
      verified = true;
    } else if (SupabaseService.isReady) {
      // Real gateway: verification happens server-side via Supabase Auth.
      final r = await repo.verifyOtp(_phone, _ctrl.text.trim());
      switch (r) {
        case Success(:final data):
          profile = data;
          verified = true;
        case Error(:final failure):
          setState(() {
            _busy = false;
            _error = failure.message;
          });
          _ctrl.clear();
          return;
      }
    }

    if (!mounted || !verified) return;
    unawaited(AnalyticsService.logEvent('otp_verified'));

    final onboarding = ref.read(onboardingControllerProvider);
    if (!gateway.isDemoMode && SupabaseService.isReady) {
      ref.read(authControllerProvider.notifier).authenticatedAs(profile);
    } else if (onboarding.asWorker) {
      // Mock worker: create an in-memory worker profile to reach registration.
      ref
          .read(authControllerProvider.notifier)
          .authenticatedAs(
            UserProfile(id: 'mock-user', phone: _phone, role: UserRole.worker),
          );
    } else {
      ref
          .read(authControllerProvider.notifier)
          .authenticatedAs(UserProfile(id: 'mock-user', phone: _phone));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDemoBanner(String otp) {
    if (!mounted) return;
    final demo = ref.read(smsGatewayProvider).isDemoMode;
    if (!demo) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('🔧 DEMO MODE — your OTP is $otp'),
          backgroundColor: KwColors.warning,
          duration: const Duration(seconds: 15),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: Theme.of(context).textTheme.headlineSmall,
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.md),
        border: Border.all(color: KwColors.line),
      ),
    );
    final demo = ref.watch(smsGatewayProvider).isDemoMode;
    final canResend = !_busy && _remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => context.go('/login/phone'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            if (demo) ...[
              Container(
                padding: const EdgeInsets.all(KwSpacing.md),
                decoration: BoxDecoration(
                  color: KwColors.warningLight,
                  borderRadius: BorderRadius.circular(KwRadius.md),
                  border: Border.all(
                    color: KwColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bug_report_rounded,
                      color: KwColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: KwSpacing.sm),
                    Expanded(
                      child: Text(
                        'Demo mode — OTP appears in a banner below.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KwColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KwSpacing.md),
            ],
            Text(
              'Enter the 6-digit code',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: KwSpacing.sm),
            Row(
              children: [
                Text(
                  'OTP sent to ${maskPhoneE164(_phone)}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: KwColors.muted),
                ),
                const SizedBox(width: KwSpacing.sm),
                InkWell(
                  onTap: _busy ? null : () => context.go('/login/phone'),
                  borderRadius: BorderRadius.circular(KwRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Change number',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: KwColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.xl),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Pinput(
                length: 6,
                controller: _ctrl,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: KwColors.surface,
                    borderRadius: BorderRadius.circular(KwRadius.md),
                    border: Border.all(color: KwColors.primary, width: 2),
                  ),
                ),
                onCompleted: (_) => _verify(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: KwSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: KwColors.red,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.red),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: KwSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _remaining > 0
                        ? 'Didn\'t get it? Resend in ${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}'
                        : 'Didn\'t get it? You can resend now.',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: KwColors.muted),
                  ),
                ),
                TextButton(
                  onPressed: canResend ? _resend : null,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            KwButton(
              label: 'Verify & Continue',
              onPressed: _busy ? null : _verify,
              icon: Icons.verified_outlined,
              loading: _busy,
            ),
          ],
        ),
      ),
    );
  }
}
