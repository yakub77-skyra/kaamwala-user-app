/// Booking creation flow (Phase 2) - structured sections, availability
/// check, slot grid with lead-time validation, robust photo upload and a
/// review-before-pay confirmation step. Booking + order are created in ONE
/// server call (create-order) - the client never computes amounts.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/booking/booking_validator.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/shared/widgets/common_widgets.dart';
import 'package:kaamwala/models/pricing_config.dart';
import 'package:kaamwala/models/worker.dart';
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

  Worker? _worker;
  bool _loadingWorker = true;
  String? _workerError;

  DateTime _date = DateTime.now();
  String _slot = '10-12';
  bool _checkingSlots = false;
  Set<String> _takenSlots = {};

  final List<PickedImage> _photos = [];

  /// One idempotency key per form session - retries reuse the same booking
  /// instead of duplicating it (Task 8.6).
  late final String _idempotencyKey;

  bool _busy = false;
  bool _uploadingPhotos = false;

  static const _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'bk-${DateTime.now().microsecondsSinceEpoch}-'
        '${Random().nextInt(0x7fffffff)}';
    unawaited(AnalyticsService.logEvent('booking_started'));
    _loadWorker();
    _loadTakenSlots();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorker() async {
    final res = await ref.read(workersRepoProvider).byId(widget.workerId);
    if (!mounted) return;
    setState(() {
      _loadingWorker = false;
      switch (res) {
        case Success(:final data):
          _worker = data;
        case Error(:final failure):
          _workerError = failure.message;
      }
    });
  }

  Future<void> _loadTakenSlots() async {
    setState(() => _checkingSlots = true);
    final res = await ref
        .read(bookingsRepoProvider)
        .takenSlots(workerId: widget.workerId, serviceDate: _date);
    if (!mounted) return;
    setState(() {
      _takenSlots = switch (res) {
        Success(:final data) => data,
        Error() => <String>{},
      };
      _checkingSlots = false;
    });
  }

  Future<void> _pickDate() async {
    final pricing =
        ref.read(pricingProvider).valueOrNull ?? PricingConfig.defaults;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: pricing.maxLeadDays)),
    );
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
      _loadTakenSlots();
    }
  }

  void _selectSlot(String slot) {
    if (slot == _slot) return;
    setState(() => _slot = slot);
    unawaited(
      AnalyticsService.logEvent('booking_slot_selected', {'slot': slot}),
    );
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxPhotos photos allowed')),
      );
      return;
    }
    try {
      final picked = await KwImagePicker.instance.pickMulti(
        maxCount: remaining,
      );
      if (picked.isEmpty) return;
      if (!mounted) return;
      setState(() => _photos.addAll(picked));
      unawaited(
        AnalyticsService.logEvent('booking_photo_added', {
          'count': _photos.length,
        }),
      );
    } on ImagePickError catch (e) {
      // Ignore plain cancellations; surface real validation errors.
      if (mounted && e.message != 'No image selected') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick photos. Try again.')),
        );
      }
    }
  }

  /// Step 1: validate + show the confirmation sheet (Task 9).
  Future<void> _reviewBooking() async {
    if (_busy || _uploadingPhotos) return;
    if (!_formKey.currentState!.validate()) return;
    final worker = _worker;
    if (worker == null) return;
    if (!worker.isAvailable || !worker.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This worker is currently unavailable.')),
      );
      return;
    }
    final pricing =
        ref.read(pricingProvider).valueOrNull ?? PricingConfig.defaults;
    final slotCheck = validateSlot(
      _date,
      _slot,
      now: DateTime.now(),
      pricing: pricing,
    );
    if (!slotCheck.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(slotCheck.reason ?? 'Select another slot.')),
      );
      return;
    }
    if (_takenSlots.contains(_slot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This time slot is no longer available. Please select another slot.',
          ),
        ),
      );
      return;
    }

    unawaited(AnalyticsService.logEvent('booking_confirmation_viewed'));
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        worker: worker,
        date: _date,
        slot: _slot,
        address: _addrCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        photoCount: _photos.length,
        pricing: pricing,
      ),
    );
    if (confirmed == true && mounted) {
      await _createAndPay();
    }
  }

  /// Step 2: one server call creates booking + order, then photos upload
  /// with progress, then we move to the payment screen.
  Future<void> _createAndPay() async {
    final worker = _worker;
    if (worker == null) return;
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }
    setState(() => _busy = true);
    unawaited(AnalyticsService.logEvent('booking_payment_started'));

    final result = await ref
        .read(bookingsRepoProvider)
        .createBookingOrder(
          workerId: widget.workerId,
          category: worker.category,
          description: _descCtrl.text.trim(),
          serviceDate: _date,
          timeSlot: _slot,
          address: _addrCtrl.text.trim(),
          estimateMin: worker.priceMin,
          estimateMax: worker.priceMax,
          idempotencyKey: _idempotencyKey,
        );
    if (!mounted) return;
    switch (result) {
      case Error(:final failure):
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      case Success(:final data):
        // Photos are optional: upload with progress; on failure the user
        // can retry or continue without them (never a silent loss).
        if (_photos.isNotEmpty) {
          setState(() => _uploadingPhotos = true);
          final upload = await ref
              .read(bookingsRepoProvider)
              .uploadBookingPhotos(
                bookingId: data.bookingId,
                photos: [
                  for (final p in _photos)
                    (bytes: p.bytes, name: p.originalName),
                ],
                onProgress: (done, total) {
                  if (mounted) setState(() {});
                },
              );
          if (!mounted) return;
          setState(() => _uploadingPhotos = false);
          if (upload is Error) {
            final retry = await _offerPhotoRetry();
            if (retry == true && mounted) {
              setState(() => _busy = false);
              _uploadBookingPhotos(data.bookingId);
              return;
            }
          }
        }
        if (!mounted) return;
        setState(() => _busy = false);
        context.pushReplacement('/payment/${data.bookingId}');
    }
  }

  Future<void> _uploadBookingPhotos(String bookingId) async {
    setState(() => _uploadingPhotos = true);
    final upload = await ref
        .read(bookingsRepoProvider)
        .uploadBookingPhotos(
          bookingId: bookingId,
          photos: [
            for (final p in _photos) (bytes: p.bytes, name: p.originalName),
          ],
        );
    if (!mounted) return;
    setState(() => _uploadingPhotos = false);
    if (upload is Error) {
      final retry = await _offerPhotoRetry();
      if (retry == true && mounted) return _uploadBookingPhotos(bookingId);
    }
    if (mounted) context.pushReplacement('/payment/$bookingId');
  }

  Future<bool?> _offerPhotoRetry() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo upload failed'),
        content: const Text(
          'Your booking was created, but the photos could not be uploaded. '
          'You can retry, or continue without them — photos are optional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue without photos'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricing =
        ref.watch(pricingProvider).valueOrNull ?? PricingConfig.defaults;
    return Scaffold(
      appBar: AppBar(title: const Text('Book Worker')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              _buildWorkerSummary(context),
              const SizedBox(height: KwSpacing.lg),
              _sectionTitle(context, 'When do you need the work?'),
              const SizedBox(height: KwSpacing.sm),
              _buildSchedule(context, pricing),
              const SizedBox(height: KwSpacing.lg),
              _sectionTitle(context, 'Where?'),
              const SizedBox(height: KwSpacing.sm),
              TextFormField(
                controller: _addrCtrl,
                maxLines: 2,
                maxLength: kMaxAddressChars,
                validator: (v) => (v ?? '').trim().length < kMinAddressChars
                    ? 'Enter your full address (flat, building, street, area, city, pincode)'
                    : null,
                decoration: const InputDecoration(
                  hintText: 'Flat / building / street, area, city, pincode',
                  prefixIcon: Icon(Icons.home_outlined),
                  counterStyle: TextStyle(color: KwColors.muted),
                ),
              ),
              const SizedBox(height: KwSpacing.lg),
              _sectionTitle(context, 'Describe the problem'),
              const SizedBox(height: KwSpacing.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: kMaxDescriptionChars,
                validator: (v) => (v ?? '').trim().length < kMinDescriptionChars
                    ? 'Describe the issue in at least $kMinDescriptionChars characters'
                    : null,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in detail — what happened, since when?',
                  counterStyle: TextStyle(color: KwColors.muted),
                ),
              ),
              const SizedBox(height: KwSpacing.lg),
              _sectionTitle(context, 'Add photos (optional)'),
              const SizedBox(height: KwSpacing.sm),
              _buildPhotos(context),
              const SizedBox(height: KwSpacing.lg),
              _buildPriceSummary(context, pricing),
              const SizedBox(height: KwSpacing.lg),
              KwButton(
                label: _busy ? 'Creating your booking…' : 'Review Booking',
                onPressed: _busy || _uploadingPhotos || !_canBook
                    ? null
                    : _reviewBooking,
                loading: _busy || _uploadingPhotos,
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: KwSpacing.sm),
              Center(
                child: Text(
                  pricing.cancellationPolicy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
              ),
              const SizedBox(height: KwSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canBook {
    final w = _worker;
    if (w == null) return false;
    return w.isAvailable && w.isVerified;
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  // ---------- A. worker summary ----------
  Widget _buildWorkerSummary(BuildContext context) {
    if (_loadingWorker) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(KwSpacing.lg),
          child: KwSkeleton(height: 64),
        ),
      );
    }
    final worker = _worker;
    if (worker == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Column(
            children: [
              Text(
                _workerError ?? 'Could not load this worker.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: KwColors.red),
              ),
              const SizedBox(height: KwSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _loadingWorker = true;
                    _workerError = null;
                  });
                  _loadWorker();
                },
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final available = worker.isAvailable && worker.isVerified;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WorkerAvatar(url: worker.photoUrl, radius: 26),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name.isEmpty
                            ? worker.category.labelEn
                            : worker.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        worker.category.labelEn,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KwColors.muted),
                      ),
                    ],
                  ),
                ),
                if (worker.ratingCount > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: KwColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        worker.ratingAvg.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            Row(
              children: [
                Icon(
                  available
                      ? Icons.verified_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: available ? KwColors.green : KwColors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    available
                        ? 'Available • ₹${worker.priceMin.toStringAsFixed(0)} – ₹${worker.priceMax.toStringAsFixed(0)}'
                        : worker.isVerified
                        ? 'This worker is currently unavailable.'
                        : 'This worker is not accepting new jobs yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: available ? KwColors.green : KwColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (!available) ...[
              const SizedBox(height: KwSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KwSpacing.md),
                decoration: BoxDecoration(
                  color: KwColors.redLight,
                  borderRadius: BorderRadius.circular(KwRadius.md),
                ),
                child: Text(
                  'This worker is currently unavailable.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KwColors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- B. date + slots ----------
  Widget _buildSchedule(BuildContext context, PricingConfig pricing) {
    final availability = slotAvailability(
      _date,
      now: DateTime.now(),
      pricing: pricing,
      takenSlots: _takenSlots,
    );
    final day = DateTime(_date.year, _date.month, _date.day);
    final today = DateTime.now();
    final isToday = day == DateTime(today.year, today.month, today.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 17),
                label: Text(
                  isToday
                      ? 'Today, ${DateFormat('dd MMM').format(_date)}'
                      : DateFormat('EEE, dd MMM yyyy').format(_date),
                ),
                onPressed: _pickDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: KwSpacing.md),
        if (_checkingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KwSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: KwSpacing.sm),
                Text('Checking availability…', style: TextStyle(fontSize: 13)),
              ],
            ),
          )
        else
          Wrap(
            spacing: KwSpacing.sm,
            runSpacing: KwSpacing.sm,
            children: [
              for (final entry in availability.entries)
                _SlotChip(
                  label: slotLabel(entry.key),
                  selected: entry.key == _slot,
                  reason: entry.value,
                  onTap: () => _selectSlot(entry.key),
                ),
            ],
          ),
      ],
    );
  }

  // ---------- E. photos ----------
  Widget _buildPhotos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: KwSpacing.sm,
            runSpacing: KwSpacing.sm,
            children: [
              for (var i = 0; i < _photos.length; i++)
                KwImageThumb(
                  bytes: _photos[i].bytes,
                  onRemove: () => setState(() => _photos.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: KwSpacing.md),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_rounded, size: 17),
              label: const Text('Gallery'),
              onPressed: _photos.length < _maxPhotos ? _addPhotos : null,
            ),
            const SizedBox(width: KwSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined, size: 17),
              label: const Text('Camera'),
              onPressed: _photos.length < _maxPhotos ? _takePhoto : null,
            ),
            const Spacer(),
            Text(
              '${_photos.length}/$_maxPhotos',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
        if (_uploadingPhotos) ...[
          const SizedBox(height: KwSpacing.md),
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: KwSpacing.sm),
              Text('Uploading photos…', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _takePhoto() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    try {
      final picked = await KwImagePicker.instance.pickSingle(
        ImageSource.camera,
      );
      if (!mounted) return;
      setState(() => _photos.add(picked));
      unawaited(
        AnalyticsService.logEvent('booking_photo_added', {
          'count': _photos.length,
        }),
      );
    } on ImagePickError catch (e) {
      // Ignore plain cancellations; surface real validation errors.
      if (mounted && e.message != 'No image selected') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // ---------- F. price summary ----------
  Widget _buildPriceSummary(BuildContext context, PricingConfig pricing) {
    final worker = _worker;
    final loadingEstimate = _loadingWorker || worker == null;
    final feeLoading = ref.watch(pricingProvider).isLoading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated service charge',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: KwColors.muted),
                ),
                if (loadingEstimate)
                  const KwSkeleton(height: 18, width: 90)
                else
                  Text(
                    '₹${worker.priceMin.toStringAsFixed(0)} – ₹${worker.priceMax.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
            const SizedBox(height: KwSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking fee (one-time)',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: KwColors.muted),
                ),
                if (feeLoading)
                  const KwSkeleton(height: 18, width: 60)
                else
                  Text(
                    '₹${pricing.bookingFeeRupees}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: KwColors.primary),
                  ),
              ],
            ),
            const Divider(height: KwSpacing.lg),
            Text(
              'Pay the booking fee now to confirm your request. '
              'The service charge is agreed with the worker before work '
              'starts and paid after completion.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.reason,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = reason.isNotEmpty;
    final bg = disabled
        ? KwColors.fill
        : selected
        ? KwColors.primary
        : KwColors.surface;
    final fg = disabled
        ? KwColors.muted.withValues(alpha: .6)
        : selected
        ? Colors.white
        : KwColors.ink;
    return Tooltip(
      message: disabled ? reason : label,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(KwRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(KwRadius.md),
            border: Border.all(
              color: selected ? KwColors.primary : KwColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                disabled ? Icons.lock_clock_outlined : Icons.schedule_rounded,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Task 9: full booking review BEFORE payment is ever opened.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.worker,
    required this.date,
    required this.slot,
    required this.address,
    required this.description,
    required this.photoCount,
    required this.pricing,
  });

  final Worker worker;
  final DateTime date;
  final String slot;
  final String address;
  final String description;
  final int photoCount;
  final PricingConfig pricing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KwSpacing.lg,
          KwSpacing.md,
          KwSpacing.lg,
          KwSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Review your booking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: KwSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row(
                      icon: Icons.person_rounded,
                      label: worker.name.isEmpty
                          ? worker.category.labelEn
                          : worker.name,
                      sub:
                          '${worker.category.labelEn}'
                          '${worker.ratingCount > 0 ? ' • ★ ${worker.ratingAvg.toStringAsFixed(1)}' : ''}',
                    ),
                    _Row(
                      icon: Icons.event_rounded,
                      label:
                          '${DateFormat('EEE, dd MMM yyyy').format(date)} • ${slotLabel(slot)}',
                    ),
                    _Row(
                      icon: Icons.place_outlined,
                      label: address,
                      sub: 'Service address',
                    ),
                    _Row(
                      icon: Icons.description_outlined,
                      label: description,
                      maxLines: 3,
                    ),
                    _Row(
                      icon: Icons.photo_library_outlined,
                      label: photoCount == 0
                          ? 'No photos added'
                          : '$photoCount photo${photoCount == 1 ? '' : 's'}',
                    ),
                    const Divider(height: KwSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Job estimate',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: KwColors.muted),
                        ),
                        Text(
                          '₹${worker.priceMin.toStringAsFixed(0)} – ₹${worker.priceMax.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: KwSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking fee (pay now)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: KwColors.muted),
                        ),
                        Text(
                          '₹${pricing.bookingFeeRupees}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: KwColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KwSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 15,
                          color: KwColors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Full refund if you cancel before the worker '
                            'accepts. ${pricing.refundTimeline}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: KwColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KwSpacing.lg),
            KwButton(
              label: 'Confirm & Pay ₹${pricing.bookingFeeRupees}',
              icon: Icons.currency_rupee_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: KwSpacing.sm),
            KwButton(
              label: 'Keep editing',
              variant: KwButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.sub,
    this.maxLines,
  });

  final IconData icon;
  final String label;
  final String? sub;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KwSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: KwColors.muted),
          const SizedBox(width: KwSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (sub != null)
                  Text(
                    sub!,
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
