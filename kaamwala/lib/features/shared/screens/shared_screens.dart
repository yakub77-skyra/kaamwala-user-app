/// Shared screens - Settings/Profile (S2) + Notifications (S1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: const Icon(Icons.person)),
              const SizedBox(width: KwSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.profile?.name.isEmpty ?? true
                        ? 'User'
                        : auth.profile!.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(auth.profile?.phone ?? '+91 ••••',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: KwColors.muted)),
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
              selected: const {'en'},
              onSelectionChanged: (_) {},
            ),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('🔔 Notifications'),
            trailing: Switch(value: true, onChanged: null),
          ),
          const ListTile(
            leading: Icon(Icons.location_city),
            title: Text('📍 My city'),
            subtitle: Text('Kharadi, Pune'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('📄 Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: KwColors.red),
            title:
                const Text('Sign Out', style: TextStyle(color: KwColors.red)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
          const SizedBox(height: KwSpacing.md),
          Center(
            child: Text('NO role switch. One phone = one role.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: KwColors.muted)),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: const [
          Card(
            margin: EdgeInsets.only(bottom: KwSpacing.md),
            child: ListTile(
              leading: Text('🔔', style: TextStyle(fontSize: 22)),
              title: Text('New job! Fan repair'),
              subtitle: Text('Kharadi • ₹300'),
              trailing: Text('2m'),
            ),
          ),
          Card(
            margin: EdgeInsets.only(bottom: KwSpacing.md),
            child: ListTile(
              leading: Text('💰', style: TextStyle(fontSize: 22)),
              title: Text('₹270 sent to your UPI'),
              subtitle: Text('Razorpay X payout'),
              trailing: Text('1h'),
            ),
          ),
        ],
      ),
    );
  }
}
