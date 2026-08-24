/// Single-screen booking form (Phase 3 C8) - NO wizard, NO fee tiers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.workerId});
  final String workerId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController(text: 'A-402, Kharadi, Pune');
  DateTime _date = DateTime.now();
  String _slot = '10-12';
  bool _busy = false;

  static const _slots = ['8-10', '10-12', '12-14', '14-16', '16-18', '18-20'];

  @override
  void dispose() {
    _descCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_descCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the work (min 10 chars)'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    // Demo estimates; production values come from server config.
    final bookingResult = await ref
        .read(bookingsRepoProvider)
        .create(
          clientId: '00000000-0000-0000-0000-000000000000',
          workerId: widget.workerId,
          category: ref.read(selectedCategoryProvider),
          description: _descCtrl.text.trim(),
          serviceDate: _date,
          timeSlot: _slot,
          address: _addrCtrl.text.trim(),
          estimateMin: 300,
          estimateMax: 800,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (bookingResult) {
      case Success(:final data):
        context.go('/payment/${data.id}');
      case Error(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Worker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.lg),
          children: [
            Text(
              'What work do you need?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: KwSpacing.sm),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Fan is not working...',
              ),
            ),
            const SizedBox(height: KwSpacing.md),
            Text('When?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('dd MMM').format(_date)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _slot,
                    items: [
                      for (final s in _slots)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() => _slot = v ?? _slot),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            Text('Where?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.sm),
            TextFormField(
              controller: _addrCtrl,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const Divider(height: KwSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job estimate',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Text(
                  '₹300 – ₹800',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking fee',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '₹${AppConstants.bookingFeeRupees}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.lg),
            ElevatedButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.currency_rupee),
              label: Text('Pay ₹${AppConstants.bookingFeeRupees} & Book'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
