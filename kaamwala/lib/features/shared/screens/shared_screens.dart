/// Shared screens - Profile & Settings (S2).
///
/// The notification center moved to
/// `features/notifications/screens/notifications_screen.dart` (Phase 3).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/features/admin/providers/admin_provider.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';
import 'package:kaamwala/features/shared/providers/shared_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/services/location_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((i) => mounted ? setState(() => _version = i.version) : null)
        .catchError((_) {});
  }

  Future<void> _changeAvatar() async {
    if (_uploadingAvatar) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final ok = await ref
          .read(authControllerProvider.notifier)
          .updateAvatar(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Photo updated' : 'Could not update photo. Try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _editProfile() async {
    final auth = ref.read(authControllerProvider);
    final nameCtrl = TextEditingController(text: auth.profile?.name ?? '');
    final cityCtrl = TextEditingController(text: auth.profile?.city ?? '');
    var locatingCity = false;
    Future<void> detectCity(StateSetter setSheetState) async {
      if (locatingCity) return;
      setSheetState(() => locatingCity = true);
      final res = await LocationService.detectCity();
      if (!mounted) return;
      setSheetState(() => locatingCity = false);
      switch (res) {
        case Success(:final data):
          cityCtrl.text = data;
        case Error(:final failure):
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: KwSpacing.xl,
            right: KwSpacing.xl,
            top: KwSpacing.sm,
            bottom: MediaQuery.viewInsetsOf(context).bottom + KwSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.lg),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: KwSpacing.md),
              TextField(
                controller: cityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'City',
                  helperText: 'Tap the pin to detect automatically',
                  suffixIcon: IconButton(
                    onPressed: () => detectCity(setSheetState),
                    tooltip: 'Use my current location',
                    icon: locatingCity
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final err = await ref
                        .read(authControllerProvider.notifier)
                        .updateDetails(
                          name: nameCtrl.text,
                          city: cityCtrl.text,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context, err == null);
                    if (err != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to verify your phone number again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: KwColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(onboardingControllerProvider.notifier).reset();
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    // signOut clears the profile -> router sends an unnamed user to /role,
    // but we also reset onboarding so a fresh user lands on choose-role.
    context.go('/role');
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            KwSpacing.xl,
            0,
            KwSpacing.xl,
            KwSpacing.xl,
          ),
          children: [
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: KwSpacing.md),
            ...const [
              (
                'How do I book a worker?',
                'Pick a category, choose a worker, describe the job and pay the â‚¹20 booking fee. The worker accepts and arrives at your address.',
              ),
              (
                'Is the â‚¹20 fee refundable?',
                'Yes - cancel while the booking is still pending for a full refund to your original payment method.',
              ),
              (
                'When is the worker paid?',
                'After you confirm the work is done. You keep 100% control - no auto-charge.',
              ),
              (
                'Are workers verified?',
                'Every worker uploads an Aadhar card that our team manually verifies before they can receive jobs.',
              ),
            ].map(
              (qa) => (ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.help_outline_rounded,
                  color: KwColors.primary,
                ),
                title: Text(
                  qa.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(qa.$2, style: const TextStyle(height: 1.4)),
              )),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Contact support'),
              subtitle: const Text(
                'support@kaamwala.com â€¢ WhatsApp +91-90000-00000',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'KaamWala respects your privacy.\n\n'
            'â€¢ We store your phone number and name to run bookings.\n'
            'â€¢ Your Aadhar documents are stored in an encrypted private '
            'bucket. Only our verification team can view them - never '
            'customers or workers.\n'
            'â€¢ Your work photos are public so customers can find you.\n'
            'â€¢ Chat messages are visible only to you and the person you '
            'booked / who booked you.\n'
            'â€¢ We never sell your data.\n\n'
            'Questions? support@kaamwala.com',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final prefs = ref.watch(prefsProvider);
    final name = auth.profile?.name;
    final phone = auth.profile?.phone;
    final city = auth.profile?.city;
    final photoUrl = auth.profile?.photoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          // ---------- identity card ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KwSpacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Stack(
                      children: [
                        WorkerAvatar(url: photoUrl, radius: 30),
                        if (_uploadingAvatar)
                          const Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: KwColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KwSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == null || name.isEmpty ? 'User' : name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          phone ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: KwColors.muted),
                        ),
                        if (city != null && city.isNotEmpty)
                          Text(
                            '$city â€¢ ${auth.stage == AppStage.workerApp ? 'Worker' : 'Customer'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: KwColors.muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KwSpacing.lg),

          // ---------- preferences ----------
          SectionHeader(title: 'Preferences'),
          const SizedBox(height: KwSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: prefs.notificationsOn,
                    onChanged: (v) =>
                        ref.read(prefsProvider.notifier).setNotificationsOn(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KwSpacing.lg),

          // ---------- support ----------
          SectionHeader(title: 'Support & legal'),
          const SizedBox(height: KwSpacing.sm),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final isAdmin = ref.watch(isAdminProvider).value ?? false;
                    if (!isAdmin) return const SizedBox.shrink();
                    return ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: KwColors.primary,
                      ),
                      title: const Text(
                        'Verification Queue',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Admin: approve worker profiles'),
                      onTap: () async {
                        await context.push('/admin');
                        ref.invalidate(isAdminProvider);
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & Support'),
                  subtitle: const Text('FAQs and contact'),
                  onTap: _showHelp,
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: _showPrivacyPolicy,
                ),
              ],
            ),
          ),
          const SizedBox(height: KwSpacing.lg),

          // ---------- danger ----------
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(foregroundColor: KwColors.red),
              onPressed: _signOut,
            ),
          ),
          const SizedBox(height: KwSpacing.lg),
          Center(
            child: Column(
              children: [
                Text(
                  'One phone = one role',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
                if (_version.isNotEmpty)
                  Text(
                    'KaamWala v$_version',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: KwColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
