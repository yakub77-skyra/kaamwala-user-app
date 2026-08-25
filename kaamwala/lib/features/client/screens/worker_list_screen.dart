/// Worker list / search results (Phase 3 C6). Sorted by rating,
/// name-search filter, live navigation to profiles.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

enum WorkerSort { rating, priceLowHigh, priceHighLow }

class WorkerListScreen extends ConsumerStatefulWidget {
  const WorkerListScreen({super.key});

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _city;
  WorkerSort _sort = WorkerSort.rating;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _city = (profile?.city ?? '').isEmpty ? null : profile!.city;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({String? name}) {
    final category = ref.read(selectedCategoryProvider);
    ref
        .read(workersByCategoryProvider(category).notifier)
        .load(city: _city, name: name);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(name: q));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(selectedCategoryProvider);
    final workersState = ref.watch(workersByCategoryProvider(category));

    final sorted = [...workersState.workers];
    switch (_sort) {
      case WorkerSort.rating:
        sorted.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
      case WorkerSort.priceLowHigh:
        sorted.sort((a, b) => a.priceMin.compareTo(b.priceMin));
      case WorkerSort.priceHighLow:
        sorted.sort((a, b) => b.priceMax.compareTo(a.priceMax));
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: KwSpacing.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${category.labelEn}s'),
            if (_city != null)
              Text(
                'in $_city',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: KwColors.muted),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<WorkerSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: WorkerSort.rating,
                child: Text('Top rated first'),
              ),
              PopupMenuItem(
                value: WorkerSort.priceLowHigh,
                child: Text('Price: low to high'),
              ),
              PopupMenuItem(
                value: WorkerSort.priceHighLow,
                child: Text('Price: high to low'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KwSpacing.lg,
              KwSpacing.xs,
              KwSpacing.lg,
              KwSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search by name',
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: workersState.loading
                ? const Center(child: CircularProgressIndicator())
                : sorted.isEmpty
                ? EmptyState(
                    emoji: '🔍',
                    title: 'No ${category.labelEn.toLowerCase()}s found',
                    subtitle: 'Try a different category or check back soon - new workers join every day.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _load(name: _searchCtrl.text),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        KwSpacing.lg,
                        KwSpacing.sm,
                        KwSpacing.lg,
                        KwSpacing.xxl,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, i) => WorkerCard(
                        worker: sorted[i],
                        onTap: () => context.push('/worker/${sorted[i].id}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
