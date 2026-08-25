/// Shared screens - Profile & Settings (S2) + Notifications (S1).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/admin/providers/admin_provider.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/shared/providers/shared_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: KwSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final err = await ref
                      .read(authControllerProvider.notifier)
                      .updateDetails(name: nameCtrl.text, city: cityCtrl.text);
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
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated ✅')));
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
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/login');
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
                'Pick a category, choose a worker, describe the job and pay the ₹20 booking fee. The worker accepts and arrives at your address.',
              ),
              (
                'Is the ₹20 fee refundable?',
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
                'support@kaamwala.com • WhatsApp +91-90000-00000',
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
            '• We store your phone number and name to run bookings.\n'
            '• Your Aadhar documents are stored in an encrypted private '
            'bucket. Only our verification team can view them - never '
            'customers or workers.\n'
            '• Your work photos are public so customers can find you.\n'
            '• Chat messages are visible only to you and the person you '
            'booked / who booked you.\n'
            '• We never sell your data.\n\n'
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
                            '$city • ${auth.stage == AppStage.workerApp ? 'Worker' : 'Customer'}',
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
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Language'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'hi', label: Text('हिंदी')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {prefs.language},
                    onSelectionChanged: (v) =>
                        ref.read(prefsProvider.notifier).setLanguage(v.first),
                    showSelectedIcon: false,
                  ),
                ),
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

/// S1 - live feed from the notifications table.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) => switch (type) {
    'booking' => Icons.handyman_outlined,
    'payment' => Icons.currency_rupee_outlined,
    _ => Icons.notifications_outlined,
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
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          async.maybeWhen(
            data: (s) => s.unread > 0
                ? TextButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'Could not load notifications',
          subtitle: 'Pull down to retry.',
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () async =>
              await ref.read(notificationsProvider.notifier).refresh(),
          child: state.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .7,
                      child: const EmptyState(
                        emoji: '🔔',
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
                            _iconFor(n.type.name),
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
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
