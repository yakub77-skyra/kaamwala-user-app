/// Rate & Review (Phase 3 C12) - stars + text + quick tags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

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

  static const _quickTags = ['On time', 'Polite', 'Neat work', 'Fair price'];

  String get _starWord => switch (_stars) {
    1 => 'Poor 😞',
    2 => 'Not great',
    3 => 'Okay',
    4 => 'Good!',
    5 => 'Excellent! 🎉',
    _ => '',
  };

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Booking b) async {
    if (_busy || _stars == 0) return;
    setState(() => _busy = true);
    final result = await ref
        .read(reviewsRepoProvider)
        .submitReview(
          Review(
            id: '',
            bookingId: widget.bookingId,
            workerId: b.workerId,
            clientId: SupabaseService.currentUserId ?? b.clientId,
            rating: _stars,
            text: _textCtrl.text.trim(),
            tags: _tags.toList(),
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for rating your worker 🎉')),
        );
        // Detail screen is below in the stack; drop back to the bookings tab.
        if (context.canPop()) {
          context.pop();
        }
        context.go('/bookings');
      case Error(:final failure):
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final b = bookings.value
        ?.where((x) => x.id == widget.bookingId)
        .firstOrNull;
    final name = b?.workerName ?? 'your worker';

    return Scaffold(
      appBar: AppBar(title: const Text('Rate your worker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Center(child: WorkerAvatar(url: b?.workerPhoto, radius: 34)),
            const SizedBox(height: KwSpacing.md),
            Center(
              child: Text(
                'How was $name?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: KwSpacing.xs),
            Center(
              child: Text(
                'Your rating helps neighbours pick the right person',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KwColors.muted),
              ),
            ),
            const SizedBox(height: KwSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 42,
                    splashColor: Colors.transparent,
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: KwColors.gold,
                      shadows: i <= _stars
                          ? const [
                              Shadow(color: Color(0x33D97706), blurRadius: 12),
                            ]
                          : null,
                    ),
                  ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _starWord,
                key: ValueKey(_stars),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _stars >= 4 ? KwColors.green : KwColors.gold,
                ),
              ),
            ),
            const SizedBox(height: KwSpacing.lg),
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
                    showCheckmark: false,
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rate_review_rounded, size: 19),
              label: Text(_busy ? 'Submitting…' : 'Submit Review'),
              onPressed: _stars == 0 || _busy || b == null
                  ? null
                  : () => _submit(b),
            ),
          ],
        ),
      ),
    );
  }
}

typedef BookingLike = dynamic;
