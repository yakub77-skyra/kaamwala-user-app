/// Notification center (Phase 3) - live feed from the notifications table.
///
/// Tap -> mark read + deep-link to the relevant screen (booking/chat/payment).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_empty_state.dart';
import 'package:kaamwala/features/notifications/models/app_notification.dart';
import 'package:kaamwala/features/notifications/providers/notification_providers.dart';
import 'package:kaamwala/services/analytics_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.newMessage => Icons.chat_bubble_outline_rounded,
    AppNotificationType.payment ||
    AppNotificationType.paymentPending ||
    AppNotificationType.paymentSuccess ||
    AppNotificationType.paymentFailed => Icons.currency_rupee_outlined,
    AppNotificationType.workerApproved => Icons.verified_outlined,
    AppNotificationType.workerRejected => Icons.block_outlined,
    _ => Icons.handyman_outlined,
  };

  String _whenAgo(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationCenterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          async.maybeWhen(
            data: (s) => s.unread > 0
                ? TextButton(
                    onPressed: () => ref
                        .read(notificationCenterProvider.notifier)
                        .markAllRead(),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const KwEmptyState(
          illustration: KwIllustration.offline,
          title: 'Could not load notifications',
          subtitle: 'Pull down to retry.',
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () async =>
              await ref.read(notificationCenterProvider.notifier).refresh(),
          child: state.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .7,
                      child: const KwEmptyState(
                        illustration: KwIllustration.bookings,
                        title: 'No notifications yet',
                        subtitle:
                            'Booking updates and payment alerts appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: KwSpacing.md),
                  itemBuilder: (context, i) {
                    final n = state.items[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      color: n.isRead
                          ? KwColors.surface
                          : KwColors.primaryLight,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: n.isRead
                              ? KwColors.fill
                              : KwColors.primary.withValues(alpha: .15),
                          child: Icon(
                            _iconFor(n.type),
                            size: 19,
                            color: n.isRead ? KwColors.muted : KwColors.primary,
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: n.isRead ? null : KwColors.dark,
                          ),
                        ),
                        subtitle: Text(n.body),
                        trailing: Text(
                          _whenAgo(n.createdAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: KwColors.muted),
                        ),
                        onTap: () {
                          unawaited(
                            AnalyticsService.logEvent(
                              'notification_center_opened',
                            ),
                          );
                          openNotification(ref, n);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
