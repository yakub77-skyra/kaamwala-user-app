/// Single-screen booking form (Phase 3 C8) - NO wizard, NO fee tiers.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.workerId});
  final String workerId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  String _slot = '10-12';
  bool _busy = false;
  num _estMin = 300;
  num _estMax = 800;

  static const _slots = ['8-10', '10-12', '12-14', '14-16', '16-18', '18-20'];

  @override
  void initState() {
    super.initState();
    // Estimate defaults come from the worker's own price range.
    Future.microtask(() async {
      final res = await ref.read(workersRepoProvider).byId(widget.workerId);
      if (!mounted) return;
      if (res case Success(:final data)) {
        setState(() {
          if (data.priceMin > 0 || data.priceMax > 0) {
            _estMin = data.priceMin;
            _estMax = data.priceMax;
          }
        });
      }
    });
  }

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
    if (!_formKey.currentState!.validate()) return;
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }
    setState(() => _busy = true);
    final bookingResult = await ref
        .read(bookingsRepoProvider)
        .create(
          clientId: uid,
          workerId: widget.workerId,
          category: ref.read(selectedCategoryProvider),
          description: _descCtrl.text.trim(),
          serviceDate: _date,
          timeSlot: _slot,
          address: _addrCtrl.text.trim(),
          estimateMin: _estMin,
          estimateMax: _estMax,
        );
    if (!mounted) return;
    switch (bookingResult) {
      case Success(:final data):
        unawaited(
          AnalyticsService.logEvent('booking_created', {
            'category': ref.read(selectedCategoryProvider).name,
          }),
        );
        context.pushReplacement('/payment/${data.id}');
      case Error(:final failure):
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Worker')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              Text(
                'What work do you need?',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 500,
                validator: (v) => (v ?? '').trim().length < 10
                    ? 'Describe the work in at least 10 characters'
                    : null,
                decoration: const InputDecoration(
                  hintText: 'Fan is not working, sparking noise…',
                  counterStyle: TextStyle(color: KwColors.muted),
                ),
              ),
              const SizedBox(height: KwSpacing.md),
              Text(
                'When?',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 17),
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
                          DropdownMenuItem(value: s, child: Text('$s hrs')),
                      ],
                      onChanged: (v) => setState(() => _slot = v ?? _slot),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.md),
              Text(
                'Where?',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.sm),
              TextFormField(
                controller: _addrCtrl,
                maxLines: 2,
                validator: (v) => (v ?? '').trim().length < 8
                    ? 'Enter your full address'
                    : null,
                decoration: const InputDecoration(
                  hintText: 'Flat / building / street, landmark',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: KwSpacing.lg),

              // ---------- summary ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KwSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Job estimate'),
                          Text(
                            '₹${_estMin.toStringAsFixed(0)} – ₹${_estMax.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: KwSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Booking fee (refundable on cancel)'),
                          Text(
                            '₹${AppConstants.bookingFeeRupees}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: KwSpacing.xs),
                      Text(
                        'Final price is agreed with the worker before work starts.',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KwColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.lg),
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
                    : const Icon(Icons.currency_rupee_rounded, size: 19),
                label: Text(
                  _busy
                      ? 'Creating booking…'
                      : 'Pay ₹${AppConstants.bookingFeeRupees} & Book',
                ),
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: KwSpacing.sm),
              Center(
                child: Text(
                  'Cancel anytime while pending = full refund',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
