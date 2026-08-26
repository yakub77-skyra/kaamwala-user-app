/// Shared UI widgets - empty states, worker cards, status pills & timeline.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/models/worker.dart';

/// NFR-USE-07: every list has a friendly empty state, never blank white.
/// Optionally carries a CTA so users always have a next action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });
  final String emoji;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: KwColors.fill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: KwSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: KwSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KwColors.muted, height: 1.4),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: KwSpacing.xl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, KwSizes.buttonHeight),
                ),
                onPressed: onCta,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({super.key, this.url, this.radius = 24});
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: KwColors.primaryLight,
        child: Icon(
          Icons.person_rounded,
          size: radius * .95,
          color: KwColors.primary.withValues(alpha: .8),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: KwColors.fill,
      backgroundImage: CachedNetworkImageProvider(url!),
    );
  }
}

/// Small colored pill for booking statuses - replaces emoji+text rows.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (:fg, :bg, :icon) = switch (status) {
      BookingStatus.pending => (
        fg: KwColors.gold,
        bg: KwColors.goldLight,
        icon: Icons.schedule_rounded,
      ),
      BookingStatus.accepted => (
        fg: KwColors.blue,
        bg: KwColors.blueLight,
        icon: Icons.check_circle_outline_rounded,
      ),
      BookingStatus.traveling => (
        fg: KwColors.blue,
        bg: KwColors.blueLight,
        icon: Icons.directions_bike_rounded,
      ),
      BookingStatus.arrived => (
        fg: KwColors.blue,
        bg: KwColors.blueLight,
        icon: Icons.location_on_rounded,
      ),
      BookingStatus.inProgress => (
        fg: KwColors.primary,
        bg: KwColors.primaryLight,
        icon: Icons.construction_rounded,
      ),
      BookingStatus.completed => (
        fg: KwColors.green,
        bg: KwColors.greenLight,
        icon: Icons.verified_rounded,
      ),
      BookingStatus.cancelled || BookingStatus.declined => (
        fg: KwColors.red,
        bg: KwColors.redLight,
        icon: Icons.cancel_outlined,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KwRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase letter-spaced section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: KwColors.muted,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(KwRadius.sm),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: KwSizes.minTouchTarget,
                minHeight: KwSizes.minTouchTarget,
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: KwSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: KwColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: KwColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Worker card - photo, name, rating pill, verified badge, area, price-from.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, this.onTap});
  final Worker worker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = worker;
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.md),
          child: Row(
            children: [
              Stack(
                children: [
                  WorkerAvatar(url: w.photoUrl, radius: 26),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: w.isAvailable ? KwColors.green : KwColors.muted,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: KwSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            w.name.isEmpty ? 'Worker' : w.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (w.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: KwColors.green,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${w.category.labelEn}'
                      '${(w.area.isNotEmpty || w.city.isNotEmpty) ? ' • ${w.area.isNotEmpty ? w.area : w.city}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: KwColors.goldLight,
                            borderRadius: BorderRadius.circular(KwRadius.chip),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: KwColors.gold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                w.ratingCount > 0
                                    ? w.ratingAvg.toStringAsFixed(1)
                                    : 'New',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: KwColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (w.priceMin > 0)
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'from '),
                                TextSpan(
                                  text: '₹${_fmt(w.priceMin)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: KwColors.muted),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KwSpacing.sm),
              const Icon(Icons.chevron_right_rounded, color: KwColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(num v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// Status timeline - C10b track detail (Pending -> ... -> Completed).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});
  final BookingStatus status;

  static const _flow = [
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.traveling,
    BookingStatus.arrived,
    BookingStatus.inProgress,
    BookingStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == BookingStatus.cancelled || status == BookingStatus.declined) {
      return Row(
        children: [
          StatusPill(status: status),
          const SizedBox(width: KwSpacing.sm),
          Expanded(
            child: Text(
              status == BookingStatus.cancelled
                  ? 'This booking was cancelled.'
                  : 'The worker declined this job.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ),
        ],
      );
    }
    final currentIdx = _flow.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      if (i > 0)
                        Container(
                          width: 2,
                          height: 10,
                          color: i <= currentIdx
                              ? KwColors.green
                              : KwColors.line,
                        ),
                      _dot(i <= currentIdx, i == currentIdx),
                      if (i < _flow.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: i < currentIdx
                                ? KwColors.green
                                : KwColors.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: KwSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _flow[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == currentIdx
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i <= currentIdx ? KwColors.dark : KwColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(bool done, bool current) {
    if (done && !current) {
      return const Icon(
        Icons.check_circle_rounded,
        color: KwColors.green,
        size: 22,
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? KwColors.green : Colors.white,
        border: Border.all(
          color: done ? KwColors.green : KwColors.muted.withValues(alpha: .4),
          width: current ? 5 : 2,
        ),
      ),
    );
  }
}
