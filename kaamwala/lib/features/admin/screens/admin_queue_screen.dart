/// Admin verification queue (Phase 3 section 5.3) - approve/reject workers
/// whose Aadhar is under review. Only visible to uids listed in
/// platform_config.admin_user_ids.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_empty_state.dart';
import 'package:kaamwala/features/admin/providers/admin_provider.dart';

class AdminQueueScreen extends ConsumerWidget {
  const AdminQueueScreen({super.key});

  Future<String?> _askRejectReason(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'e.g. Aadhar photo is blurred, please re-upload',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Queue')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const KwEmptyState(
          illustration: KwIllustration.offline,
          title: 'Could not load queue',
          subtitle: 'Pull down to retry.',
        ),
        data: (s) {
          if (!s.isAdmin) {
            return const KwEmptyState(
              illustration: KwIllustration.review,
              title: 'Admins only',
              subtitle: 'Your account is not in the admin list (platform_config.admin_user_ids).',
            );
          }
          if (s.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  await ref.read(adminProvider.notifier).refresh(),
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  KwEmptyState(
                    illustration: KwIllustration.success,
                    title: 'Queue clear!',
                    subtitle: 'No worker profiles waiting for review.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                await ref.read(adminProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(KwSpacing.lg),
              itemCount: s.queue.length,
              separatorBuilder: (_, _) => const SizedBox(height: KwSpacing.md),
              itemBuilder: (context, i) {
                final w = s.queue[i];
                final busy = s.busyWorkerId == w.id;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(KwSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: (w.photoUrl?.isNotEmpty ?? false)
                                  ? CachedNetworkImageProvider(w.photoUrl!)
                                  : null,
                              child: (w.photoUrl?.isNotEmpty ?? false)
                                  ? null
                                  : const Icon(Icons.person),
                            ),
                            const SizedBox(width: KwSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.name.isEmpty ? 'Unnamed worker' : w.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${w.category.labelEn} • ${w.area.isEmpty ? w.city : w.area} • ₹${w.priceMin.toStringAsFixed(0)}+',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: KwColors.muted),
                                  ),
                                  if (w.bio.isNotEmpty)
                                    Text(
                                      w.bio,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KwSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.close, size: 18),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: KwColors.red,
                                ),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final reason = await _askRejectReason(
                                          context,
                                        );
                                        if (reason == null ||
                                            !context.mounted) {
                                          return;
                                        }
                                        final err = await ref
                                            .read(adminProvider.notifier)
                                            .decide(
                                              w.id,
                                              approve: false,
                                              reason: reason,
                                            );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              err ??
                                                  'Rejected - worker notified',
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(width: KwSpacing.md),
                            Expanded(
                              child: FilledButton.icon(
                                icon: busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: const Text('Approve'),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final err = await ref
                                            .read(adminProvider.notifier)
                                            .decide(w.id, approve: true);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  err ?? 'Approved - push sent to worker',
                                                ),
                                              ),
                                            );
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
