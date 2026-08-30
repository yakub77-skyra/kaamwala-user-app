/// Phone number entry screen - comes after role selection.
/// User enters phone number, we send OTP, then navigate to OTP screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/phone/phone_utils.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';
import 'package:kaamwala/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala/core/services/sms/sms_providers.dart';
import 'package:kaamwala/core/services/sms/sms_gateway.dart';
import 'package:kaamwala/services/supabase_service.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final normalizedPhone = normalizePhoneE164(_phoneCtrl.text.trim());

    // Get the selected role from the onboarding flow
    final onboarding = ref.read(onboardingControllerProvider);
    final isWorker = onboarding.asWorker;

    // Determine OTP purpose based on role
    final purpose = isWorker ? OtpPurpose.registration : OtpPurpose.login;

    final smsGateway = ref.read(smsGatewayProvider);
    final result = await smsGateway.sendOtp(
      phoneE164: normalizedPhone,
      purpose: purpose,
    );

    if (!mounted) return;

    // Real delivery only when a real gateway is active; the mock gateway
    // handles both sides (send + verify) entirely in-app.
    if (result.success && !smsGateway.isDemoMode && SupabaseService.isReady) {
      final real = await const AuthRepository().sendOtp(normalizedPhone);
      if (!mounted) return;
      if (real is Error) {
        setState(() => _busy = false);
        setState(() => _error = real.failure.message);
        _showSnack(real.failure.message);
        return;
      }
    }

    setState(() => _busy = false);

    if (result.success) {
      if (smsGateway.isDemoMode && result.otpDevOnly != null) {
        _showDemoOtp(normalizedPhone, result.otpDevOnly!);
      }
      // Persist the phone + transition to OTP stage for the shared state.
      ref.read(onboardingControllerProvider.notifier).setPhone(normalizedPhone);
      ref
          .read(authControllerProvider.notifier)
          .startOtpVerification(normalizedPhone);
      if (mounted) {
        context.go('/login/otp');
      }
    } else {
      setState(() => _error = result.message);
      _showSnack(result.message);
    }
  }

  void _showDemoOtp(String phone, String otp) {
    if (!mounted) return;
    final demo = ref.read(smsGatewayProvider).isDemoMode;
    if (!demo) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '🔧 DEMO MODE — OTP for ${maskPhoneE164(phone)} is $otp',
          ),
          backgroundColor: KwColors.warning,
          duration: const Duration(seconds: 15),
        ),
      );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingControllerProvider);
    final isWorker = onboarding.asWorker;

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
                      isWorker
                          ? 'Create your worker profile to get jobs'
                          : 'Book verified workers for home services',
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

                    Text(
                      'Enter your mobile number',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: KwSpacing.xs),
                    Text(
                      'We\'ll send a free OTP via SMS. No spam calls.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: KwColors.muted),
                    ),
                    const SizedBox(height: KwSpacing.md),

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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your mobile number';
                        }
                        if (!isValidIndianMobile(v.trim())) {
                          return 'Enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _sendOtp(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: KwSpacing.sm),
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
                    KwButton(
                      label: 'Send OTP',
                      onPressed: _busy ? null : _sendOtp,
                      icon: Icons.arrow_forward_rounded,
                      loading: _busy,
                    ),
                    const SizedBox(height: KwSpacing.md),
                    TextButton(
                      onPressed: () => context.go('/role'),
                      child: const Text('← Back to role selection'),
                    ),
                    const SizedBox(height: KwSpacing.lg),
                    Text(
                      'Your number is used only for login and booking updates.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: KwColors.muted),
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
