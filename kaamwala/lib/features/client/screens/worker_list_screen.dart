/// Worker list / search results (Phase 3 C6). Sorted by rating,
/// name-search filter, live navigation to profiles.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/services/location_service.dart';

enum WorkerSort { rating, priceLowHigh, priceHighLow, distance }

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
  bool _availableNow = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _city = (profile?.city ?? '').isEmpty ? null : profile!.city;
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _getUserLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
        if (mounted) setState(() => _userPosition = pos);
      }
    } catch (_) {}
  }

  void _load({String? name}) {
    final category = ref.read(selectedCategoryProvider);
    ref
        .read(workersByCategoryProvider(category).notifier)
        .load(
          city: _city,
          name: name,
          availableNow: _availableNow,
          userLat: _userPosition?.latitude,
          userLng: _userPosition?.longitude,
        );
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
      case WorkerSort.distance:
        if (_userPosition != null) {
          sorted.sort((a, b) {
            final da = a.distanceKmFrom(_userPosition!.latitude, _userPosition!.longitude) ?? double.infinity;
            final db = b.distanceKmFrom(_userPosition!.latitude, _userPosition!.longitude) ?? double.infinity;
            return da.compareTo(db);
          });
        }
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
          // Available Now filter
          IconButton(
            tooltip: 'Available now',
            icon: Icon(
              Icons.schedule_rounded,
              color: _availableNow ? KwColors.primary : KwColors.muted,
            ),
            onPressed: () {
              setState(() {
                _availableNow = !_availableNow;
                _load(name: _searchCtrl.text);
              });
            },
          ),
          PopupMenuButton<WorkerSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: WorkerSort.rating,
                child: Text('Top rated first'),
              ),
              const PopupMenuItem(
                value: WorkerSort.priceLowHigh,
                child: Text('Price: low to high'),
              ),
              const PopupMenuItem(
                value: WorkerSort.priceHighLow,
                child: Text('Price: high to low'),
              ),
              PopupMenuItem(
                value: WorkerSort.distance,
                enabled: _userPosition != null,
                child: Text(
                  _userPosition != null ? 'Nearest first' : 'Nearest first (enable location)',
                ),
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
          // Active filter chips
          if (_availableNow || _sort == WorkerSort.distance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KwSpacing.lg),
              child: Wrap(
                spacing: KwSpacing.sm,
                children: [
                  if (_availableNow)
                    InputChip(
                      label: const Text('Available now'),
                      onDeleted: () {
                        setState(() {
                          _availableNow = false;
                          _load(name: _searchCtrl.text);
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_sort == WorkerSort.distance && _userPosition != null)
                    InputChip(
                      label: const Text('Sorted by distance'),
                      onDeleted: () {
                        setState(() => _sort = WorkerSort.rating);
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ),
          Expanded(
            child: workersState.loading
                ? const Padding(
                    padding: EdgeInsets.all(KwSpacing.lg),
                    child: KwSkeletonList(),
                  )
                : sorted.isEmpty
                ? KwEmptyState(
                    illustration: KwIllustration.search,
                    title: 'No ${category.labelEn.toLowerCase()}s found',
                    subtitle:
                        'Try a different category or check back soon - new '
                        'workers join every day.',
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
                      itemBuilder: (context, i) {
                        final w = sorted[i];
                        double? distance;
                        if (_sort == WorkerSort.distance && _userPosition != null) {
                          distance = w.distanceKmFrom(_userPosition!.latitude, _userPosition!.longitude);
                        }
                        return WorkerCard(
                          worker: w,
                          distanceKm: distance,
                          onTap: () => context.push('/worker/${w.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
