/// Worker-side Riverpod providers - jobs pipeline + dashboard stats.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/worker/repositories/worker_repository.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/supabase_service.dart';

final workerRepoProvider = Provider((_) => const WorkerRepository());

/// Pending job requests (W4). Demo mode -> empty list -> empty state.
class WorkerJobsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final result = await ref.read(workerRepoProvider).pendingJobs();
    return switch (result) {
      Success(:final data) => data,
      Error() => [],
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Accept moves pending -> accepted and opens the active-job screen.
  Future<bool> accept(Booking b) async {
    final res = await ref
        .read(workerRepoProvider)
        .updateStatus(
          b.id,
          BookingStatus.accepted,
          expectedFrom: BookingStatus.pending,
        );
    final ok = res is Success;
    if (ok) await refresh();
    return ok;
  }

  /// Decline removes the request from the pipeline.
  Future<void> decline(Booking b) async {
    await ref
        .read(workerRepoProvider)
        .updateStatus(
          b.id,
          BookingStatus.declined,
          expectedFrom: BookingStatus.pending,
        );
    await refresh();
  }
}

final workerJobsProvider =
    AsyncNotifierProvider<WorkerJobsController, List<Booking>>(
      WorkerJobsController.new,
    );

/// All non-terminal bookings for this worker (accepted -> in progress).
class ActiveJobsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    const statuses = [
      BookingStatus.accepted,
      BookingStatus.traveling,
      BookingStatus.arrived,
      BookingStatus.inProgress,
    ];
    final result = await ref
        .read(workerRepoProvider)
        .myBookings(statuses: SupabaseService.isReady ? statuses : null);
    return switch (result) {
      Success(:final data) => data,
      Error() => [],
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final activeJobsProvider =
    AsyncNotifierProvider<ActiveJobsController, List<Booking>>(
      ActiveJobsController.new,
    );

/// Completed bookings - earnings history (W7). Earnings shown are the
/// server-computed worker_earning values, never recalculated client-side.
class CompletedJobsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final result = await ref
        .read(workerRepoProvider)
        .myBookings(statuses: [BookingStatus.completed]);
    return switch (result) {
      Success(:final data) => data,
      Error() => [],
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final completedJobsProvider =
    AsyncNotifierProvider<CompletedJobsController, List<Booking>>(
      CompletedJobsController.new,
    );

/// Single booking by id for the job detail screen (W5).
final bookingByIdProvider = FutureProvider.autoDispose.family<Booking?, String>(
  (ref, id) async {
    final result = await ref.watch(workerRepoProvider).bookingById(id);
    return switch (result) {
      Success(:final data) => data,
      Error() => null,
    };
  },
);

/// Dashboard aggregates (W3): counts + sums over server-stored values.
class WorkerDashboardStats {
  const WorkerDashboardStats({
    this.activeCount = 0,
    this.todayEarning = 0,
    this.monthEarning = 0,
    this.weekEarning = 0,
  });

  final int activeCount;
  final num todayEarning;
  final num monthEarning;
  final num weekEarning;
}

final workerStatsProvider = Provider<WorkerDashboardStats>((ref) {
  final active = ref.watch(activeJobsProvider).value ?? const <Booking>[];
  final done = ref.watch(completedJobsProvider).value ?? const <Booking>[];
  final now = DateTime.now();
  var week = now.subtract(const Duration(days: 7));
  var month = DateTime(now.year, now.month, 1);
  num today = 0, weekSum = 0, monthSum = 0;
  for (final b in done) {
    final at = b.createdAt;
    if (at == null) continue;
    final day = DateTime(at.year, at.month, at.day);
    final todayDay = DateTime(now.year, now.month, now.day);
    if (day == todayDay) today += b.workerEarning;
    if (at.isAfter(week)) weekSum += b.workerEarning;
    if (at.isAfter(month)) monthSum += b.workerEarning;
  }
  return WorkerDashboardStats(
    activeCount: active.length,
    todayEarning: today,
    weekEarning: weekSum,
    monthEarning: monthSum,
  );
});

/// Greeting name from the auth profile ('' when unknown).
final workerNameProvider = Provider<String>((ref) {
  final profile = ref.watch(authControllerProvider).profile;
  return profile?.name ?? '';
});
