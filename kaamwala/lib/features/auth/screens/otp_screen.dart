/// OTP verification screen (Phase 3 C3 lower half).
/// OTP expires in 5 min; max 3 resends/hour (FR-AUTH-01 / NFR-SEC-07).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala/services/analytics_service.dart';

const _resendLimitPerHour = 3;
const _otpExpirySeconds = 5 * 60;

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.phone});
  final String? phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  final _repo = const AuthRepository();
  Timer? _timer;
  int _remaining = _otpExpirySeconds;
  int _resendsLeft = _resendLimitPerHour;
  bool _busy = false;
  String? _error;

  String get _phone => widget.phone ?? '+910000000000';

  @override
  void initState() {
    super.initState();
    _startTimer();
    // FR-AUTH-01: SMS goes out as soon as the screen opens. In demo mode
    // (no backend configured) sendOtp is a no-op success.
    Future<void>.microtask(() async {
      final r = await _repo.sendOtp(_phone);
      if (r is Success<void>) {
        unawaited(AnalyticsService.logEvent('otp_requested'));
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

  Future<void> _resend() async {
    if (_busy || _resendsLeft <= 0 || _remaining > _otpExpirySeconds - 30) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _repo.sendOtp(_phone);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        setState(() => _resendsLeft--);
        _startTimer();
        unawaited(
          AnalyticsService.logEvent('otp_requested', {'via': 'resend'}),
        );
        _showSnack('OTP sent again to $_phone');
      case Error(:final failure):
        _showSnack(failure.message);
    }
  }

  Future<void> _verify() async {
    if (_busy || _ctrl.text.length < 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _repo.verifyOtp(_phone, _ctrl.text.trim());
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // Demo mode (data == null) lands on role selection like before.
        unawaited(AnalyticsService.logEvent('otp_verified'));
        ref.read(authControllerProvider.notifier).authenticatedAs(data);
      case Error(:final failure):
        setState(() => _busy = false);
        setState(() => _error = failure.message);
        _ctrl.clear();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.button),
        border: Border.all(color: const Color(0x291A1A2E)),
      ),
    );
    final canResend =
        !_busy && _resendsLeft > 0 && _remaining <= _otpExpirySeconds - 30;
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Text(
              'Sent to $_phone',
              style: Theme.of(context).textTheme.bodyMedium,
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
                    borderRadius: BorderRadius.circular(KwRadius.button),
                    border: Border.all(color: KwColors.primary, width: 2),
                  ),
                ),
                onCompleted: (_) => _verify(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: KwSpacing.md),
              Text(
                '❌ $_error',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KwColors.red),
              ),
            ],
            const SizedBox(height: KwSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _remaining > 0
                        ? 'Resend in ${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}   ($_resendsLeft tries)'
                        : 'You can resend now ($_resendsLeft tries left)',
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
            ElevatedButton.icon(
              onPressed: _busy ? null : _verify,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: const Text('Verify & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
