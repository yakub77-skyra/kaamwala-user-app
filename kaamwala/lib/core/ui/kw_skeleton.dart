import 'package:flutter/material.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

/// Pulsing placeholder block - the loading language for all list content.
class KwSkeleton extends StatefulWidget {
  const KwSkeleton({
    this.width = double.infinity,
    this.height = 14,
    this.radius = KwRadius.sm,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<KwSkeleton> createState() => _KwSkeletonState();
}

class _KwSkeletonState extends State<KwSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: .45,
        end: 1,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: KwColors.fill,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton row matching [WorkerCard] geometry.
class KwSkeletonList extends StatelessWidget {
  const KwSkeletonList({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: KwSpacing.md),
          Container(
            padding: const EdgeInsets.all(KwSpacing.lg),
            decoration: BoxDecoration(
              color: KwColors.surface,
              borderRadius: BorderRadius.circular(KwRadius.lg),
              border: Border.all(color: KwColors.line),
            ),
            child: Row(
              children: [
                const KwSkeleton(width: 56, height: 56, radius: KwRadius.md),
                const SizedBox(width: KwSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KwSkeleton(
                        width: 140,
                        height: 15,
                        radius: KwRadius.sm,
                      ),
                      const SizedBox(height: KwSpacing.sm),
                      const KwSkeleton(width: 90, height: 12),
                      const SizedBox(height: KwSpacing.sm),
                      const KwSkeleton(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
