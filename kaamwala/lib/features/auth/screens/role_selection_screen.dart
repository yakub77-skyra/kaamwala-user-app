/// Role selection - ONE TIME, LOCKED (Phase 3 C4 wireframe).
/// No role toggle anywhere in v2 (Phase 2 section 2 role rules).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _nameCtrl = TextEditingController();
  bool _worker = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(bool asWorker) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first')),
      );
      return;
    }
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).finishRoleSelection(
          name: _nameCtrl.text.trim(),
          asWorker: asWorker,
          city: '',
        );
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome! 🙏')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Text('Your name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'e.g. Rohit Sharma'),
            ),
            const SizedBox(height: KwSpacing.md),
            Text('How will you use KaamWala?',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.md),
            _roleCard(
              emoji: '🏠',
              title: 'I need a worker',
              body: 'Book plumbers, electricians & more',
              selected: !_worker,
              onTap: () => setState(() => _worker = false),
            ),
            const SizedBox(height: KwSpacing.md),
            _roleCard(
              emoji: '🔧',
              title: 'I am a worker',
              body: 'Get jobs near you & earn money daily',
              selected: _worker,
              onTap: () => setState(() => _worker = true),
            ),
            const SizedBox(height: KwSpacing.lg),
            ElevatedButton(
              onPressed: _busy ? null : () => _submit(_worker),
              child: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              'This choice is FINAL. One phone number = one role.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required String emoji,
    required String title,
    required String body,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KwRadius.card),
        side: BorderSide(
            color: selected ? KwColors.primary : Colors.transparent,
            width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KwRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: KwSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: KwColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
