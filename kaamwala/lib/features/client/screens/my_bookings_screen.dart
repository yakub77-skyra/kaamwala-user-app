/// My Bookings list + Booking detail/track (Phase 3 C10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          emoji: '⚠️',
          title: 'Could not load bookings',
          subtitle: 'Pull to retry.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                emoji: '📋',
                title: 'No bookings yet',
                subtitle: 'Find a worker and book in 3 taps.',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(myBookingsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: KwSpacing.md),
                      child: Padding(
                        padding: const EdgeInsets.all(KwSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    b.clientName.isEmpty
                                        ? b.ref
                                        : '${b.category.labelEn} • ${b.ref}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                Text(
                                  b.status.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: KwSpacing.sm),
                            Text(
                              '${b.status.emoji} ${b.status.label}',
                              style: TextStyle(
                                color: switch (b.status) {
                                  BookingStatus.completed => KwColors.green,
                                  BookingStatus.cancelled ||
                                  BookingStatus.declined => KwColors.red,
                                  _ => KwColors.gold,
                                },
                              ),
                            ),
                            const SizedBox(height: KwSpacing.md),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Chat'),
                                  onPressed: () => context.go('/chat/${b.id}'),
                                ),
                                const SizedBox(width: KwSpacing.md),
                                FilledButton.icon(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('Track'),
                                  onPressed: () =>
                                      context.go('/booking/${b.id}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    final booking = bookings.value?.where((b) => b.id == bookingId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text('#${booking?.ref ?? bookingId.substring(0, 8)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          if (booking == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                CircleAvatar(child: const Icon(Icons.person)),
                const SizedBox(width: KwSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Worker'),
                    Text(
                      '⭐ rated professional',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: KwSpacing.xxl),
            StatusTimeline(status: booking.status),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(booking.address),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.build_outlined),
              title: Text(booking.description),
            ),
            if (booking.canCancel) ...[
              const SizedBox(height: KwSpacing.lg),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Cancel Booking (full ₹20 refund)'),
                style: OutlinedButton.styleFrom(foregroundColor: KwColors.red),
                onPressed: () async {
                  await ref.read(bookingsRepoProvider).cancel(booking.id);
                  if (!context.mounted) return;
                  ref.read(myBookingsProvider.notifier).refresh();
                },
              ),
            ],
            if (booking.status == BookingStatus.completed &&
                !booking.clientConfirmed) ...[
              const SizedBox(height: KwSpacing.md),
              ElevatedButton.icon(
                icon: const Icon(Icons.thumb_up),
                label: const Text('Confirm Work Done → Release Payment'),
                onPressed: () async {
                  await ref
                      .read(bookingsRepoProvider)
                      .confirmCompletion(booking.id);
                  if (!context.mounted) return;
                  context.go('/rate/${booking.id}');
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
