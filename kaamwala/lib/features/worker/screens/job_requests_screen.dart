/// Job Requests list (Phase 3 W4) - only status=pending assigned to me.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = [
      (emoji: '🌀', title: 'Fan repair', meta: 'Rohit • Kharadi • 1.2 km\nToday 10 AM   ~₹300'),
      (emoji: '💡', title: 'Wiring check', meta: 'Priya • Viman Nagar • 3 km\nTomorrow 2 PM ~₹500'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('नए काम (New Jobs)')),
      body: demo.isEmpty
          ? const EmptyState(emoji: '📭', title: 'No new jobs right now')
          : ListView(
              padding: const EdgeInsets.all(KwSpacing.lg),
              children: [
                for (final j in demo)
                  Card(
                    margin: const EdgeInsets.only(bottom: KwSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(KwSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(j.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: KwSpacing.md),
                            Expanded(
                              child: Text(j.title,
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(j.meta,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: KwColors.muted)),
                          const SizedBox(height: KwSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style:
                                      OutlinedButton.styleFrom(foregroundColor: KwColors.red),
                                  onPressed: () {},
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: KwSpacing.md),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accept'),
                                  onPressed: () => context.go('/w/active/new'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
