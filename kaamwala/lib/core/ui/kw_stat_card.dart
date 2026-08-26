import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_icon_well.dart';

/// Dashboard metric tile (worker home / earnings). Icon well + big number +
/// label, on a raised white card.
class KwStatCard extends StatelessWidget {
  const KwStatCard({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
    this.tint = KwColors.primaryLight,
    this.foreground = KwColors.primary,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KwSpacing.lg),
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.lg),
        border: Border.all(color: KwColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          KwIconWell(
            icon: icon,
            size: 40,
            background: tint,
            foreground: foreground,
          ),
          const SizedBox(height: KwSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: KwColors.muted),
          ),
        ],
      ),
    );
  }
}
