/// Rate & Review (Phase 3 C12) - stars + text + quick tags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/models/review.dart';

class RateReviewScreen extends ConsumerStatefulWidget {
  const RateReviewScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends ConsumerState<RateReviewScreen> {
  int _stars = 0;
  final _textCtrl = TextEditingController();
  final Set<String> _tags = {};
  bool _busy = false;

  static const _quickTags = ['On time', 'Polite', 'Neat', 'Fair price'];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _stars == 0) return;
    setState(() => _busy = true);
    await ref
        .read(reviewsRepoProvider)
        .submitReview(
          Review(
            id: '',
            bookingId: widget.bookingId,
            workerId: 'worker-id',
            clientId: 'client-id',
            rating: _stars,
            text: _textCtrl.text.trim(),
            tags: _tags.toList(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Thanks for rating your worker!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your worker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                child: const Icon(Icons.person, size: 32),
              ),
            ),
            const SizedBox(height: KwSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star : Icons.star_border,
                      color: KwColors.gold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            TextFormField(
              controller: _textCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(hintText: 'How was the work?'),
            ),
            const SizedBox(height: KwSpacing.sm),
            Wrap(
              spacing: KwSpacing.sm,
              runSpacing: KwSpacing.sm,
              children: [
                for (final t in _quickTags)
                  FilterChip(
                    label: Text(t),
                    selected: _tags.contains(t),
                    onSelected: (_) => setState(
                      () => _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KwSpacing.xl),
            ElevatedButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: const Text('Submit Review'),
              onPressed: _stars == 0 || _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
