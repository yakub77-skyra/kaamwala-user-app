/// Worker registration - 4-step flow (Phase 1):
///   1. Basic details  2. Documents (Aadhaar)  3. Work photos  4. Review & submit
///
/// Features: correct step indicator, per-step validation (Next is disabled
/// until the step is valid), image preview/replace/remove, local draft
/// persistence, and submit error recovery (form data is never cleared).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/phone/phone_utils.dart';
import 'package:kaamwala/core/services/sms/sms_providers.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/city_field.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/auth/providers/auth_controller.dart';
import 'package:kaamwala/features/auth/providers/onboarding_controller.dart';
import 'package:kaamwala/features/worker/models/worker_registration.dart';
import 'package:kaamwala/features/worker/repositories/worker_repository.dart';
import 'package:kaamwala/features/worker/services/worker_registration_draft_store.dart';

class WorkerRegisterScreen extends ConsumerStatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  ConsumerState<WorkerRegisterScreen> createState() =>
      _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends ConsumerState<WorkerRegisterScreen> {
  static const _stepLabels = ['Basic', 'Documents', 'Photos', 'Review'];

  final _data = WorkerRegistrationData();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0;
  bool _busy = false;
  String? _submitError;
  bool _draftApplied = false;

  @override
  void initState() {
    super.initState();
    // Prefill from the profile created at role selection (name/city already
    // captured there), then let any saved draft override it.
    final profile = ref.read(authControllerProvider).profile;
    if (profile != null) {
      _data.name = profile.name;
      _data.city = profile.city;
    }
    _nameCtrl.text = _data.name;
    _priceCtrl.text = _data.priceMin > 0 ? '${_data.priceMin}' : '';
    Future<void>.microtask(_loadDraft);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String get _phone =>
      ref.read(authControllerProvider).profile?.phone ??
      ref.read(onboardingControllerProvider).phoneE164 ??
      '';

  bool get _demoMode => ref.read(smsGatewayProvider).isDemoMode;

  Future<void> _loadDraft() async {
    final draft = await WorkerRegistrationDraftStore.load();
    if (!mounted || draft == null || _draftApplied) return;
    setState(() {
      _draftApplied = true;
      draft.applyTo(_data);
      _nameCtrl.text = _data.name;
      _priceCtrl.text = _data.priceMin > 0 ? '${_data.priceMin}' : '';
      // Never restore past the review step; documents/photos are re-added.
      _step = draft.step.clamp(0, 3);
    });
  }

  /// Fire-and-forget draft save - never blocks typing.
  void _persistDraft() {
    unawaited(
      WorkerRegistrationDraftStore.save(
        WorkerRegistrationDraft(
          name: _data.name,
          city: _data.city,
          category: _data.category,
          priceMin: _data.priceMin,
          step: _step,
        ),
      ),
    );
  }

  // ---- Step gating --------------------------------------------------------

  bool get _step1Valid => WorkerRegistrationValidator.isStep1Valid(_data);
  bool get _step2Valid => WorkerRegistrationValidator.isStep2Valid(_data);
  bool get _step3Valid => WorkerRegistrationValidator.isStep3Valid(_data);
  bool get _allValid => WorkerRegistrationValidator.allValid(_data);

  // ---- Navigation ---------------------------------------------------------

  void _goBack() {
    if (_busy) return;
    if (_step > 0) {
      setState(() => _step--);
      _persistDraft();
    } else {
      context.go('/role');
    }
  }

  void _next() {
    if (_busy) return;
    final valid = switch (_step) {
      0 => _step1Valid,
      1 => _step2Valid,
      2 => _step3Valid,
      _ => _allValid,
    };
    if (!valid) {
      // Errors are live via autovalidate; just nudge.
      _showSnack('Please complete the highlighted fields to continue.');
      return;
    }
    setState(() => _step = _step + 1);
    _persistDraft();
  }

  // ---- Image picking ------------------------------------------------------

  Future<ImageSource> _pickSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: KwSpacing.sm),
          ],
        ),
      ),
    );
    return source ?? ImageSource.gallery;
  }

  Future<void> _pickAadhaar(bool front) async {
    final source = await _pickSource();
    try {
      final img = await KwImagePicker.instance.pickSingle(source);
      if (!mounted) return;
      setState(() {
        if (front) {
          _data.aadharFrontBytes = img.bytes;
        } else {
          _data.aadharBackBytes = img.bytes;
        }
      });
    } on ImagePickError catch (e) {
      if (e.message != 'No image selected') _showSnack(e.message);
    }
  }

  Future<void> _pickWorkPhotos() async {
    final room =
        WorkerRegistrationValidator.maxWorkPhotos - _data.portfolioBytes.length;
    if (room <= 0) return;
    try {
      final imgs = await KwImagePicker.instance.pickMulti(maxCount: room);
      if (!mounted) return;
      setState(() {
        for (final img in imgs) {
          if (_data.portfolioBytes.length <
              WorkerRegistrationValidator.maxWorkPhotos) {
            _data.portfolioBytes.add(img.bytes);
          }
        }
      });
    } on ImagePickError catch (e) {
      if (e.message != 'No images selected') _showSnack(e.message);
    }
  }

  // ---- Submit -------------------------------------------------------------

  Future<void> _submit() async {
    if (_busy || !_allValid) return;
    setState(() {
      _busy = true;
      _submitError = null;
    });
    final res = await const WorkerRepository().submitRegistration(
      _data,
      demoMode: _demoMode,
    );
    if (!mounted) return;
    switch (res) {
      case Success():
        // Registration recorded - drop the draft so a fresh attempt starts clean.
        await WorkerRegistrationDraftStore.clear();
        if (!mounted) return;
        context.go('/w/review');
      case Error(:final failure):
        // Keep ALL user data - only show the error and let them retry.
        setState(() {
          _busy = false;
          _submitError = failure.message;
        });
        _showSnack(failure.message);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: const Text('Worker Signup'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KwSpacing.lg,
                KwSpacing.xs,
                KwSpacing.lg,
                KwSpacing.md,
              ),
              child: _StepIndicator(step: _step, labels: _stepLabels),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    KwSpacing.xl,
                    0,
                    KwSpacing.xl,
                    KwSpacing.xl,
                  ),
                  children: switch (_step) {
                    0 => _buildStep1(context),
                    1 => _buildStep2(context),
                    2 => _buildStep3(context),
                    _ => _buildStep4(context),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _busy ? null : _goBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: KwSpacing.md),
              ],
              Expanded(
                child: KwButton(
                  label: _step == 3 ? 'Submit for Review' : 'Next',
                  icon: _step == 3
                      ? Icons.verified_outlined
                      : Icons.arrow_forward_rounded,
                  loading: _busy,
                  onPressed: switch (_step) {
                    0 => _step1Valid ? _next : null,
                    1 => _step2Valid ? _next : null,
                    2 => _step3Valid ? _next : null,
                    _ => _allValid ? _submit : null,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Step 1: Basic details ----------------------------------------------

  List<Widget> _buildStep1(BuildContext context) {
    return [
      Text(
        'Your details help customers trust you.',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: KwSpacing.xs),
      Text(
        'This takes about 2 minutes.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: KwColors.muted),
      ),
      const SizedBox(height: KwSpacing.lg),
      if (_phone.isNotEmpty) ...[
        Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 18,
              color: KwColors.green,
            ),
            const SizedBox(width: KwSpacing.xs),
            Text(
              'Verified: ${maskPhoneE164(_phone)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
        const SizedBox(height: KwSpacing.lg),
      ],
      _FieldLabel('Your full name'),
      const SizedBox(height: KwSpacing.sm),
      TextFormField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Ramesh Kumar'),
        validator: WorkerRegistrationValidator.name,
        onChanged: (v) {
          _data.name = v;
          _persistDraft();
        },
      ),
      if (WorkerRegistrationValidator.name(_data.name) != null)
        _FieldHelper(
          'Min ${WorkerRegistrationValidator.minNameLength} characters',
        ),
      const SizedBox(height: KwSpacing.lg),

      _FieldLabel('Your city'),
      const SizedBox(height: KwSpacing.sm),
      KwCityField(
        initialValue: _data.city,
        validator: WorkerRegistrationValidator.city,
        onChanged: (v) {
          _data.city = v;
          _persistDraft();
        },
      ),
      if (WorkerRegistrationValidator.city(_data.city) != null)
        _FieldHelper('Any city works - not limited to the suggestions'),
      const SizedBox(height: KwSpacing.lg),

      _FieldLabel('What work do you do?'),
      const SizedBox(height: KwSpacing.sm),
      Wrap(
        spacing: KwSpacing.sm,
        runSpacing: KwSpacing.sm,
        children: [
          for (final c in ServiceCategory.values)
            ChoiceChip(
              avatar: Icon(c.icon, size: 18),
              label: Text(c.labelEn),
              selected: _data.category == c.dbValue,
              selectedColor: KwColors.primary.withValues(alpha: 0.12),
              onSelected: (_) {
                setState(() => _data.category = c.dbValue);
                _persistDraft();
              },
            ),
        ],
      ),
      if (_data.category.isEmpty) _FieldHelper('Select one category'),
      const SizedBox(height: KwSpacing.lg),

      _FieldLabel('Starting day rate (₹/day)'),
      const SizedBox(height: KwSpacing.sm),
      TextFormField(
        controller: _priceCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          prefixText: '₹  ',
          hintText: 'e.g. 500',
        ),
        validator: WorkerRegistrationValidator.price,
        onChanged: (v) {
          _data.priceMin = int.tryParse(v) ?? 0;
          _persistDraft();
        },
      ),
      if (WorkerRegistrationValidator.price(_priceCtrl.text) != null)
        _FieldHelper('Your starting charge per day'),
      const SizedBox(height: KwSpacing.md),
    ];
  }

  // ---- Step 2: Documents ---------------------------------------------------

  List<Widget> _buildStep2(BuildContext context) {
    return [
      _TrustCard(
        icon: Icons.shield_outlined,
        title: 'Aadhaar is used only for verification',
        body:
            'It is stored securely, never shown to customers, and only used '
            'to build trust in your profile.',
      ),
      const SizedBox(height: KwSpacing.xl),

      _FieldLabel('Aadhaar card front'),
      const SizedBox(height: KwSpacing.sm),
      if (_data.aadharFrontBytes != null)
        KwImagePreview(
          bytes: _data.aadharFrontBytes!,
          label: 'Front side',
          onRemove: () => setState(() => _data.aadharFrontBytes = null),
        )
      else
        _PickTile(
          icon: Icons.badge_outlined,
          label: 'Add front photo',
          onTap: () => _pickAadhaar(true),
        ),
      if (_data.aadharFrontBytes != null) ...[
        const SizedBox(height: KwSpacing.xs),
        _ReplaceTile(onTap: () => _pickAadhaar(true)),
      ],
      const SizedBox(height: KwSpacing.lg),

      _FieldLabel('Aadhaar card back'),
      const SizedBox(height: KwSpacing.sm),
      if (_data.aadharBackBytes != null)
        KwImagePreview(
          bytes: _data.aadharBackBytes!,
          label: 'Back side',
          onRemove: () => setState(() => _data.aadharBackBytes = null),
        )
      else
        _PickTile(
          icon: Icons.badge_outlined,
          label: 'Add back photo',
          onTap: () => _pickAadhaar(false),
        ),
      if (_data.aadharBackBytes != null) ...[
        const SizedBox(height: KwSpacing.xs),
        _ReplaceTile(onTap: () => _pickAadhaar(false)),
      ],
      const SizedBox(height: KwSpacing.md),
      if (!WorkerRegistrationValidator.aadhaarValid(
        _data.aadharFrontBytes,
        _data.aadharBackBytes,
      ))
        _FieldHelper('Both sides are required to submit'),
    ];
  }

  // ---- Step 3: Work photos -------------------------------------------------

  List<Widget> _buildStep3(BuildContext context) {
    final count = _data.portfolioBytes.length;
    return [
      Text(
        'Work photos',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: KwSpacing.xs),
      Text(
        'Add clear photos of your work to get more jobs. '
        'Customers see these on your profile.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: KwColors.muted, height: 1.4),
      ),
      const SizedBox(height: KwSpacing.lg),
      KwImageThumbRow(
        images: _data.portfolioBytes,
        onRemove: (i) {
          setState(() => _data.portfolioBytes.removeAt(i));
          _persistDraft();
        },
      ),
      if (count > 0) const SizedBox(height: KwSpacing.md),
      OutlinedButton.icon(
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(
          count >= WorkerRegistrationValidator.maxWorkPhotos
              ? 'Maximum ${WorkerRegistrationValidator.maxWorkPhotos} photos added'
              : 'Add photos ($count/${WorkerRegistrationValidator.maxWorkPhotos})',
        ),
        onPressed: count >= WorkerRegistrationValidator.maxWorkPhotos
            ? null
            : _pickWorkPhotos,
      ),
      const SizedBox(height: KwSpacing.md),
      _PhotoProgress(
        count: count,
        min: WorkerRegistrationValidator.minWorkPhotos,
        max: WorkerRegistrationValidator.maxWorkPhotos,
      ),
      if (!WorkerRegistrationValidator.workPhotosValid(count))
        _FieldHelper(
          'Add at least ${WorkerRegistrationValidator.minWorkPhotos} photos',
        ),
      const SizedBox(height: KwSpacing.md),
    ];
  }

  // ---- Step 4: Review & submit --------------------------------------------

  List<Widget> _buildStep4(BuildContext context) {
    final category =
        ServiceCategory.values
            .where((c) => c.dbValue == _data.category)
            .firstOrNull
            ?.labelEn ??
        _data.category;
    return [
      Text(
        'Review your details',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: KwSpacing.xs),
      Text(
        'Our team verifies within 24 hours.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: KwColors.muted),
      ),
      const SizedBox(height: KwSpacing.lg),
      Container(
        decoration: BoxDecoration(
          color: KwColors.surface,
          borderRadius: BorderRadius.circular(KwRadius.lg),
          border: Border.all(color: KwColors.line),
        ),
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          children: [
            _SummaryRow(label: 'Name', value: _data.name.trim()),
            _SummaryRow(label: 'City', value: _data.city.trim()),
            _SummaryRow(label: 'Work type', value: category),
            _SummaryRow(
              label: 'Day rate',
              value: '₹${_data.priceMin}/day',
              last: true,
            ),
            if (_phone.isNotEmpty)
              _SummaryRow(
                label: 'Verified number',
                value: maskPhoneE164(_phone),
                last: true,
              ),
          ],
        ),
      ),
      const SizedBox(height: KwSpacing.md),
      Container(
        decoration: BoxDecoration(
          color: KwColors.surface,
          borderRadius: BorderRadius.circular(KwRadius.lg),
          border: Border.all(color: KwColors.line),
        ),
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Aadhaar front',
              value: _data.aadharFrontBytes != null ? 'Added' : 'Missing',
              last: false,
              ok: _data.aadharFrontBytes != null,
            ),
            _SummaryRow(
              label: 'Aadhaar back',
              value: _data.aadharBackBytes != null ? 'Added' : 'Missing',
              ok: _data.aadharBackBytes != null,
            ),
            _SummaryRow(
              label: 'Work photos',
              value:
                  '${_data.portfolioBytes.length} photo${_data.portfolioBytes.length == 1 ? '' : 's'}',
              last: true,
              ok: WorkerRegistrationValidator.workPhotosValid(
                _data.portfolioBytes.length,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: KwSpacing.md),
      if (!_allValid) ...[
        Container(
          padding: const EdgeInsets.all(KwSpacing.md),
          decoration: BoxDecoration(
            color: KwColors.warningLight,
            borderRadius: BorderRadius.circular(KwRadius.md),
            border: Border.all(color: KwColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: KwColors.warning,
              ),
              const SizedBox(width: KwSpacing.sm),
              Expanded(
                child: Text(
                  'Some details are incomplete. Go back and finish them '
                  'before submitting.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KwSpacing.md),
      ],
      if (_submitError != null) ...[
        Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: KwColors.red,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _submitError!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KwColors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: KwSpacing.md),
      ],
      _TrustCard(
        icon: Icons.lock_outline_rounded,
        title: 'Your data is safe with us',
        body:
            'Aadhaar photos are encrypted and private. Work photos are only '
            'visible to customers after approval.',
      ),
      const SizedBox(height: KwSpacing.md),
    ];
  }
}

// ---- Shared small widgets --------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _FieldHelper extends StatelessWidget {
  const _FieldHelper(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: KwColors.muted),
    ),
  );
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KwSpacing.md),
      decoration: BoxDecoration(
        color: KwColors.greenLight,
        borderRadius: BorderRadius.circular(KwRadius.md),
        border: Border.all(color: KwColors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: KwColors.green),
          const SizedBox(width: KwSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: KwColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KwColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _ReplaceTile extends StatelessWidget {
  const _ReplaceTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Replace'),
      ),
    );
  }
}

/// Thin progress bar for the work-photo minimum.
class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({
    required this.count,
    required this.min,
    required this.max,
  });

  final int count;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final pct = (count / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(KwRadius.pill),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: KwColors.fill,
            color: count >= min ? KwColors.green : KwColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count >= min
              ? 'Minimum reached - you can add up to $max.'
              : '$count of $min minimum photos added',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: KwColors.muted),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
    this.ok = true,
  });

  final String label;
  final String value;
  final bool last;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: KwColors.muted),
                ),
              ),
              if (!ok)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: KwColors.red,
                  ),
                ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(height: 1, color: KwColors.line.withValues(alpha: 0.6)),
      ],
    );
  }
}

/// Correct step indicator: numbered circles with check marks for completed
/// steps, connectors, and a "Step N of 4" caption. No substring tricks.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= step ? KwColors.primary : KwColors.line,
                      borderRadius: BorderRadius.circular(KwRadius.pill),
                    ),
                  ),
                ),
              _StepDot(index: i, current: step),
            ],
          ],
        ),
        const SizedBox(height: KwSpacing.sm),
        Text(
          'Step ${step + 1} of ${labels.length} - ${labels[step]}',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: KwColors.muted),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.current});

  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final Color bg;
    final Color fg;
    if (done) {
      bg = KwColors.green;
      fg = Colors.white;
    } else if (active) {
      bg = KwColors.primary;
      fg = Colors.white;
    } else {
      bg = KwColors.surface;
      fg = KwColors.muted;
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: active || done
            ? null
            : Border.all(color: KwColors.line, width: 1.5),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
