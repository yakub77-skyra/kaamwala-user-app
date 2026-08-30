/// In-app notification banner host + system permission gate (Phase 3).
///
/// Rendered once at the MaterialApp.builder level:
///  - Listens to the NotificationService banner stream and shows a slim
///    top card (auto-dismiss, tap = open target). Suppressed while the user
///    is already looking at that chat or the notification center.
///  - [NotificationPermissionGate] asks the system permission once (after
///    the value-prop dialog) without ever blocking or crashing.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/notifications/models/app_notification.dart';
import 'package:kaamwala/features/notifications/providers/notification_providers.dart';
import 'package:kaamwala/features/shared/providers/shared_providers.dart';

class InAppBannerHost extends ConsumerStatefulWidget {
  const InAppBannerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppBannerHost> createState() => _InAppBannerHostState();
}

class _InAppBannerHostState extends ConsumerState<InAppBannerHost> {
  StreamSubscription<AppNotification>? _sub;
  AppNotification? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(notificationServiceProvider).banners.listen(_onBanner);
  }

  void _onBanner(AppNotification n) {
    if (!mounted) return;
    if (_shouldSuppress(n)) return;
    _dismissTimer?.cancel();
    setState(() => _current = n);
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _current = null);
    });
  }

  /// No banner while reading that very chat or the notification center.
  bool _shouldSuppress(AppNotification n) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return false;
    final loc = GoRouter.of(ctx).state.matchedLocation;
    if (loc == '/notifications') return true;
    final bookingId = n.bookingId;
    if (bookingId != null &&
        loc.startsWith('/chat/') &&
        loc.contains(bookingId)) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the live feed alive for the whole session - it is the source of
    // banners (realtime inserts -> showBanner).
    ref.watch(notificationCenterProvider);
    final service = ref.watch(notificationServiceProvider);
    final n = _current;
    return Stack(
      children: [
        widget.child,
        if (n != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BannerCard(
              notification: n,
              showMockTag: service.isMock,
              onTap: () {
                _dismissTimer?.cancel();
                setState(() => _current = null);
                openNotification(ref, n);
              },
              onDismiss: () {
                _dismissTimer?.cancel();
                setState(() => _current = null);
              },
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.notification,
    required this.showMockTag,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final bool showMockTag;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KwSpacing.md,
          KwSpacing.sm,
          KwSpacing.md,
          0,
        ),
        child: Material(
          color: KwColors.ink,
          borderRadius: BorderRadius.circular(KwRadius.md),
          elevation: 6,
          shadowColor: Colors.black38,
          child: InkWell(
            borderRadius: BorderRadius.circular(KwRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KwSpacing.md,
                vertical: KwSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: KwSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (showMockTag) ...[
                              const SizedBox(width: KwSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'mock',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for SYSTEM notification permission once, behind a value-prop dialog.
/// Denied/cancelled never blocks the app (in-app notifications keep working).
class NotificationPermissionGate extends ConsumerWidget {
  const NotificationPermissionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(authControllerProvider).stage;
    final prefs = ref.watch(prefsProvider);
    final authed = stage == AppStage.clientApp || stage == AppStage.workerApp;
    if (authed &&
        prefs.loaded &&
        !prefs.notificationPermissionAsked &&
        prefs.notificationsOn) {
      ref.read(prefsProvider.notifier).setPermissionAsked();
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask(ref));
    }
    return const SizedBox.shrink();
  }

  Future<void> _ask(WidgetRef ref) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final granted = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.notifications_active_outlined,
          size: 36,
          color: KwColors.primary,
        ),
        title: const Text('Stay updated'),
        content: const Text(
          'Get a heads-up when a worker replies, accepts your booking '
          'or your payment changes. We never spam.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow notifications'),
          ),
        ],
      ),
    );
    if (granted == true) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
  }
}
