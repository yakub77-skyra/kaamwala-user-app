import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

/// Rounded tinted square behind an icon. The single replacement for the seven
/// ad-hoc "icon-in-a-well" variants found across the app.
class KwIconWell extends StatelessWidget {
  const KwIconWell({
    required this.icon,
    super.key,
    this.size = 44,
    this.iconSize,
    this.background = KwColors.primaryLight,
    this.foreground = KwColors.primary,
    this.radius,
  });

  final IconData icon;

  /// Outer edge length (square).
  final double size;

  /// Defaults to ~30% of [size] for the signature rounded-square look.
  final double? radius;
  final Color background;
  final Color foreground;

  /// Defaults to 45% of [size].
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius ?? size * .3),
      ),
      child: Icon(icon, size: iconSize ?? size * .45, color: foreground),
    );
  }
}
