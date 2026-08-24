/// Worker profile (Phase 3 C7): photo, rating, verified badge, price range,
/// portfolio strip, about, skills, reviews + sticky Book Now.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/models/worker.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key, required this.workerId});
  final String workerId;

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> {
  late Future<Worker?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Worker?> _load() async {
    final result = await ref.read(workersRepoProvider).byId(widget.workerId);
    return switch (result) {
      Success(:final data) => data,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book Now'),
            onPressed: () => context.go('/book/${widget.workerId}'),
          ),
        ),
      ),
      body: FutureBuilder<Worker?>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final w = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  child: const Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: KwSpacing.md),
              Center(
                child: Text(
                  w.name.isEmpty ? 'Worker' : w.name,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: KwSpacing.xs),
              Center(
                child: Text(
                  '${w.category.labelEn} • ${w.city}   ⭐ ${w.ratingAvg.toStringAsFixed(1)} (${w.ratingCount})',
                ),
              ),
              const SizedBox(height: KwSpacing.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (w.isVerified ? KwColors.green : KwColors.gold)
                        .withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(KwRadius.chip),
                  ),
                  child: Text(
                    w.isVerified ? '✅ Aadhar Verified' : '⚠️ Unverified',
                    style: TextStyle(
                      color: w.isVerified ? KwColors.green : KwColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Divider(height: KwSpacing.xxl),
              Row(
                children: [
                  Text(
                    '₹${w.priceMin}–₹${w.priceMax}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: w.isAvailable ? KwColors.green : KwColors.muted,
                  ),
                  Text(w.isAvailable ? ' Available' : ' Busy'),
                ],
              ),
              const Divider(),
              if (w.portfolioUrls.isNotEmpty) ...[
                Text(
                  'WORK PHOTOS',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: KwColors.muted, letterSpacing: 1),
                ),
                const SizedBox(height: KwSpacing.sm),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: w.portfolioUrls.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: KwSpacing.sm),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(KwRadius.button),
                      child: ColoredBox(
                        color: KwColors.primaryLight,
                        child: const SizedBox(width: 84, height: 84),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: KwSpacing.lg),
              ],
              Text(
                'ABOUT',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted, letterSpacing: 1),
              ),
              const SizedBox(height: KwSpacing.xs),
              Text(w.bio.isEmpty ? 'Experienced professional.' : w.bio),
              const SizedBox(height: KwSpacing.lg),
              if (w.skills.isNotEmpty) ...[
                Text(
                  'SKILLS',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: KwColors.muted, letterSpacing: 1),
                ),
                const SizedBox(height: KwSpacing.sm),
                Wrap(
                  spacing: KwSpacing.sm,
                  runSpacing: KwSpacing.sm,
                  children: [for (final s in w.skills) Chip(label: Text(s))],
                ),
              ],
              const SizedBox(height: KwSpacing.lg),
              Text(
                'REVIEWS (${w.ratingCount})',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted, letterSpacing: 1),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text('⭐⭐⭐⭐⭐'),
                title: Text('"Very neat work."'),
              ),
              Text(
                'Booking fee ₹${AppConstants.bookingFeeRupees} applies at checkout.',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: KwColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}
