/// Login - phone number entry (UI 2.0: trust-first, single field).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final digits = _phoneCtrl.text.trim();
    context.go('/login/otp', extra: '+91$digits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KwSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: KwSpacing.xl),
                    // Brand mark
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: KwColors.brandGradient,
                          ),
                          borderRadius: BorderRadius.circular(KwRadius.lg),
                          boxShadow: KwShadows.s3,
                        ),
                        child: const Icon(
                          Icons.handyman_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: KwSpacing.lg),
                    Text(
                      'KaamWala',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: KwSpacing.sm),
                    Text(
                      'Verified workers for every home job.\n'
                      'Booked in seconds, paid by UPI.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: KwColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: KwSpacing.xxl),

                    // Trust chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrustChip(
                          icon: Icons.verified_rounded,
                          label: 'Aadhaar-verified',
                        ),
                        const SizedBox(width: KwSpacing.sm),
                        _TrustChip(
                          icon: Icons.lock_rounded,
                          label: 'Secure UPI',
                        ),
                        const SizedBox(width: KwSpacing.sm),
                        _TrustChip(
                          icon: Icons.undo_rounded,
                          label: 'Auto-refund',
                        ),
                      ],
                    ),
                    const SizedBox(height: KwSpacing.xxl),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: const InputDecoration(
                        counterText: '',
                        prefixText: '+91  ',
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KwColors.ink,
                        ),
                        hintText: '98765 43210',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) == 10
                          ? null
                          : 'Enter a valid 10-digit mobile number',
                      onFieldSubmitted: (_) => _sendOtp(),
                    ),
                    const SizedBox(height: KwSpacing.lg),
                    KwButton(
                      label: 'Send OTP',
                      onPressed: _sendOtp,
                      icon: Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(height: KwSpacing.md),
                    KwButton(
                      label: 'I want to work - sign up as worker',
                      variant: KwButtonVariant.secondary,
                      onPressed: () => context.go('/login/otp'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.pill),
        border: Border.all(color: KwColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KwColors.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KwColors.muted, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
