/// Worker profile (Phase 3 C7): photo, rating, verified badge, price range,
/// portfolio strip, about, skills, reviews + sticky Book Now / Call.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_empty_state.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/models/worker.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key, required this.workerId});
  final String workerId;

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> {
  late Future<(Worker?, List<Review>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Worker?, List<Review>)> _load() async {
    final result = await ref.read(workersRepoProvider).byId(widget.workerId);
    final worker = switch (result) {
      Success(:final data) => data,
      _ => null,
    };
    final reviewsRes = await ref
        .read(reviewsRepoProvider)
        .forWorker(widget.workerId);
    final reviews = switch (reviewsRes) {
      Success(:final data) => data,
      _ => const <Review>[],
    };
    return (worker, reviews);
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(Worker?, List<Review>)>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final w = snap.data!.$1;
          final reviews = snap.data!.$2;
          if (w == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const KwEmptyState(
                illustration: KwIllustration.search,
                title: 'Worker not found',
                subtitle: 'This profile may have been removed.',
              ),
            );
          }
          return Scaffold(
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KwSpacing.lg,
                  KwSpacing.sm,
                  KwSpacing.lg,
                  KwSpacing.lg,
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: w.phone == null ? null : () => _call(w.phone),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(56, KwSizes.buttonHeight),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.call_rounded, size: 20),
                    ),
                    const SizedBox(width: KwSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 19,
                        ),
                        label: const Text('Book Now'),
                        onPressed: () =>
                            context.push('/book/${widget.workerId}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: CustomScrollView(
              slivers: [
                // ---------- hero header ----------
                SliverAppBar(
                  expandedHeight: 210,
                  pinned: true,
                  backgroundColor: KwColors.primaryLight,
                  foregroundColor: KwColors.dark,
                  title: Text(
                    w.name.isEmpty ? 'Worker' : w.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KwColors.surface,
                              border: Border.all(
                                color: KwColors.surface,
                                width: 3,
                              ),
                              boxShadow: KwShadows.s2,
                            ),
                            child: WorkerAvatar(url: w.photoUrl, radius: 44),
                          ),
                          const SizedBox(height: KwSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${w.category.labelEn} • ${w.area.isNotEmpty ? w.area : w.city}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: KwColors.muted),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 9,
                                color: w.isAvailable
                                    ? KwColors.green
                                    : KwColors.muted,
                              ),
                              Text(
                                w.isAvailable ? ' Available' : ' Busy',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: w.isAvailable
                                          ? KwColors.green
                                          : KwColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatChip(
                                icon: Icons.star_rounded,
                                value: w.ratingCount > 0
                                    ? w.ratingAvg.toStringAsFixed(1)
                                    : 'New',
                                label: w.ratingCount > 0
                                    ? '${w.ratingCount} reviews'
                                    : 'No reviews',
                              ),
                              const SizedBox(width: KwSpacing.sm),
                              _StatChip(
                                icon: Icons.payments_outlined,
                                value:
                                    '₹${w.priceMin.toStringAsFixed(0)}–${w.priceMax.toStringAsFixed(0)}',
                                label: 'price range',
                              ),
                              const SizedBox(width: KwSpacing.sm),
                              _StatChip(
                                icon: Icons.verified_rounded,
                                value: w.isVerified ? 'Verified' : 'Pending',
                                label: 'Aadhar check',
                                tint: w.isVerified
                                    ? KwColors.green
                                    : KwColors.gold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ---------- work photos ----------
                      if (w.portfolioUrls.isNotEmpty) ...[
                        SectionHeader(title: 'Work photos'),
                        const SizedBox(height: KwSpacing.sm),
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: w.portfolioUrls.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: KwSpacing.sm),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () =>
                                  _showPhoto(context, w.portfolioUrls[i]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  KwRadius.button,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: w.portfolioUrls[i],
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      ColoredBox(color: KwColors.fill),
                                  errorWidget: (_, _, _) => ColoredBox(
                                    color: KwColors.fill,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: KwColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: KwSpacing.xl),
                      ],

                      // ---------- about ----------
                      SectionHeader(title: 'About'),
                      const SizedBox(height: KwSpacing.sm),
                      Text(
                        w.bio.isEmpty ? 'Experienced professional.' : w.bio,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.45),
                      ),

                      // ---------- skills ----------
                      if (w.skills.isNotEmpty) ...[
                        const SizedBox(height: KwSpacing.xl),
                        SectionHeader(title: 'Skills'),
                        const SizedBox(height: KwSpacing.sm),
                        Wrap(
                          spacing: KwSpacing.sm,
                          runSpacing: KwSpacing.sm,
                          children: [
                            for (final s in w.skills)
                              Chip(
                                label: Text(s),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],

                      // ---------- reviews ----------
                      const SizedBox(height: KwSpacing.xl),
                      SectionHeader(title: 'Reviews (${w.ratingCount})'),
                      const SizedBox(height: KwSpacing.sm),
                      if (reviews.isEmpty)
                        Text(
                          'No reviews yet — be the first to book and rate.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: KwColors.muted),
                        )
                      else
                        for (final r in reviews)
                          Card(
                            margin: const EdgeInsets.only(bottom: KwSpacing.md),
                            child: Padding(
                              padding: const EdgeInsets.all(KwSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      for (var i = 0; i < 5; i++)
                                        Icon(
                                          i < r.rating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 16,
                                          color: KwColors.gold,
                                        ),
                                      const Spacer(),
                                      Text(
                                        r.tags.join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: KwColors.muted),
                                      ),
                                    ],
                                  ),
                                  if (r.text.isNotEmpty) ...[
                                    const SizedBox(height: KwSpacing.sm),
                                    Text(
                                      '"${r.text}"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                      Text(
                        'Booking fee ₹${AppConstants.bookingFeeRupees} applies at checkout.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KwColors.muted),
                      ),
                      const SizedBox(height: KwSpacing.xl),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: .92),
            body: Center(
              child: InteractiveViewer(
                maxScale: 4,
                child: CachedNetworkImage(imageUrl: url),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.tint = KwColors.dark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: KwColors.surface,
        borderRadius: BorderRadius.circular(KwRadius.chip),
        boxShadow: KwShadows.s1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: tint == KwColors.dark ? KwColors.gold : tint,
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: Theme.of(context).textTheme.labelMedium),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: KwColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
