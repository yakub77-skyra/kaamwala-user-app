/// Onboarding - 3 skippable slides with brand illustrations (UI 2.0).
/// Slide copy is flavor-aware: customers see booking benefits, partners see
/// earning benefits.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();

  static const _customerSlides = [
    (
      illustration: KwIllustration.search,
      title: 'Find verified workers',
      body:
          'Aadhaar-checked plumbers, electricians, painters & carpenters '
          'near you - with real ratings.',
    ),
    (
      illustration: KwIllustration.bookings,
      title: 'Book in 3 taps',
      body:
          'Pick a worker, describe the job, choose a time slot. '
          'No long forms, no phone tag.',
    ),
    (
      illustration: KwIllustration.success,
      title: 'Pay safely with UPI',
      body:
          'GPay, PhonePe, Paytm via Razorpay. Cancel before acceptance '
          'and the booking fee refunds automatically.',
    ),
  ];

  static const _partnerSlides = [
    (
      illustration: KwIllustration.search,
      title: 'Get work near you',
      body:
          'Real jobs from real customers - plumbing, electrical, painting, '
          'carpentry. Right in your area.',
    ),
    (
      illustration: KwIllustration.bookings,
      title: 'Accept jobs in one tap',
      body:
          'New job requests reach you instantly. Accept, travel, complete - '
          'all tracked step by step.',
    ),
    (
      illustration: KwIllustration.success,
      title: 'Keep more of every job',
      body:
          'You keep 90% of each completed job. Money goes straight to your '
          'bank account via UPI.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<({KwIllustration illustration, String title, String body})> _slidesFor(
    AppFlavor flavor,
  ) => flavor == AppFlavor.partner ? _partnerSlides : _customerSlides;

  void _next() {
    if (!_controller.hasClients) return;
    if (_controller.page!.round() >=
        _slidesFor(ref.read(flavorProvider)).length - 1) {
      context.go('/login');
    } else {
      _controller.nextPage(duration: KwMotion.base, curve: KwMotion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slidesFor(ref.watch(flavorProvider));
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              itemBuilder: (context, i) {
                final s = slides[i];
                return Padding(
                  padding: const EdgeInsets.all(KwSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/illustrations/${switch (s.illustration) {
                          KwIllustration.search => 'search',
                          KwIllustration.bookings => 'bookings',
                          _ => 'success',
                        }}.svg',
                        width: 220,
                      ),
                      const SizedBox(height: KwSpacing.xl),
                      Text(
                        s.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: KwSpacing.md),
                      Text(
                        s.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: KwColors.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KwSpacing.xl,
              0,
              KwSpacing.xl,
              KwSpacing.xxl,
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: KwMotion.fast,
                          curve: KwMotion.emphasized,
                          width:
                              (_controller.hasClients &&
                                  _controller.page!.round() == i)
                              ? 22
                              : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(KwRadius.pill),
                            color:
                                (_controller.hasClients &&
                                    _controller.page!.round() == i)
                                ? KwColors.primary
                                : KwColors.fill,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: KwSpacing.lg),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final last =
                        _controller.hasClients &&
                        _controller.page!.round() >= slides.length - 1;
                    return KwButton(
                      label: last ? 'Get started' : 'Next',
                      onPressed: _next,
                      icon: last ? Icons.arrow_forward_rounded : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
