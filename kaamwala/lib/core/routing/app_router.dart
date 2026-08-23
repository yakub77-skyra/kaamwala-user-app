/// go_router navigation map - Phase 3 section 6.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/screens/login_screen.dart';
import 'package:kaamwala/features/auth/screens/onboarding_screen.dart';
import 'package:kaamwala/features/auth/screens/otp_screen.dart';
import 'package:kaamwala/features/auth/screens/role_selection_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      switch (auth.stage) {
        case AppStage.loading:
          return '/';
        case AppStage.onboarding:
          return loc == '/onboarding' ? null : '/onboarding';
        case AppStage.login:
          if (loc.startsWith('/login')) return null;
          return '/login';
        case AppStage.roleSelection:
          return loc == '/role' ? null : '/role';
        case AppStage.clientApp:
          if (loc == '/' || loc.startsWith('/login') || loc == '/role' || loc == '/onboarding' || loc.startsWith('/w/')) {
            return '/home';
          }
          return null;
        case AppStage.workerApp:
          if (loc == '/' || loc.startsWith('/login') || loc == '/role' || loc == '/onboarding' || !loc.startsWith('/w/')) {
            return '/w/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/login/otp', builder: (_, s) => OtpScreen(phone: s.extra as String?)),
      GoRoute(path: '/role', builder: (_, _) => const RoleSelectionScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),

      // CLIENT
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, _) => const WorkerListScreen()),
          GoRoute(path: '/bookings', builder: (_, _) => const MyBookingsScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/worker/:id', builder: (_, s) => WorkerProfileScreen(workerId: s.pathParameters['id']!)),
      GoRoute(path: '/book/:workerId', builder: (_, s) => BookingScreen(workerId: s.pathParameters['workerId']!)),
      GoRoute(path: '/payment/:bookingId', builder: (_, s) => PaymentScreen(bookingId: s.pathParameters['bookingId']!)),
      GoRoute(path: '/booking/:id', builder: (_, s) => BookingDetailScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/chat/:bookingId', builder: (_, s) => ChatScreen(bookingId: s.pathParameters['bookingId']!)),
      GoRoute(path: '/rate/:bookingId', builder: (_, s) => RateReviewScreen(bookingId: s.pathParameters['bookingId']!)),

      // WORKER (/w/* requires worker role - guard enforced by redirect above)
      ShellRoute(
        builder: (context, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(path: '/w/home', builder: (_, _) => const WorkerDashboardScreen()),
          GoRoute(path: '/w/earnings', builder: (_, _) => const EarningsScreen()),
          GoRoute(path: '/w/profile', builder: (_, _) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/w/register', builder: (_, _) => const WorkerRegisterScreen()),
      GoRoute(path: '/w/review', builder: (_, _) => const UnderReviewScreen()),
      GoRoute(path: '/w/jobs', builder: (_, _) => const JobRequestsScreen()),
      GoRoute(path: '/w/job/:id', builder: (_, s) => JobDetailScreen(jobId: s.pathParameters['id'])),
      GoRoute(path: '/w/active/:id', builder: (_, s) => ActiveJobScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/w/payment-setup', builder: (_, _) => const PaymentSetupScreen()),
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
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // firstRun=true -> onboarding; else login (session restore inside).
      await ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🔧', style: TextStyle(fontSize: 72)),
            SizedBox(height: 12),
            Text('KaamWala', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            Text('"काम वाला"', style: TextStyle(color: Color(0xFF7A7A9D))),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFF6B35)),
          ],
        ),
      ),
    );
  }
}

/// Client bottom-nav shell: Home / Search / My Bookings / Profile.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.child});
  final Widget child;

  static int _index(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/bookings')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(loc),
        onDestinationSelected: (i) =>
            context.go(['/', '/', '/', '/', '/'][i] == '/'
                ? ['/home', '/search', '/bookings', '/profile'][i]
                : '/home'),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Worker bottom-nav shell: होम / कमाई / प्रोफ़ाइल.
class WorkerShell extends StatelessWidget {
  const WorkerShell({super.key, required this.child});
  final Widget child;

  static int _index(String loc) {
    if (loc.startsWith('/w/earnings')) return 1;
    if (loc.startsWith('/w/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(loc),
        onDestinationSelected: (i) =>
            context.go(['/w/home', '/w/earnings', '/w/profile'][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'होम'),
          NavigationDestination(icon: Icon(Icons.currency_rupee_outlined), label: 'कमाई'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'प्रोफ़ाइल'),
        ],
      ),
    );
  }
}
