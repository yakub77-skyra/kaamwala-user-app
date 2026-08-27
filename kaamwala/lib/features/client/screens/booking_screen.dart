/// Single-screen booking form (Phase 3 C8) - NO wizard, NO fee tiers.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_button.dart';
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
  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();

  static const _slots = ['8-10', '10-12', '12-14', '14-16', '16-18', '18-20'];
  static const _maxPhotos = 5;

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

  Future<void> _pickPhotos() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxPhotos photos/videos allowed')),
      );
      return;
    }
    final remaining = _maxPhotos - _photos.length;
    try {
      final picked = await _picker.pickMultiImage(limit: remaining);
      if (picked.isNotEmpty && mounted) {
        setState(() => _photos.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick media: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxPhotos photos/videos allowed')),
      );
      return;
    }
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() => _photos.add(photo));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<List<String>> _uploadPhotos(String bookingId) async {
    if (!SupabaseService.isReady || _photos.isEmpty) return [];
    try {
      final bucket = SupabaseService.client.storage.from('booking_photos');
      final urls = <String>[];
      final uid = SupabaseService.currentUserId!;
      for (var i = 0; i < _photos.length; i++) {
        final ext = _photos[i].path.split('.').last;
        final path = '$uid/$bookingId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        await bucket.uploadBinary(path, File(_photos[i].path).readAsBytesSync());
        urls.add(bucket.getPublicUrl(path));
      }
      return urls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to upload media: $e')));
      }
      return [];
    }
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
        // Upload photos after booking is created
        final photoUrls = await _uploadPhotos(data.id);
        if (photoUrls.isNotEmpty) {
          await SupabaseService.client
              .from('bookings')
              .update({'photo_urls': photoUrls})
              .eq('id', data.id);
        }
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
                style: Theme.of(context).textTheme.titleSmall,
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
              Text('When?', style: Theme.of(context).textTheme.titleSmall),
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
              Text('Where?', style: Theme.of(context).textTheme.titleSmall),
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

              // ---------- photos/videos ----------
              Text(
                'Add photos/videos (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: KwSpacing.sm),
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: KwSpacing.sm),
                    itemBuilder: (context, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(KwRadius.md),
                          child: Image.file(
                            File(_photos[i].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded, size: 17),
                    label: const Text('Gallery'),
                    onPressed: _photos.length < _maxPhotos ? _pickPhotos : null,
                  ),
                  const SizedBox(width: KwSpacing.md),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded, size: 17),
                    label: const Text('Camera'),
                    onPressed: _photos.length < _maxPhotos ? _takePhoto : null,
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(width: KwSpacing.sm),
                    Text(
                      '${_photos.length}/$_maxPhotos',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ],
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
                          Text(
                            'Job estimate',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: KwColors.muted),
                          ),
                          Text(
                            '₹${_estMin.toStringAsFixed(0)} – ₹${_estMax.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: KwSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking fee (refundable)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: KwColors.muted),
                          ),
                          Text(
                            '₹${AppConstants.bookingFeeRupees}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: KwColors.primary),
                          ),
                        ],
                      ),
                      const Divider(height: KwSpacing.lg),
                      Text(
                        'Final price is agreed with the worker before work '
                        'starts.',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KwColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.lg),
              KwButton(
                label: _busy
                    ? 'Creating booking…'
                    : 'Pay ₹${AppConstants.bookingFeeRupees} & Book',
                onPressed: _busy ? null : _submit,
                loading: _busy,
                icon: Icons.currency_rupee_rounded,
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
