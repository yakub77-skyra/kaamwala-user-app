/// Job Requests list (Phase 3 W4) - only status=pending assigned to me.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/features/worker/providers/worker_providers.dart';
import 'package:kaamwala/models/booking.dart';

class JobRequestsScreen extends ConsumerWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(workerJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('नए काम (New Jobs)')),
      body: jobs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          emoji: '⚠️',
          title: 'Could not load jobs',
          subtitle: 'Pull to retry.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                emoji: '📭',
                title: 'No new jobs right now',
                subtitle: 'New requests appear here the moment a client pays the ₹20 fee.',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(workerJobsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _JobRequestCard(booking: list[i]),
                ),
              ),
      ),
    );
  }
}

class _JobRequestCard extends ConsumerStatefulWidget {
  const _JobRequestCard({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_JobRequestCard> createState() => _JobRequestCardState();
}

class _JobRequestCardState extends ConsumerState<_JobRequestCard> {
  bool _busy = false;

  String get _meta {
    final b = widget.booking;
    final date = b.serviceDate == null
        ? ''
        : ' • ${b.serviceDate!.day}/${b.serviceDate!.month}';
    return '${b.clientName.isEmpty ? 'Client' : b.clientName}$date'
        '${b.timeSlot.isEmpty ? '' : ' • ${b.timeSlot}'}'
        '\n${b.address.isEmpty ? b.ref : b.address}'
        '   ~₹${b.estimateMin}${b.estimateMax > b.estimateMin ? '–₹${b.estimateMax}' : ''}';
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(workerJobsProvider.notifier).accept(widget.booking);
    if (!mounted) return;
    context.go('/w/active/${widget.booking.id}');
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(workerJobsProvider.notifier).decline(widget.booking);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(b.category.labelHi, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: Text(
                    '${b.category.labelEn} • ${b.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _meta,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
            const SizedBox(height: KwSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KwColors.red,
                    ),
                    onPressed: _busy ? null : _decline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    onPressed: _busy ? null : _accept,
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
