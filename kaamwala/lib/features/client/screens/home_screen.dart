/// Client Home (Phase 3 C5): greeting header, search bar, category grid,
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
    final firstName = (name == null || name.isEmpty)
        ? ''
        : name.split(' ').first;
    final city = (auth.profile?.city ?? '').isEmpty
        ? 'Pune'
        : auth.profile!.city;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(topRatedWorkersProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              KwSpacing.lg,
              KwSpacing.md,
              KwSpacing.lg,
              KwSpacing.xxl,
            ),
            children: [
              // ---------- header ----------
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: WorkerAvatar(
                      url: auth.profile?.photoUrl,
                      radius: 20,
                    ),
                  ),
                  const SizedBox(width: KwSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName.isEmpty
                              ? 'Namaste 👋'
                              : 'Namaste, $firstName 👋',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: KwColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              city,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: KwColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await context.push('/notifications');
                      ref.invalidate(unreadCountProvider);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: KwColors.line),
                      ),
                    ),
                    icon: Badge(
                      isLabelVisible: unread.maybeWhen(
                        data: (n) => n > 0,
                        orElse: () => false,
                      ),
                      backgroundColor: KwColors.red,
                      label: Text('${unread.value ?? 0}'),
                      child: const Icon(Icons.notifications_outlined, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.lg),

              // ---------- search ----------
              TextFormField(
                readOnly: true,
                onTap: () => context.go('/search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: KwColors.muted,
                  ),
                  hintText: 'Search plumbers, electricians…',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KwRadius.button),
                    borderSide: const BorderSide(color: KwColors.line),
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.xl),

              // ---------- categories ----------
              const SectionHeader(title: 'Services'),
              const SizedBox(height: KwSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: KwSpacing.md,
                crossAxisSpacing: KwSpacing.md,
                childAspectRatio: 1.55,
                padding: EdgeInsets.zero,
                children: [
                  for (final c in ServiceCategory.values)
                    _CategoryTile(category: c),
                ],
              ),
              const SizedBox(height: KwSpacing.xl),

              // ---------- top rated ----------
              SectionHeader(
                title: 'Top rated near you',
                actionLabel: 'See all',
                onAction: () => context.go('/search'),
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
                  subtitle: 'Check your connection and try again.',
                  ctaLabel: 'Retry',
                  onCta: () => ref.invalidate(topRatedWorkersProvider),
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
    return Card(
      child: InkWell(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = category;
          context.go('/search');
        },
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: KwColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(category.icon, color: KwColors.primary, size: 24),
              ),
              const SizedBox(width: KwSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.labelEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.labelHi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: KwColors.muted),
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
