/// Client-side Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/client/repositories/bookings_repository.dart';
import 'package:kaamwala/features/client/repositories/chat_repository.dart';
import 'package:kaamwala/features/client/repositories/workers_repository.dart';
import 'package:kaamwala/features/shared/providers/shared_providers.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/models/worker.dart';
import 'package:kaamwala/services/supabase_service.dart';
import 'package:kaamwala/services/location_service.dart';

final workersRepoProvider = Provider((_) => const WorkersRepository());
final bookingsRepoProvider = Provider((_) => const BookingsRepository());
final reviewsRepoProvider = Provider((_) => const ReviewsRepository());
final chatRepoProvider = Provider((_) => const ChatRepository());

/// User's current location for distance-based worker search.
/// Null if not available / permission denied.
final userLocationProvider = FutureProvider.autoDispose<({double lat, double lng})?>((
  ref,
) async {
  final result = await LocationService.detectCity();
  if (result case Success(:final data)) {
    // We only get city name from detectCity, not coordinates.
    // For distance sorting, we'd need actual GPS coordinates.
    // This is a placeholder - in production, use Geolocator.getCurrentPosition directly.
    return null;
  }
  return null;
});

class WorkersState {
  const WorkersState({this.workers = const [], this.loading = false});
  final List<Worker> workers;
  final bool loading;
}

class WorkersController
    extends AutoDisposeFamilyNotifier<WorkersState, ServiceCategory> {
  @override
  WorkersState build(ServiceCategory arg) => const WorkersState();

  Future<void> load({
    String? city,
    String? name,
    bool availableNow = false,
    double? userLat,
    double? userLng,
  }) async {
    state = WorkersState(workers: state.workers, loading: true);
    final result = await ref
        .read(workersRepoProvider)
        .search(
          category: arg,
          city: city,
          name: name,
          availableNow: availableNow,
          userLat: userLat,
          userLng: userLng,
        );
    state = switch (result) {
      Success(:final data) => WorkersState(workers: data),
      _ => const WorkersState(),
    };
  }
}

final workersByCategoryProvider = NotifierProvider.autoDispose
    .family<WorkersController, WorkersState, ServiceCategory>(
      WorkersController.new,
    );

/// Home "Top rated near you" - live from workers table.
final topRatedWorkersProvider = AutoDisposeFutureProvider<List<Worker>>((
  ref,
) async {
  final profile = ref.watch(authControllerProvider).profile;
  final result = await ref
      .read(workersRepoProvider)
      .topRated(city: (profile?.city ?? '').isEmpty ? null : profile!.city);
  return switch (result) {
    Success(:final data) => data,
    Error() => const [],
  };
});

/// Unread notification badge for the home bell.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final res = await ref.watch(notificationsRepoProvider).unreadCount();
  return switch (res) {
    Success(:final data) => data,
    Error() => 0,
  };
});

/// Selected category on Home (C5 -> C6 navigation payload).
final selectedCategoryProvider = StateProvider<ServiceCategory>(
  (_) => ServiceCategory.plumber,
);

class MyBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final profile = ref.watch(authControllerProvider).profile;
    final uid = profile?.id ?? SupabaseService.currentUserId;
    if (uid == null) return [];
    final result = await ref.read(bookingsRepoProvider).forClient(uid);
    return switch (result) {
      Success(:final data) => data,
      Error() => [],
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => build());
  }
}

final myBookingsProvider =
    AsyncNotifierProvider<MyBookingsController, List<Booking>>(
      MyBookingsController.new,
    );
