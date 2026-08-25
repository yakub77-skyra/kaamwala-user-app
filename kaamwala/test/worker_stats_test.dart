// WorkerDashboardStats - the only client-side money math in the app.
// Everything it sums comes from server-computed worker_earning values; this
// pins the today/week/month windows so a refactor can't silently change
// what workers see on their dashboard.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/features/worker/providers/worker_providers.dart';
import 'package:kaamwala/models/booking.dart';

class FixedActiveJobs extends ActiveJobsController {
  FixedActiveJobs(this.items);
  final List<Booking> items;

  @override
  Future<List<Booking>> build() async => items;
}

class FixedCompletedJobs extends CompletedJobsController {
  FixedCompletedJobs(this.items);
  final List<Booking> items;

  @override
  Future<List<Booking>> build() async => items;
}

Booking _completed(num earning, DateTime createdAt) => Booking(
  id: 'b-$earning',
  ref: 'KW-X',
  clientId: 'c',
  workerId: 'w',
  category: ServiceCategory.plumber,
  description: '',
  status: BookingStatus.completed,
  workerEarning: earning,
  createdAt: createdAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('today/week/month windows and active count', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final inMonthOutsideWeek =
        monthStart.isAfter(now.subtract(const Duration(days: 7)))
        ? monthStart.add(const Duration(hours: 1))
        : now.subtract(const Duration(days: 10));

    // Expected values computed independently of the implementation.
    final bookings = [
      _completed(100, now), // today + week + month
      _completed(200, now.subtract(const Duration(days: 2))), // week + month
      _completed(400, inMonthOutsideWeek), // month only (by construction)
      _completed(800, now.subtract(const Duration(days: 40))), // nothing
    ];

    num weekExpected = 0, monthExpected = 0, todayExpected = 0;
    for (final b in bookings) {
      final at = b.createdAt!;
      if (at.isAfter(now.subtract(const Duration(days: 7)))) {
        weekExpected += b.workerEarning;
      }
      if (at.isAfter(monthStart) ||
          at == monthStart ||
          (at.year == monthStart.year && at.month == monthStart.month)) {
        monthExpected += b.workerEarning;
      }
      if (DateTime(at.year, at.month, at.day) ==
          DateTime(now.year, now.month, now.day)) {
        todayExpected += b.workerEarning;
      }
    }

    final container = ProviderContainer(
      overrides: [
        activeJobsProvider.overrideWith(
          () => FixedActiveJobs([
            Booking(
              id: 'a1',
              ref: 'KW-A',
              clientId: 'c',
              workerId: 'w',
              category: ServiceCategory.plumber,
              description: '',
              status: BookingStatus.inProgress,
            ),
          ]),
        ),
        completedJobsProvider.overrideWith(() => FixedCompletedJobs(bookings)),
      ],
    );
    addTearDown(container.dispose);

    // workerStatsProvider is synchronous over cached async values - resolve
    // both sources before reading the aggregate.
    await container.read(activeJobsProvider.future);
    await container.read(completedJobsProvider.future);
    final stats = container.read(workerStatsProvider);

    expect(stats.activeCount, 1);
    expect(stats.todayEarning, todayExpected);
    expect(stats.weekEarning, weekExpected);
    expect(stats.monthEarning, monthExpected);
    // Sanity on construction above: today is a strict subset of week.
    expect(todayExpected, 100);
  });

  test('empty history yields zeroed dashboard', () async {
    final container = ProviderContainer(
      overrides: [
        activeJobsProvider.overrideWith(() => FixedActiveJobs(const [])),
        completedJobsProvider.overrideWith(() => FixedCompletedJobs(const [])),
      ],
    );
    addTearDown(container.dispose);

    await container.read(activeJobsProvider.future);
    await container.read(completedJobsProvider.future);
    final stats = container.read(workerStatsProvider);
    expect(stats.activeCount, 0);
    expect(stats.todayEarning, 0);
    expect(stats.weekEarning, 0);
    expect(stats.monthEarning, 0);
  });

  test('commission constants match the business model', () {
    // Rs.20 fee, worker keeps 90% - Phase 2 PRD.
    expect(AppConstants.bookingFeeRupees, 20);
    expect(AppConstants.commissionRate, 0.10);
  });
}
