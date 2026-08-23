/// Shared UI widgets - empty states, worker cards, status timeline.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/models/worker.dart';

/// NFR-USE-07: every list has a friendly empty state, never blank white.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle});
  final String emoji;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: KwSpacing.md),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: KwSpacing.sm),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: KwColors.muted)),
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
      return CircleAvatar(radius: radius, child: const Icon(Icons.person));
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(url!),
    );
  }
}

/// Worker card - C5/C6 wireframes: photo, name, rating, distance,
/// verified badge, price-from.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, this.onTap});
  final Worker worker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KwRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Row(
            children: [
              WorkerAvatar(url: worker.photoUrl),
              const SizedBox(width: KwSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name.isEmpty ? 'Worker' : worker.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.star, size: 16, color: KwColors.gold),
                        Text(' ${worker.ratingAvg.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${worker.category.labelEn} • ${worker.area.isEmpty ? worker.city : worker.area}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                    const SizedBox(height: KwSpacing.sm),
                    Row(
                      children: [
                        if (worker.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: KwSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: KwColors.green.withValues(alpha: .12),
                              borderRadius:
                                  BorderRadius.circular(KwRadius.chip),
                            ),
                            child: Text(
                              '✅ Verified',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: KwColors.green,
                                      fontWeight: FontWeight.w700),
                            ),
                          )
                        else
                          Text('⚠️ Unverified',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: KwColors.gold)),
                        const Spacer(),
                        Text(worker.priceMin > 0 ? '₹${worker.priceMin}+' : '',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    if (status == BookingStatus.cancelled ||
        status == BookingStatus.declined) {
      return ListTile(
        leading: Text(status.emoji, style: const TextStyle(fontSize: 22)),
        title: Text(status.label),
      );
    }
    final currentIdx =
        _flow.indexOf(status == BookingStatus.pending ? BookingStatus.pending : status);
    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 28,
            leading: _dot(i <= currentIdx),
            title: Text(
              _flow[i].label,
              style: TextStyle(
                fontWeight: i == currentIdx ? FontWeight.w700 : FontWeight.w400,
                color: i <= currentIdx ? KwColors.dark : KwColors.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot(bool done) => done
      ? const Icon(Icons.check_circle, color: KwColors.green, size: 24)
      : const Icon(Icons.circle_outlined, color: KwColors.muted, size: 24);
}
