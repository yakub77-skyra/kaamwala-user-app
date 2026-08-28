/// Reusable ElevatedButton with loading state.
/// 
/// Features:
/// - Shows spinner when isLoading is true
/// - Disables itself during loading
/// - Consistent styling across the app
library;

import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

class KwLoadingButton extends StatelessWidget {
  const KwLoadingButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.variant = _ButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final _ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    
    final Widget child = isLoading
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
      _ButtonVariant.primary => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
      _ButtonVariant.secondary => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
      _ButtonVariant.text => TextButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
    };

    return fullWidth
        ? SizedBox(width: double.infinity, child: base)
        : base;
  }
}

enum _ButtonVariant { primary, secondary, text }
