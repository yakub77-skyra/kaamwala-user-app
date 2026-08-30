/// My Bookings list + Booking detail/track (Phase 3 C10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dart:async';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/chat/providers/chat_providers.dart';
import 'package:kaamwala/features/chat/widgets/chat_widgets.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

enum _BookingsFilter { active, completed, cancelled, all }

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  _BookingsFilter _filter = _BookingsFilter.active;

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            onPressed: () => ref.read(myBookingsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- filter chips ----------
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: KwSpacing.lg),
              children: [
                for (final f in _BookingsFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: KwSpacing.sm),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        _BookingsFilter.active => 'Active',
                        _BookingsFilter.completed => 'Completed',
                        _BookingsFilter.cancelled => 'Cancelled',
                        _BookingsFilter.all => 'All',
                      }),
                      selected: _filter == f,
                      showCheckmark: false,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: bookings.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(KwSpacing.lg),
                child: KwSkeletonList(),
              ),
              error: (e, _) => KwEmptyState(
                illustration: KwIllustration.offline,
                title: 'Could not load bookings',
                subtitle: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => ref.read(myBookingsProvider.notifier).refresh(),
              ),
              data: (list) {
                final filtered = switch (_filter) {
                  _BookingsFilter.active =>
                    list.where((b) => b.status.isActive).toList(),
                  _BookingsFilter.completed =>
                    list
                        .where((b) => b.status == BookingStatus.completed)
                        .toList(),
                  _BookingsFilter.cancelled =>
                    list
                        .where(
                          (b) =>
                              b.status == BookingStatus.cancelled ||
                              b.status == BookingStatus.declined,
                        )
                        .toList(),
                  _BookingsFilter.all => list,
                };
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(myBookingsProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * .55,
                          child:
                              _filter == _BookingsFilter.active && list.isEmpty
                              ? KwEmptyState(
                                  illustration: KwIllustration.bookings,
                                  title: 'No bookings yet',
                                  subtitle:
                                      'Find a verified worker and book in a '
                                      'few taps.',
                                  actionLabel: 'Find a Worker',
                                  onAction: () => context.go('/home'),
                                )
                              : const KwEmptyState(
                                  illustration: KwIllustration.bookings,
                                  title: 'Nothing here',
                                  subtitle: 'No bookings match this filter.',
                                ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(myBookingsProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      KwSpacing.lg,
                      KwSpacing.md,
                      KwSpacing.lg,
                      KwSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _BookingCard(booking: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final dateLine = [
      if (b.serviceDate != null)
        DateFormat('dd MMM yyyy').format(b.serviceDate!),
      if (b.timeSlot.isNotEmpty) b.timeSlot,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: InkWell(
        onTap: () => context.push('/booking/${b.id}'),
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: KwColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      b.category.icon,
                      size: 21,
                      color: KwColors.primary,
                    ),
                  ),
                  const SizedBox(width: KwSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.workerName.isEmpty
                              ? b.category.labelEn
                              : b.workerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${b.category.labelEn} • ${b.ref}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: KwColors.muted),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(status: b.status),
                ],
              ),
              if (b.description.isNotEmpty) ...[
                const SizedBox(height: KwSpacing.md),
                Text(
                  b.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: KwSpacing.sm),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: KwColors.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      b.address.isEmpty ? '-' : b.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ),
                  if (dateLine.isNotEmpty) ...[
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: KwColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLine,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ],
              ),
              const Divider(height: KwSpacing.lg),
              Row(
                children: [
                  Text(
                    b.clientConfirmed && b.status == BookingStatus.completed
                        ? 'Paid ✓'
                        : b.needsPayment
                        ? 'Fee ₹${b.bookingFee.toStringAsFixed(0)}'
                        : 'Fee ₹${b.bookingFee.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          b.clientConfirmed &&
                              b.status == BookingStatus.completed
                          ? KwColors.green
                          : KwColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (b.needsPayment) ...[
                    FilledButton(
                      onPressed: () => context.push('/payment/${b.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        b.status == BookingStatus.paymentFailed
                            ? 'Retry Payment'
                            : 'Pay Now',
                      ),
                    ),
                  ] else ...[
                    ChatUnreadButton(bookingId: b.id),
                    const SizedBox(width: KwSpacing.xs),
                    FilledButton(
                      onPressed: () => context.push('/booking/${b.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        b.status == BookingStatus.completed
                            ? 'Details'
                            : 'Track',
                      ),
                    ),
                  ],
                ],
              ),
              if (b.status == BookingStatus.cancelled &&
                  b.refundNote != null) ...[
                const SizedBox(height: KwSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.undo_rounded,
                      size: 14,
                      color: KwColors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        b.refundNote!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KwColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (b.status == BookingStatus.cancelled &&
                  b.cancellationReason != null) ...[
                const SizedBox(height: KwSpacing.xs),
                Text(
                  'Reason: ${b.cancellationReason}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  static const _cancelReasons = [
    'Worker not responding',
    'Selected wrong time',
    'Issue already fixed',
    'Price concern',
    'Other',
  ];

  Future<void> _cancel(BuildContext context, WidgetRef ref, Booking b) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelReasonDialog(reasons: _cancelReasons),
    );
    if (reason == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'Your ₹${b.bookingFee.toStringAsFixed(0)} booking fee will be '
          'refunded to your original payment method if you already paid. '
          'This cannot be undone once the worker starts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: KwColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final res = await ref
        .read(bookingsRepoProvider)
        .cancelBooking(b.id, reason: reason);
    if (!context.mounted) return;
    final ok = res is Success<CancelBookingResult>;
    if (ok) {
      unawaited(
        AnalyticsService.logEvent('booking_cancelled', {
          'reason': reason,
          'refund': res.data.refundStatus.name,
        }),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? res.data.refundMessage ?? 'Booking cancelled'
              : (res as Error).failure.message,
        ),
      ),
    );
    ref.read(myBookingsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    final booking = bookings.value?.where((b) => b.id == bookingId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text('#${booking?.ref ?? bookingId.substring(0, 8)}'),
      ),
      bottomNavigationBar:
          (booking != null &&
              booking.status == BookingStatus.completed &&
              !booking.clientConfirmed)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KwSpacing.lg,
                  KwSpacing.sm,
                  KwSpacing.lg,
                  KwSpacing.lg,
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                  label: const Text('Confirm & release payment'),
                  onPressed: () async {
                    final res = await ref
                        .read(bookingsRepoProvider)
                        .confirmCompletion(booking.id);
                    if (!context.mounted) return;
                    if (res is Success<void>) {
                      unawaited(
                        AnalyticsService.logEvent('completion_confirmed', {
                          'booking_id': booking.id,
                        }),
                      );
                      context.push('/rate/${booking.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text((res as Error).failure.message)),
                      );
                    }
                    ref.read(myBookingsProvider.notifier).refresh();
                  },
                ),
              ),
            )
          : null,
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const KwEmptyState(
          illustration: KwIllustration.bookings,
          title: 'Could not load this booking',
        ),
        data: (list) {
          final b = list.where((x) => x.id == bookingId).firstOrNull;
          if (b == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              // ---------- worker header ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  child: Row(
                    children: [
                      WorkerAvatar(url: b.workerPhoto, radius: 26),
                      const SizedBox(width: KwSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    b.workerName.isEmpty
                                        ? b.category.labelEn
                                        : b.workerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: KwColors.green,
                                ),
                              ],
                            ),
                            Text(
                              'Verified professional',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: KwColors.green),
                            ),
                          ],
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final unread =
                              ref.watch(chatUnreadProvider(b.id)).valueOrNull ??
                              0;
                          return OutlinedButton.icon(
                            onPressed: () async {
                              await context.push('/chat/${b.id}');
                              ref.invalidate(chatUnreadProvider(b.id));
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            icon: Badge(
                              isLabelVisible: unread > 0,
                              backgroundColor: KwColors.red,
                              label: Text('$unread'),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 15,
                              ),
                            ),
                            label: const Text('Chat'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.md),

              // ---------- status ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Job status',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          StatusPill(status: b.status),
                        ],
                      ),
                      const SizedBox(height: KwSpacing.lg),
                      StatusTimeline(status: b.status),
                    ],
                  ),
                ),
              ),

              // ---------- live location (when traveling) ----------
              if (b.isSharingLocation) ...[
                const SizedBox(height: KwSpacing.md),
                _LiveLocationCard(booking: b),
              ],
              const SizedBox(height: KwSpacing.md),

              // ---------- details ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KwSpacing.sm),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Work requested'),
                        subtitle: Text(
                          b.description.isEmpty ? '-' : b.description,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: const Text('Address'),
                        subtitle: Text(b.address.isEmpty ? '-' : b.address),
                      ),
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Scheduled for'),
                        subtitle: Text(
                          [
                            if (b.serviceDate != null)
                              DateFormat('EEE, dd MMM yyyy')
                                  .format(b.serviceDate!),
                            if (b.timeSlot.isNotEmpty) b.timeSlot,
                          ].join(' • '),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('Estimate & fee'),
                        subtitle: Text(
                          '₹${b.estimateMin.toStringAsFixed(0)}–₹${b.estimateMax.toStringAsFixed(0)} job estimate'
                          ' • ₹${b.bookingFee.toStringAsFixed(0)} booking fee',
                        ),
                      ),
                      // ---------- payment / refund info ----------
                      if (b.needsPayment) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.payment_rounded),
                          title: Text(
                            b.status == BookingStatus.paymentFailed
                                ? 'Payment failed'
                                : 'Payment pending',
                          ),
                          subtitle: const Text(
                            'You can pay anytime from here or My Bookings.',
                          ),
                          trailing: FilledButton(
                            onPressed: () => context.push('/payment/${b.id}'),
                            child: Text(
                              b.status == BookingStatus.paymentFailed
                                  ? 'Retry Payment'
                                  : 'Pay Now',
                            ),
                          ),
                        ),
                      ],
                      if (b.status == BookingStatus.cancelled &&
                          b.refundNote != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.undo_rounded,
                            color: KwColors.green,
                          ),
                          title: const Text('Refund'),
                          subtitle: Text(
                            b.refundNote!,
                            style: const TextStyle(color: KwColors.green),
                          ),
                        ),
                      ],
                      if (b.paymentStatus == PaymentStatus.paid &&
                          b.transactionReference != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          title: const Text('Transaction reference'),
                          subtitle: Text(b.transactionReference!),
                        ),
                      ],
                      // ---------- photos ----------
                      if (b.photoUrls.isNotEmpty) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: const Text('Job photos'),
                          subtitle: Text('${b.photoUrls.length} photo(s)'),
                        ),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: KwSpacing.lg,
                            ),
                            itemCount: b.photoUrls.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: KwSpacing.sm),
                            itemBuilder: (context, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(KwRadius.sm),
                              child: Image.network(
                                b.photoUrls[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 80,
                                  height: 80,
                                  color: KwColors.fill,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ---------- cancel ----------
              if (b.canCancel) ...[
                const SizedBox(height: KwSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      'Cancel Booking (full ₹${b.bookingFee.toStringAsFixed(0)} refund)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KwColors.red,
                    ),
                    onPressed: () => _cancel(context, ref, b),
                  ),
                ),
              ],
              if (b.status == BookingStatus.completed && b.clientConfirmed)
                Padding(
                  padding: const EdgeInsets.only(top: KwSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: KwColors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Work confirmed — payout released to worker',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: KwColors.green),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Cancellation reason picker (task 13) - returns the chosen reason.
class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.reasons});
  final List<String> reasons;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Why are you cancelling?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in widget.reasons)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _selected == r
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: _selected == r ? KwColors.primary : KwColors.muted,
              ),
              title: Text(r),
              onTap: () => setState(() => _selected = r),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Live location card shown on the customer's booking detail screen when the
/// worker is sharing their location during the 'traveling' status.
class _LiveLocationCard extends ConsumerStatefulWidget {
  const _LiveLocationCard({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends ConsumerState<_LiveLocationCard> {
  Booking? _latest;
  supabase.RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _latest = widget.booking;
    _subscribeBooking();
  }

  void _subscribeBooking() {
    if (!SupabaseService.isReady) return;
    _channel = ref
        .read(bookingsRepoProvider)
        .subscribeBooking(widget.booking.id, _onBookingUpdate);
  }

  void _onBookingUpdate() {
    ref.read(myBookingsProvider.notifier).refresh();
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _latest ?? widget.booking;
    if (b.liveLat == null || b.liveLng == null) {
      return const SizedBox.shrink();
    }
    final updated = b.liveLocationUpdatedAt;
    final ago = updated == null
        ? ''
        : 'updated ${DateFormat('HH:mm:ss').format(updated)}';
    return Card(
      color: KwColors.greenLight,
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: KwColors.green,
                  size: 22,
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker is on the way',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: KwColors.green,
                        ),
                      ),
                      Text(
                        'Live location sharing active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KwColors.green.withValues(alpha: .8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.directions_bike_rounded,
                  color: KwColors.green,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            Container(
              padding: const EdgeInsets.all(KwSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(KwRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: KwColors.blue,
                      ),
                      const SizedBox(width: KwSpacing.sm),
                      Expanded(
                        child: Text(
                          'Lat: ${b.liveLat!.toStringAsFixed(6)}, '
                          'Lng: ${b.liveLng!.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KwSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: KwColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ago,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KwColors.muted),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          // TODO(Phase 2): open maps with url_launcher.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening map...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('View on Map'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
