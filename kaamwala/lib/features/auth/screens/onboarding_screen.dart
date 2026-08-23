/// Onboarding - 3 skippable slides (Phase 3 C2 wireframe).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();

  static const _slides = [
    (icon: Icons.verified_user, title: 'Find Verified Workers', body: 'Aadhar-checked plumbers & electricians near you.', emoji: '🔍'),
    (icon: Icons.bolt, title: 'Book in 3 Taps', body: 'Pick a worker, describe the job, done. No long forms.', emoji: '⚡'),
    (icon: Icons.currency_rupee, title: 'Pay Safely with UPI', body: 'GPay, PhonePe, Paytm - pay only when booked.', emoji: '💰'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (!_controller.hasClients) return;
    if (_controller.page!.round() >= _slides.length - 1) {
      context.go('/login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              itemCount: _slides.length,
              itemBuilder: (context, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.all(KwSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: KwSpacing.xl),
                      Text(
                        s.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: KwSpacing.md),
                      Text(
                        s.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: KwColors.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(KwSpacing.xl, 0, KwSpacing.xl, KwSpacing.xxl),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_controller.hasClients &&
                                    _controller.page!.round() == i)
                                ? KwColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: KwSpacing.lg),
                ElevatedButton(onPressed: _next, child: const Text('Next')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
