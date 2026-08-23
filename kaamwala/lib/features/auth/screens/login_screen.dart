/// Login - phone number entry + OTP verify (Phase 3 C3 wireframes).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  void _sendOtp() {
    final error = _validate(_phoneCtrl.text);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    context.go('/login/otp', extra: '+91$digits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SizedBox.shrink(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            const SizedBox(height: KwSpacing.xxl),
            const Center(child: Text('🔧', style: TextStyle(fontSize: 64))),
            const SizedBox(height: KwSpacing.md),
            Center(
              child: Text(
                'KaamWala',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: KwSpacing.sm),
            const Center(child: Text('Find verified workers near you')),
            const SizedBox(height: KwSpacing.xxl),
            Text('Phone Number',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: '+91',
                    readOnly: true,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: KwSpacing.sm),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    decoration:
                        const InputDecoration(counterText: '', hintText: '98765 43210'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.lg),
            ElevatedButton(onPressed: _sendOtp, child: const Text('Send OTP')),
            const SizedBox(height: KwSpacing.lg),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: KwSpacing.md),
                child: Text('OR', style: Theme.of(context).textTheme.labelSmall),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: KwSpacing.md),
            OutlinedButton(
              onPressed: () => context.go('/login/otp'),
              child: const Text('I am a Worker → (sign up)'),
            ),
          ],
        ),
      ),
    );
  }
}
