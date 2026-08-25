/// Under Review (W2), Dashboard (W3), Job Detail (W5),
/// Active Job (W6), Earnings (W7), Payment Setup (W8) - Hindi-first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/features/worker/providers/worker_providers.dart';
import 'package:kaamwala/features/worker/repositories/worker_repository.dart';
import 'package:kaamwala/models/booking.dart';

/// W2 - Profile under review gate. Worker cannot see jobs until approved.
class UnderReviewScreen extends StatelessWidget {
  const UnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⏳', style: TextStyle(fontSize: 72)),
              SizedBox(height: KwSpacing.lg),
              Text(
                'आपकी प्रोफ़ाइल जांच के अधीन है',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: KwSpacing.sm),
              Text(
                '(Profile under review)',
                style: TextStyle(color: KwColors.muted),
              ),
              SizedBox(height: KwSpacing.md),
              Text(
                'We verify your Aadhar within 24 hours.\n'
                'You\'ll get a message when approved. ✅',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// W3 - Worker dashboard: availability toggle, today stats, new jobs.
class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  bool _available = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      // Seed the toggle from the workers row (is_available, FR-WORKER-03).
      final res = await ref.read(workerRepoProvider).myWorker();
      if (!mounted || res is! Success<Map<String, dynamic>?>) return;
      final row = res.data;
      if (row == null || !row.containsKey('is_available')) return;
      setState(() => _available = (row['is_available'] ?? true) as bool);
    });
    // Keep dashboard fresh when returning from jobs screens.
    Future<void>.microtask(() => _refreshAll());
  }

  Future<void> _refreshAll() async {
    await ref.read(workerJobsProvider.notifier).refresh();
    await ref.read(activeJobsProvider.notifier).refresh();
    await ref.read(completedJobsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(workerStatsProvider);
    final name = ref.watch(workerNameProvider);
    final newJobs = ref.watch(workerJobsProvider).value ?? const <Booking>[];
    final active = ref.watch(activeJobsProvider).value ?? const <Booking>[];
    final firstName = name.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(firstName.isEmpty ? 'नमस्ते 🙏' : 'नमस्ते, $firstName 🙏'),
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.lg),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _available
                      ? const LinearGradient(
                          colors: [Color(0xFFE9F9F0), KwColors.surface],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                ),
                child: SwitchListTile(
                  value: _available,
                  onChanged: (v) {
                    // Repo call no-ops in demo mode (FR-WORKER-03).
                    setState(() => _available = v);
                    ref.read(workerRepoProvider).setAvailability(v);
                  },
                  activeThumbColor: KwColors.green,
                  secondary: Icon(
                    _available
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round,
                    color: _available ? KwColors.green : KwColors.muted,
                  ),
                  title: Text(
                    'काम के लिए उपलब्ध?',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _available
                        ? 'Clients can book you right now'
                        : 'You are hidden from search',
                  ),
                ),
              ),
            ),
            if (active.isNotEmpty) ...[
              const SizedBox(height: KwSpacing.md),
              for (final b in active) _activeJobTile(context, b),
            ],
            const SizedBox(height: KwSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'आज के काम',
                    value: '${stats.activeCount}',
                    icon: Icons.construction_rounded,
                    tint: KwColors.blue,
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: _StatCard(
                    label: 'आज की कमाई',
                    value: '₹${_money(stats.todayEarning)}',
                    icon: Icons.currency_rupee_rounded,
                    tint: KwColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'नए काम (${newJobs.length})',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/w/jobs'),
                  child: const Text('सभी देखें ›'),
                ),
              ],
            ),
            if (newJobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KwSpacing.lg),
                child: Text(
                  'अभी कोई नया काम नहीं है',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KwColors.muted),
                ),
              )
            else
              for (final b in newJobs.take(2)) _newJobCard(context, b),
          ],
        ),
      ),
    );
  }

  Widget _activeJobTile(BuildContext context, Booking b) {
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: InkWell(
        onTap: () => context.go('/w/active/${b.id}'),
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: KwColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(b.category.icon, size: 22, color: KwColors.primary),
              ),
              const SizedBox(width: KwSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      b.status.label,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: KwColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newJobCard(BuildContext context, Booking b) {
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: KwColors.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    b.category.icon,
                    size: 20,
                    color: KwColors.primary,
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: Text(
                    '${b.clientName.isEmpty ? 'New job' : b.clientName} • ~₹${b.estimateMin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (b.description.isNotEmpty) ...[
              const SizedBox(height: KwSpacing.sm),
              Text(
                b.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: KwColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    b.address.isEmpty
                        ? b.ref
                        : '${b.address}${b.timeSlot.isNotEmpty ? ' • ${b.timeSlot}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: KwColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KwColors.red,
                    ),
                    onPressed: () =>
                        ref.read(workerJobsProvider.notifier).decline(b),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept'),
                    onPressed: () async {
                      final ok = await ref
                          .read(workerJobsProvider.notifier)
                          .accept(b);
                      if (!ok || !context.mounted) return;
                      context.go('/w/active/${b.id}');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat tile used on the worker dashboard.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(num v) {
  // Indian digit grouping: last 3, then pairs (12,40,000).
  final digits = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining == 3 || (remaining > 3 && remaining.isOdd)) buf.write(',');
  }
  return buf.toString();
}

/// W5 - Job detail with real booking data + working accept/decline.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, this.jobId});
  final String? jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final booking = ref.watch(bookingByIdProvider(jobId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      bottomNavigationBar: booking.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (b) => (b == null || b.status != BookingStatus.pending)
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KwColors.red,
                          ),
                          onPressed: () async {
                            await ref
                                .read(workerJobsProvider.notifier)
                                .decline(b);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: KwSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Accept Job'),
                          onPressed: () async {
                            final ok = await ref
                                .read(workerJobsProvider.notifier)
                                .accept(b);
                            if (!ok || !context.mounted) return;
                            context.go('/w/active/${b.id}');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: booking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load this job.')),
        data: (b) {
          if (b == null) {
            return const Center(child: Text('This job no longer exists.'));
          }
          return ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('👤', style: TextStyle(fontSize: 24)),
                title: Text(b.clientName.isEmpty ? 'Client' : b.clientName),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  b.category.labelHi,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(
                  b.description.isEmpty ? b.category.labelEn : b.description,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('📍', style: TextStyle(fontSize: 24)),
                title: Text(b.address.isEmpty ? b.ref : b.address),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('📅', style: TextStyle(fontSize: 24)),
                title: Text(_whenLine(b)),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimate'),
                  Text(
                    '₹${b.estimateMin} – ₹${b.estimateMax}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.sm),
              Row(
                children: [
                  Text(
                    'You earn (${((1 - AppConstants.commissionRate) * 100).toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '₹${_money(b.estimateMin * (1 - AppConstants.commissionRate))} – ₹${_money(b.estimateMax * (1 - AppConstants.commissionRate))}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: KwColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.sm),
              Text(
                'Platform commission ${(AppConstants.commissionRate * 100).toStringAsFixed(0)}% — transparent.',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: KwColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  String _whenLine(Booking b) {
    final d = b.serviceDate;
    final parts = [
      if (d != null) '${d.day}/${d.month}/${d.year}',
      if (b.timeSlot.isNotEmpty) b.timeSlot,
    ];
    return parts.isEmpty ? 'Flexible' : parts.join(' • ');
  }
}

/// W6 - Active job status screen with ONE next-action button (Phase 3 W6).
/// Progression: accepted -> traveling -> arrived -> inProgress -> completed.
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  bool _busy = false;

  static const _flow = [
    BookingStatus.accepted,
    BookingStatus.traveling,
    BookingStatus.arrived,
    BookingStatus.inProgress,
    BookingStatus.completed,
  ];

  String _labelFor(BookingStatus next) => switch (next) {
    BookingStatus.traveling => '🛵 Start Travel',
    BookingStatus.arrived => '✅ I have Arrived',
    BookingStatus.inProgress => '🔧 Start Work',
    BookingStatus.completed => '🎉 Mark Completed',
    _ => '',
  };

  Future<void> _advance(Booking b, BookingStatus next) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref
        .read(workerRepoProvider)
        .updateStatus(widget.bookingId, next, expectedFrom: b.status);
    await ref.read(activeJobsProvider.notifier).refresh();
    await ref.read(completedJobsProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    if (next == BookingStatus.completed && context.mounted) {
      context.go('/w/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingByIdProvider(widget.bookingId));
    return Scaffold(
      appBar: AppBar(title: const Text('Active Job')),
      body: booking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const EmptyState(emoji: '⚠️', title: 'Could not load this job'),
        data: (b) {
          if (b == null) {
            return const EmptyState(emoji: '🤷', title: 'Job not found');
          }
          final idx = _flow.indexOf(b.status);
          final isTerminal =
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.declined;
          final next = !isTerminal && idx >= 0 && idx < _flow.length - 1
              ? _flow[idx + 1]
              : null;
          return ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              for (var i = 0; i < _flow.length; i++)
                StatusRow(
                  done:
                      (idx >= 0 && i < idx) ||
                      b.status == BookingStatus.completed,
                  current: i == idx,
                  label: _flow[i].label,
                ),
              const SizedBox(height: KwSpacing.xl),
              if (next != null)
                ElevatedButton.icon(
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_labelFor(next)),
                  onPressed: _busy ? null : () => _advance(b, next),
                )
              else
                Center(
                  child: Text(
                    b.status == BookingStatus.completed
                        ? 'काम पूरा हुआ 🎉 Client confirmation unlocks your payout.'
                        : 'Job ${b.status.label.toLowerCase()}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: KwColors.muted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.done,
    this.current = false,
    required this.label,
  });
  final bool done;
  final bool current;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: done
          ? const Icon(Icons.check_circle, color: KwColors.green)
          : current
          ? const Icon(Icons.radio_button_checked, color: KwColors.gold)
          : const Icon(Icons.circle_outlined, color: KwColors.muted),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: current ? FontWeight.w700 : FontWeight.w400,
          color: done || current ? KwColors.dark : KwColors.muted,
        ),
      ),
    );
  }
}

/// W7 - Earnings (Hindi-first). Sums read server-computed worker_earning.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(completedJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('कमाई (Earnings)')),
      body: done.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const EmptyState(emoji: '⚠️', title: 'Could not load earnings'),
        data: (list) {
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final weekAgo = now.subtract(const Duration(days: 7));
          num month = 0, week = 0;
          for (final b in list) {
            final at = b.createdAt;
            if (at == null) continue;
            if (at.isAfter(monthStart)) month += b.workerEarning;
            if (at.isAfter(weekAgo)) week += b.workerEarning;
          }
          return ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(KwSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [KwColors.primary, KwColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(KwRadius.card),
                ),
                child: Column(
                  children: [
                    Text(
                      'इस महीने (This Month)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: KwSpacing.sm),
                    Text(
                      '₹${_money(month)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: KwSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(KwRadius.chip),
                      ),
                      child: Text(
                        'This week ₹${_money(week)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KwSpacing.lg),
              Text(
                'HISTORY',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted, letterSpacing: 1),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(KwSpacing.xl),
                  child: EmptyState(
                    emoji: '💼',
                    title: 'No completed jobs yet',
                    subtitle: 'Finish a job and it shows up here.',
                  ),
                )
              else
                for (final b in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: KwSpacing.md),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KwSpacing.lg,
                        vertical: KwSpacing.xs,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: KwColors.primaryLight,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          b.category.icon,
                          size: 20,
                          color: KwColors.primary,
                        ),
                      ),
                      title: Text(
                        b.description.isEmpty
                            ? b.category.labelEn
                            : b.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        b.status == BookingStatus.completed && b.clientConfirmed
                            ? 'Paid ✓'
                            : 'Awaiting client confirmation',
                        style: TextStyle(
                          fontSize: 12,
                          color: b.clientConfirmed
                              ? KwColors.green
                              : KwColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        '+₹${_money(b.workerEarning)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: KwColors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: KwSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Payment Setup'),
                onPressed: () => context.go('/w/payment-setup'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// W8 - One-time payment setup. UPI regex from FR-WORKER-10.
class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({super.key});

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  bool _upi = true;
  final _upiCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool get _upiValid =>
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{2,}$').hasMatch(_upiCtrl.text.trim());
  bool get _bankValid =>
      _accCtrl.text.trim().length >= 9 &&
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
          .hasMatch(_ifscCtrl.text.trim().toUpperCase()) &&
      _holderCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _upiCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Setup')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: (_upi && !_upiValid) || (!_upi && !_bankValid)
                ? null
                : () async {
                    await const WorkerRepository().savePaymentInfo(
                      upi: _upi,
                      upiId: _upiCtrl.text.trim(),
                      bankAccount: _accCtrl.text.trim(),
                      ifsc: _ifscCtrl.text.trim().toUpperCase(),
                      holderName: _holderCtrl.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.xl),
        children: [
          const Center(
            child: Text(
              'Money will come here 👇',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: KwSpacing.lg),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('UPI')),
              ButtonSegment(value: false, label: Text('Bank')),
            ],
            selected: {_upi},
            onSelectionChanged: (s) => setState(() => _upi = s.first),
          ),
          const SizedBox(height: KwSpacing.lg),
          if (_upi) ...[
            TextField(
              controller: _upiCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'ramesh@ybl'),
            ),
            const SizedBox(height: KwSpacing.sm),
            if (_upiCtrl.text.isNotEmpty)
              Text(
                _upiValid ? '✅ UPI ID looks valid' : '❌ Invalid UPI ID format',
                style: TextStyle(
                  color: _upiValid ? KwColors.green : KwColors.red,
                  fontSize: 12,
                ),
              ),
          ] else ...[
            TextField(
              controller: _accCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'Account Number'),
            ),
            const SizedBox(height: KwSpacing.md),
            TextField(
              controller: _ifscCtrl,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'IFSC Code (e.g. SBIN0001234)',
              ),
            ),
            const SizedBox(height: KwSpacing.md),
            TextField(
              controller: _holderCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'Account Holder Name'),
            ),
            if (_accCtrl.text.isNotEmpty || _ifscCtrl.text.isNotEmpty) ...[
              const SizedBox(height: KwSpacing.sm),
              Text(
                _bankValid
                    ? '✅ Details look valid'
                    : '❌ Check account number / IFSC / name',
                style: TextStyle(
                  color: _bankValid ? KwColors.green : KwColors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
