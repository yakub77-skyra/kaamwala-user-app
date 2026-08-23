/// Client Home (Phase 3 C5): location header, search bar, 4 categories,
/// top rated workers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.lg),
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: KwColors.primary),
                const SizedBox(width: KwSpacing.xs),
                Text('Kharadi, Pune',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go('/notifications'),
                  icon: const Badge(child: Icon(Icons.notifications_outlined)),
                ),
              ],
            ),
            Text('Namaste, Rohit 👋', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: KwSpacing.lg),
            TextFormField(
              readOnly: true,
              onTap: () => context.go('/search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search "electrician"',
              ),
            ),
            const SizedBox(height: KwSpacing.xl),
            Text('SERVICES',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: KwColors.muted, letterSpacing: 1)),
            const SizedBox(height: KwSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in ServiceCategory.values)
                  _CategoryTile(category: c),
              ],
            ),
            const SizedBox(height: KwSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text('TOP RATED NEAR YOU',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: KwColors.muted, letterSpacing: 1)),
                ),
                GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Text('See all ›',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: KwColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            // Worker cards are rendered by /search list; demo teaser below.
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('Ramesh Kumar   ⭐ 4.8'),
                subtitle: const Text('Electrician • 1.2 km\n✅ Verified   ₹300+'),
                isThreeLine: true,
                trailing:
                    FilledButton(onPressed: () {}, child: const Text('Book')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('Suresh Yadav   ⭐ 4.6'),
                subtitle: const Text('Painter • 3 km • ✅ Verified'),
                trailing:
                    FilledButton(onPressed: () {}, child: const Text('Book')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});
  final ServiceCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(KwRadius.card),
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        context.go('/search');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KwSpacing.xs),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: KwColors.primaryLight,
                borderRadius: BorderRadius.circular(KwRadius.card),
              ),
              child: Icon(category.icon, color: KwColors.primary, size: 30),
            ),
            const SizedBox(height: KwSpacing.xs),
            SizedBox(
              width: 64,
              child: Text(
                category.labelEn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
