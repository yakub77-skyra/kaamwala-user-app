/// Cancellation and Refund Policy screen.
/// 
/// Trust UI (Phase 1 Section 6): Clear policy explanation builds user trust.
library;

import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

class CancellationPolicyScreen extends StatelessWidget {
  const CancellationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancellation & Refund Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          _PolicySection(
            title: 'Booking Cancellation',
            icon: Icons.cancel_outlined,
            content: [
              'You can cancel a booking anytime before the worker starts the job.',
              'If you cancel after the worker has arrived, a cancellation fee may apply.',
              'Cancellations due to worker unavailability are fully refunded.',
            ],
          ),
          const SizedBox(height: KwSpacing.lg),
          _PolicySection(
            title: 'Refund Process',
            icon: Icons.refund_outlined,
            content: [
              'Refunds are processed automatically to your original payment method.',
              'Refunds typically appear within 3-5 business days.',
              'For UPI payments, refunds are instant in most cases.',
            ],
          ),
          const SizedBox(height: KwSpacing.lg),
          _PolicySection(
            title: 'Service Quality Issues',
            icon: Icons.rate_review_outlined,
            content: [
              'If you\'re not satisfied with the service, report it within 24 hours.',
              'We investigate all quality complaints within 48 hours.',
              'Valid complaints result in full refund or free re-service.',
            ],
          ),
          const SizedBox(height: KwSpacing.lg),
          _PolicySection(
            title: 'No-Show Policy',
            icon: Icons.person_off_outlined,
            content: [
              'If the worker doesn\'t arrive within 30 minutes of scheduled time, you get a full refund.',
              'Report no-shows through the app for immediate resolution.',
              'Repeated no-shows result in worker removal from platform.',
            ],
          ),
          const SizedBox(height: KwSpacing.xl),
          
          // Contact info
          Container(
            padding: const EdgeInsets.all(KwSpacing.lg),
            decoration: BoxDecoration(
              color: KwColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(KwRadius.md),
              border: Border.all(color: KwColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: KwColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: KwSpacing.sm),
                    Text(
                      'Need Help?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: KwColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: KwSpacing.sm),
                Text(
                  'Contact our support team for any questions about cancellations or refunds.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: KwSpacing.sm),
                Text(
                  'support@kaamwala.com',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: KwColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final List<String> content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KwSpacing.lg),
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.md),
        border: Border.all(color: KwColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KwColors.muted, size: 22),
              const SizedBox(width: KwSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: KwSpacing.md),
          ...content.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: KwSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: KwColors.green,
                    ),
                    const SizedBox(width: KwSpacing.sm),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
