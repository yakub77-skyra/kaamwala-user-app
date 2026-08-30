/// Role selection / profile setup.
///
/// Dual-purpose route `/role`:
///  - PRE-OTP  (onboarding role not chosen yet): "I need a service" vs
///    "I want to work". This is the FIRST step of the auth flow.
///  - POST-OTP (onboarding role chosen, profile unnamed): captures name +
///    city to create the user's profile, locking the role server-side.
///    Workers are then sent to the worker registration screen to add their
///    trade details, documents and work photos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/config/app_flavor.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';
import 'package:kaamwala/services/location_service.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key, this.workerOnly = false});

  /// Partner flavor: only the worker option is shown pre-OTP.
  final bool workerOnly;

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _locating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with any existing profile data (returning session w/ partial profile).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(authControllerProvider).profile;
      if (profile != null) {
        if (profile.name.isNotEmpty && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = profile.name;
        }
        if (profile.city.isNotEmpty && _cityCtrl.text.isEmpty) {
          _cityCtrl.text = profile.city;
        }
      }
    });
  }

  Future<void> _detectCity() async {
    if (_locating || _busy) return;
    setState(() => _locating = true);
    final res = await LocationService.detectCity();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (res) {
      case Success(:final data):
        _cityCtrl.text = data;
      case Error(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final onboarding = ref.read(onboardingControllerProvider);
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .finishRoleSelection(
          name: _nameCtrl.text.trim(),
          asWorker: onboarding.asWorker,
          city: _cityCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      if (onboarding.asWorker) {
        // Workers proceed to trade details + documents + work photos.
        context.go('/w/register');
      }
      // Customers: finishRoleSelection already set clientApp -> router -> /home.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Try again.'),
        ),
      );
    }
  }

  void _chooseRole(bool asWorker) {
    final flavor = ref.read(flavorProvider);
    ref
        .read(onboardingControllerProvider.notifier)
        .selectRole(asWorker ? OnboardingRole.worker : OnboardingRole.client);
    ref.read(authControllerProvider.notifier).selectRole(asWorker);

    // Respect the two-app split: a role that doesn't match this binary lands
    // on the wrong-app screen (no dead-ends).
    final matchesFlavor = asWorker
        ? flavor == AppFlavor.partner
        : flavor == AppFlavor.customer;
    if (!matchesFlavor) {
      context.go('/wrong-app');
    } else {
      context.go('/login/phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingControllerProvider);
    final showChooseRole = onboarding.role == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showChooseRole ? 'Welcome to KaamWala' : 'Set up your profile',
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KwSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: showChooseRole
                  ? _buildChooseRole(context)
                  : _buildProfileForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChooseRole(BuildContext context) {
    final provider = ref.watch(flavorProvider);
    final isPartner = provider == AppFlavor.partner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: KwSpacing.sm),
        Text(
          'How would you like to use KaamWala?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KwSpacing.xs),
        Text(
          'Choose the experience that fits you best',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: KwColors.muted),
        ),
        const SizedBox(height: KwSpacing.xxl),
        _RoleCard(
          icon: Icons.home_repair_service_rounded,
          title: 'I need a service',
          subtitle: 'Find trusted workers near you',
          description: 'Book plumbers, electricians,\npainters & carpenters.',
          onTap: () => _chooseRole(false),
          color: KwColors.primary,
        ),
        const SizedBox(height: KwSpacing.md),
        _RoleCard(
          icon: Icons.work_outline_rounded,
          title: 'I want to work',
          subtitle: 'Create your worker profile & get jobs',
          description: 'Verified professionals.\nKeep 90% of every job.',
          onTap: () => _chooseRole(true),
          color: KwColors.green,
        ),
        if (!isPartner) ...[
          const SizedBox(height: KwSpacing.lg),
          Text(
            'One phone number = one role. Your role is locked forever\nso customers and workers stay separate.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KwColors.muted, height: 1.4),
          ),
        ],
        const SizedBox(height: KwSpacing.xl),
        Text(
          'Your number is used only for login and booking updates. No spam.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: KwColors.muted),
        ),
      ],
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    final onboarding = ref.read(onboardingControllerProvider);
    final isWorker = onboarding.asWorker;
    final phone =
        ref.read(authControllerProvider).profile?.phone ??
        ref.read(onboardingControllerProvider).phoneE164 ??
        '';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KwSpacing.sm),
          Text(
            'Finish setting up your profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: KwSpacing.xs),
          Text(
            isWorker
                ? 'Your name and city help customers trust you.'
                : 'Just a couple details and you can start booking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: KwColors.muted),
          ),
          const SizedBox(height: KwSpacing.xl),

          if (phone.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.phone_rounded, size: 18, color: KwColors.muted),
                const SizedBox(width: KwSpacing.sm),
                Text(
                  'Verified: $phone',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KwColors.muted),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.lg),
          ],

          Text('Your full name', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: KwSpacing.sm),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Rohit Sharma'),
            validator: (v) => (v?.trim().length ?? 0) >= 3
                ? null
                : 'Enter your full name (min 3 chars)',
          ),
          const SizedBox(height: KwSpacing.lg),

          Text('Your city', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: KwSpacing.sm),
          TextFormField(
            controller: _cityCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Pune, Mumbai, Delhi',
              prefixIcon: const Icon(Icons.location_city_rounded),
              suffixIcon: IconButton(
                onPressed: _locate,
                tooltip: 'Use my current location',
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
            validator: (v) => (v?.trim().length ?? 0) >= 2
                ? null
                : 'Enter your city (min 2 chars)',
          ),
          const SizedBox(height: KwSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _locate,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text('Use my current location'),
            ),
          ),
          const SizedBox(height: KwSpacing.lg),

          KwButton(
            label: isWorker ? 'Continue to registration' : 'Start KaamWala',
            onPressed: _busy ? null : _submitProfile,
            icon: isWorker
                ? Icons.arrow_forward_rounded
                : Icons.rocket_launch_rounded,
            loading: _busy,
          ),
          const SizedBox(height: KwSpacing.sm),
          if (phone.isNotEmpty)
            TextButton(
              onPressed: () => context.go('/login/phone'),
              child: const Text('Change number'),
            ),
        ],
      ),
    );
  }

  void _locate() {
    if (_locating) return;
    _detectCity();
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KwRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(KwSpacing.xl),
        decoration: BoxDecoration(
          color: KwColors.surface,
          borderRadius: BorderRadius.circular(KwRadius.lg),
          border: Border.all(color: KwColors.line),
          boxShadow: KwShadows.s1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(KwRadius.md),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: KwSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: KwSpacing.sm),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: KwColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: KwColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
