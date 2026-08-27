/// Shared app bootstrap for both flavors (customer + partner).
///
/// Entry points:
///  - lib/main.dart         -> bootstrap(AppFlavor.customer)
///  - lib/main_partner.dart -> bootstrap(AppFlavor.partner)
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/env/env.dart';
import 'package:kaamwala/core/routing/app_router.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/shared/providers/connectivity_provider.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/fcm_service.dart';
import 'package:kaamwala/services/supabase_service.dart';
import 'package:kaamwala/l10n/app_localizations.dart';

Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Release builds must never silently fall back to demo mode - fail loudly.
  if (kReleaseMode && !Env.isConfigured) {
    runApp(const _MisconfiguredApp());
    return;
  }
  await SupabaseService.init();
  // Arms Crashlytics global handlers as early as possible (no-op w/o Firebase).
  await AnalyticsService.ensureInitialized();
  unawaited(AnalyticsService.logEvent('app_open', {'flavor': flavor.name}));
  runApp(
    ProviderScope(
      overrides: [flavorProvider.overrideWithValue(flavor)],
      child: KaamWalaApp(key: ValueKey(flavor)),
    ),
  );
}

/// Shown instead of the app when a release build ships without KW_* env vars,
/// so a misconfigured build is obvious instead of quietly running demo data.
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Build configuration error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This build was compiled without backend configuration '
                  '(KW_SUPABASE_URL / KW_SUPABASE_ANON_KEY missing). '
                  'Please rebuild with --dart-define-from-file=.env.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    // A push landing in the wrong binary is caught by the flavor gate in
    // appRedirect and lands on /wrong-app.
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
    final flavor = ref.watch(flavorProvider);
    return MaterialApp.router(
      title: flavor.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => _OfflineBoundary(child: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
    );
  }
}

/// Shows a persistent banner above the app while offline.
class _OfflineBoundary extends ConsumerWidget {
  const _OfflineBoundary({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    final content = child ?? const SizedBox.shrink();
    if (online) return content;
    return Column(
      children: [
        Material(
          color: KwColors.red,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
