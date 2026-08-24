import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/services/fcm_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const ProviderScope(child: KaamWalaApp()));
}

class KaamWalaApp extends ConsumerStatefulWidget {
  const KaamWalaApp({super.key});

  @override
  ConsumerState<KaamWalaApp> createState() => _KaamWalaAppState();
}

class _KaamWalaAppState extends ConsumerState<KaamWalaApp> {
  StreamSubscription<RemoteMessage>? _tapSub;

  @override
  void initState() {
    super.initState();
    unawaited(_initPushRouting());
  }

  /// Push tap -> deep link (FR-NOTIF-02). No-ops without Firebase.
  Future<void> _initPushRouting() async {
    await FcmService.ensureInitialized();
    if (!FcmService.isAvailable) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && mounted) {
        _routeFromPush(initial.data);
      }
      _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
        if (mounted) _routeFromPush(m.data);
      });
    } on Exception catch (_) {}
  }

  void _routeFromPush(Map<String, dynamic> data) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final explicit = data['route'];
    if (explicit is String && explicit.startsWith('/')) {
      ctx.go(explicit);
      return;
    }
    // Role-aware fallback until every push carries an explicit route.
    final isWorker =
        ref.read(authControllerProvider).stage == AppStage.workerApp;
    ctx.go(isWorker ? '/w/jobs' : '/bookings');
  }

  @override
  void dispose() {
    unawaited(_tapSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'KaamWala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
