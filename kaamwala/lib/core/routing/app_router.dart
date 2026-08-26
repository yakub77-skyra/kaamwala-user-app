/// go_router navigation map - Phase 3 section 6.
///
/// Tab shells use StatefulShellRoute.indexedStack so every tab keeps its
/// own navigator + scroll state: switching tabs and coming back restores
/// exactly where you were, and system back pops inside the tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/admin/screens/admin_queue_screen.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/screens/login_screen.dart';
import 'package:kaamwala/features/auth/screens/onboarding_screen.dart';
import 'package:kaamwala/features/auth/screens/otp_screen.dart';
import 'package:kaamwala/features/auth/screens/role_selection_screen.dart';
import 'package:kaamwala/features/auth/screens/wrong_app_screen.dart';
import 'package:kaamwala/features/client/screens/booking_screen.dart';
import 'package:kaamwala/features/client/screens/chat_screen.dart';
import 'package:kaamwala/features/client/screens/home_screen.dart';
import 'package:kaamwala/features/client/screens/my_bookings_screen.dart';
import 'package:kaamwala/features/client/screens/payment_screen.dart';
import 'package:kaamwala/features/client/screens/rate_review_screen.dart';
import 'package:kaamwala/features/client/screens/worker_list_screen.dart';
import 'package:kaamwala/features/client/screens/worker_profile_screen.dart';
import 'package:kaamwala/features/shared/screens/shared_screens.dart';
import 'package:kaamwala/features/worker/screens/job_requests_screen.dart';
import 'package:kaamwala/features/worker/screens/worker_register_screen.dart';
import 'package:kaamwala/features/worker/screens/worker_screens.dart';

/// Global navigator key - lets FCM taps deep-link from outside widgets.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pure routing policy per auth stage (table-driven tested in
/// `test/router_redirect_test.dart`). Returns null to allow [loc], else the
/// location to redirect to.
///
/// [flavor] gates the two binaries against each other: the customer app
/// never serves a worker account and vice versa - both land on /wrong-app.
String? appRedirect(
  AppStage stage,
  String loc, {
  AppFlavor flavor = AppFlavor.customer,
}) {
  final wrongRoleForFlavor = switch (flavor) {
    AppFlavor.customer => stage == AppStage.workerApp,
    AppFlavor.partner => stage == AppStage.clientApp,
  };
  if (wrongRoleForFlavor) {
    return loc == '/wrong-app' ? null : '/wrong-app';
  }
  switch (stage) {
    case AppStage.loading:
    case AppStage.startupError:
      return '/';
    case AppStage.onboarding:
      return loc == '/onboarding' ? null : '/onboarding';
    case AppStage.login:
      if (loc.startsWith('/login')) return null;
      return '/login';
    case AppStage.roleSelection:
      return loc == '/role' ? null : '/role';
    case AppStage.clientApp:
      if (loc == '/' ||
          loc.startsWith('/login') ||
          loc == '/role' ||
          loc == '/onboarding' ||
          loc.startsWith('/w/')) {
        return '/home';
      }
      return null;
    case AppStage.workerApp:
      if (loc == '/' ||
          loc.startsWith('/login') ||
          loc == '/role' ||
          loc == '/onboarding' ||
          !loc.startsWith('/w/')) {
        return '/w/home';
      }
      return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final flavor = ref.watch(flavorProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) =>
        appRedirect(auth.stage, state.matchedLocation, flavor: flavor),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/login/otp',
        builder: (_, s) => OtpScreen(phone: s.extra as String?),
      ),
      GoRoute(
        path: '/role',
        builder: (_, _) =>
            RoleSelectionScreen(workerOnly: flavor == AppFlavor.partner),
      ),
      GoRoute(path: '/wrong-app', builder: (_, _) => const WrongAppScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminQueueScreen()),

      // CLIENT - indexedStack keeps each tab's state alive
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ClientShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => const WorkerListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (_, _) => const MyBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/worker/:id',
        builder: (_, s) =>
            WorkerProfileScreen(workerId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:workerId',
        builder: (_, s) =>
            BookingScreen(workerId: s.pathParameters['workerId']!),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        builder: (_, s) =>
            PaymentScreen(bookingId: s.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, s) =>
            BookingDetailScreen(bookingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:bookingId',
        builder: (_, s) =>
            ChatScreen(bookingId: s.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/rate/:bookingId',
        builder: (_, s) =>
            RateReviewScreen(bookingId: s.pathParameters['bookingId']!),
      ),

      // WORKER (/w/* requires worker role - guard enforced by redirect above)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => WorkerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/w/home',
                builder: (_, _) => const WorkerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/w/earnings',
                builder: (_, _) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/w/profile',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/w/register',
        builder: (_, _) => const WorkerRegisterScreen(),
      ),
      GoRoute(path: '/w/review', builder: (_, _) => const UnderReviewScreen()),
      GoRoute(path: '/w/jobs', builder: (_, _) => const JobRequestsScreen()),
      GoRoute(
        path: '/w/job/:id',
        builder: (_, s) => JobDetailScreen(jobId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/w/active/:id',
        builder: (_, s) => ActiveJobScreen(bookingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/w/payment-setup',
        builder: (_, _) => const PaymentSetupScreen(),
      ),
    ],
  );
});

/// Splash - checks session then redirects via auth controller (Phase 3 C1).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      // firstRun=true -> onboarding; else login (session restore inside).
      await ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stage = ref.watch(authControllerProvider).stage;
    final flavor = ref.watch(flavorProvider);
    final failed = stage == AppStage.startupError;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: KwColors.brandGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(KwRadius.lg),
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                flavor.appName,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                flavor == AppFlavor.partner
                    ? 'Get jobs near you. Earn every day.'
                    : 'Verified workers. Instant booking.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: .85)),
              ),
              const SizedBox(height: 36),
              if (failed) ...[
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Could not reach the server.\nCheck your internet and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(authControllerProvider.notifier)
                      .restoreSession(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ] else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared scaffold chrome for an indexed-stack tab shell.
/// Back pops within the active tab; tab switches preserve state.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<({IconData icon, IconData selectedIcon, String label})> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      extendBody: false,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          // A second tap on the current tab pops it back to its root.
          initialLocation: i == shell.currentIndex,
        ),
        destinations: [
          for (final it in items)
            NavigationDestination(
              icon: Icon(it.icon),
              selectedIcon: Icon(it.selectedIcon),
              label: it.label,
            ),
        ],
      ),
    );
  }
}

/// Client bottom-nav shell: Home / Search / My Bookings / Profile.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _TabShell(
      shell: shell,
      items: const [
        (
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
        ),
        (
          icon: Icons.search_rounded,
          selectedIcon: Icons.search_rounded,
          label: 'Search',
        ),
        (
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          label: 'Bookings',
        ),
        (
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }
}

/// Worker bottom-nav shell: Home / Earnings / Profile.
class WorkerShell extends StatelessWidget {
  const WorkerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _TabShell(
      shell: shell,
      items: const [
        (
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
        ),
        (
          icon: Icons.currency_rupee_outlined,
          selectedIcon: Icons.currency_rupee_rounded,
          label: 'Earnings',
        ),
        (
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }
}
