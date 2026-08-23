/// OTP verification screen (Phase 3 C3 lower half).
/// OTP expires in 5 min; max 3 resends/hour (FR-AUTH-01 / NFR-SEC-07).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

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
  Timer? _timer;
  int _remaining = _otpExpirySeconds;
  final int _resendsLeft = _resendLimitPerHour;
  bool _busy = false;

  String get _phone =>
      widget.phone ?? '+910000000000';

  @override
  void initState() {
    super.initState();
    _startTimer();
    // TODO(dev): trigger AuthRepository.sendOtp(_phone) once Supabase is configured.
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

  Future<void> _verify() async {
    if (_busy || _ctrl.text.length < 6) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _busy = false);
    context.go('/role');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Text('Sent to $_phone', style: Theme.of(context).textTheme.bodyMedium),
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
            const SizedBox(height: KwSpacing.lg),
            Text(
              _remaining > 0
                  ? 'Resend in ${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}   ($_resendsLeft tries)'
                  : 'You can resend now ($_resendsLeft tries left)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: KwColors.muted),
            ),
            const SizedBox(height: KwSpacing.md),
            ElevatedButton.icon(
              onPressed: _busy ? null : _verify,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified_outlined),
              label: const Text('Verify & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
