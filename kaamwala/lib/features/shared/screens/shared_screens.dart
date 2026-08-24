/// Shared screens - Profile & Settings (S2) + Notifications (S1).
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
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
              title: const Text('📷 Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('🖼️ Gallery'),
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
            ok ? '✅ Photo updated' : 'Could not update photo. Try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Privacy Policy'),
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
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: hasPhoto
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: hasPhoto ? null : const Icon(Icons.person),
                    ),
                    if (_uploadingAvatar)
                      const Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      const Positioned(
                        right: -2,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: KwColors.primary,
                          child: Icon(
                            Icons.edit,
                            size: 12,
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
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      phone ?? '',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: KwSpacing.xxl),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('🌐 Language'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hi', label: Text('हिंदी')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {prefs.language},
              onSelectionChanged: (v) =>
                  ref.read(prefsProvider.notifier).setLanguage(v.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('🔔 Notifications'),
            trailing: Switch(
              value: prefs.notificationsOn,
              onChanged: (v) =>
                  ref.read(prefsProvider.notifier).setNotificationsOn(v),
            ),
          ),
          if (city != null && city.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('📍 My city'),
              subtitle: Text(city),
            ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('📄 Privacy Policy'),
            onTap: _showPrivacyPolicy,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('🛟 Help & Support'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp +91-XXXXXXXXXX | support@kaamwala.com'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: KwColors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: KwColors.red),
            ),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
          const SizedBox(height: KwSpacing.md),
          Center(
            child: Column(
              children: [
                Text(
                  'NO role switch. One phone = one role.',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
                if (_version.isNotEmpty)
                  Text(
                    'v$_version',
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
                  children: [
                    const SizedBox(height: 160),
                    const EmptyState(
                      emoji: '🔔',
                      title: 'No notifications yet',
                      subtitle: 'Booking updates and payment alerts will appear here.',
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
                        leading: Icon(
                          _iconFor(n.type.name),
                          color: n.isRead ? KwColors.muted : KwColors.primary,
                        ),
                        title: Text(
                          n.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
