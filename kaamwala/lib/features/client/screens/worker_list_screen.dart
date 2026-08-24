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

class WorkerListScreen extends ConsumerStatefulWidget {
  const WorkerListScreen({super.key});

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _city;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _city == null
              ? '${category.labelEn}s'
              : '${category.labelEn}s • $_city',
        ),
        actions: [
          IconButton(
            onPressed: () => _load(name: _searchCtrl.text),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KwSpacing.lg,
              KwSpacing.sm,
              KwSpacing.lg,
              0,
            ),
            child: TextFormField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name',
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
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
                : workersState.workers.isEmpty
                ? EmptyState(
                    emoji: '🔍',
                    title: 'No workers found',
                    subtitle: 'Try another category or check back soon.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _load(name: _searchCtrl.text),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(KwSpacing.lg),
                      itemCount: workersState.workers.length,
                      itemBuilder: (context, i) => WorkerCard(
                        worker: workersState.workers[i],
                        onTap: () => context.push(
                          '/worker/${workersState.workers[i].id}',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
