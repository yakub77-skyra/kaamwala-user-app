import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

enum KwButtonVariant { primary, secondary, ghost, destructive }

/// Full-width 52dp action button with loading state. Use everywhere a CTA
/// appears; do not hand-style ElevatedButton/OutlinedButton in screens.
class KwButton extends StatelessWidget {
  const KwButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = KwButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final KwButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    final Widget child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: KwSpacing.sm),
              ],
              Text(label),
            ],
          );

    final ButtonStyleButton base = switch (variant) {
      KwButtonVariant.primary || KwButtonVariant.destructive => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: variant == KwButtonVariant.destructive
            ? ElevatedButton.styleFrom(backgroundColor: KwColors.red)
            : null,
        child: child,
      ),
      KwButtonVariant.secondary => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
      KwButtonVariant.ghost => TextButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: base) : base;
  }
}
