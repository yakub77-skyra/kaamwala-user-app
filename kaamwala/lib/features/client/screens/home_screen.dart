/// Client Home (Phase 3 C5): profile greeting, search bar, 4 categories,
/// top-rated workers - all live from Supabase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final topRated = ref.watch(topRatedWorkersProvider);
    final unread = ref.watch(unreadCountProvider);

    final name = auth.profile?.name;
    final city = (auth.profile?.city ?? '').isEmpty
        ? 'your city'
        : auth.profile!.city;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(topRatedWorkersProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: KwColors.primary,
                  ),
                  const SizedBox(width: KwSpacing.xs),
                  Text(
                    city,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await context.push('/notifications');
                      ref.invalidate(unreadCountProvider);
                      ref.invalidate(topRatedWorkersProvider);
                    },
                    icon: Badge(
                      isLabelVisible: unread.maybeWhen(
                        data: (n) => n > 0,
                        orElse: () => false,
                      ),
                      label: Text('${unread.value ?? 0}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ],
              ),
              Text(
                name == null || name.isEmpty
                    ? 'Namaste 👋'
                    : 'Namaste, $name 👋',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
              Text(
                'SERVICES',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted, letterSpacing: 1),
              ),
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
                    child: Text(
                      'TOP RATED NEAR YOU',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: KwColors.muted, letterSpacing: 1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Text(
                      'See all ›',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: KwColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.md),
              topRated.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(KwSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => EmptyState(
                  emoji: '⚠️',
                  title: 'Could not load workers',
                  subtitle: 'Pull down to retry.',
                ),
                data: (workers) {
                  if (workers.isEmpty) {
                    return const EmptyState(
                      emoji: '🛠️',
                      title: 'No workers online yet',
                      subtitle: 'Verified workers appear here as soon as they go available.',
                    );
                  }
                  return Column(
                    children: [
                      for (final w in workers)
                        WorkerCard(
                          worker: w,
                          onTap: () => context.push('/worker/${w.id}'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(KwSpacing.sm),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: KwColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(category.icon, color: KwColors.primary, size: 28),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              category.labelEn,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
