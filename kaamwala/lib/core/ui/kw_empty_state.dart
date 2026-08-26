import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

/// Brand illustration set - replaces emoji-as-artwork everywhere.
enum KwIllustration { search, bookings, jobs, review, success, offline }

extension _KwIllustrationAsset on KwIllustration {
  String get asset => switch (this) {
    KwIllustration.search => 'search',
    KwIllustration.bookings => 'bookings',
    KwIllustration.jobs => 'jobs',
    KwIllustration.review => 'review',
    KwIllustration.success => 'success',
    KwIllustration.offline => 'offline',
  };
}

/// Empty / attention state with brand illustration instead of emoji.
class KwEmptyState extends StatelessWidget {
  const KwEmptyState({
    required this.illustration,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final KwIllustration illustration;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.xxl,
          vertical: KwSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/illustrations/${illustration.asset}.svg',
              width: 168,
              semanticsLabel: title,
            ),
            const SizedBox(height: KwSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: KwSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KwColors.muted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: KwSpacing.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
