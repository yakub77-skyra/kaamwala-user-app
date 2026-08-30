/// Shown when someone opens the sibling binary with the wrong account type
/// (customer logged into Partner, or worker logged into customer KaamWala).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';

class WrongAppScreen extends ConsumerWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    final isPartner = flavor == AppFlavor.partner;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KwColors.primaryLight,
                  borderRadius: BorderRadius.circular(KwRadius.lg),
                ),
                child: Icon(
                  isPartner
                      ? Icons.home_work_outlined
                      : Icons.construction_rounded,
                  size: 44,
                  color: KwColors.primary,
                ),
              ),
              const SizedBox(height: KwSpacing.xl),
              Text(
                isPartner
                    ? 'This is the Work Partner app'
                    : 'KaamWala is for customers',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.md),
              Text(
                isPartner
                    ? 'This number is registered as a customer. Download the '
                          'KaamWala app to book verified workers near you.'
                    : 'This number is registered as a Work Partner. Download '
                          'the KaamWala Partner app to receive jobs and manage '
                          'your work.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: KwColors.muted, height: 1.4),
              ),
              const SizedBox(height: KwSpacing.xxl),
              FilledButton.icon(
                onPressed: () {
                  ref.read(onboardingControllerProvider.notifier).reset();
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Use a different number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
