/// Worker list / search results (Phase 3 C6). Sorted by rating, paginated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

class WorkerListScreen extends ConsumerStatefulWidget {
  const WorkerListScreen({super.key});

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final category = ref.read(selectedCategoryProvider);
      ref.read(workersByCategoryProvider(category).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(selectedCategoryProvider);
    final workersState = ref.watch(workersByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.labelEn}s • Pune'),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(workersByCategoryProvider(category).notifier)
                .load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(KwSpacing.lg, KwSpacing.sm, KwSpacing.lg, 0),
            child: TextFormField(
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KwSpacing.lg),
            child: Row(
              children: [
                const Text('Sort: '),
                FilterChip(
                  label: const Text('Top Rated ▾'),
                  selected: true,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          Expanded(
            child: workersState.loading
                ? const Center(child: CircularProgressIndicator())
                : workersState.workers.isEmpty
                    ? EmptyState(
                        emoji: '🔍',
                        title: 'No workers found',
                        subtitle: 'Try another category or check back soon.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(KwSpacing.lg),
                        itemCount: workersState.workers.length,
                        itemBuilder: (context, i) => WorkerCard(
                          worker: workersState.workers[i],
                          onTap: () {}, // -> /worker/:id
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
