/// Worker registration - 3 steps, Hindi-first (Phase 3 W1 wireframe).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/worker/repositories/worker_repository.dart';

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  int _step = 0;
  final _data = WorkerRegistrationData();
  Uint8List? _front;
  Uint8List? _back;
  bool _busy = false;

  Future<void> _pickAadhar(bool front) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => front ? _front = bytes : _back = bytes);
  }

  /// Optional work photos - gallery multi-pick, capped at 5 (CS-05).
  Future<void> _pickWorkPhotos() async {
    final room = 5 - _data.portfolioBytes.length;
    if (room <= 0) return;
    final xs = await ImagePicker().pickMultiImage(imageQuality: 60);
    for (final x in xs.take(room)) {
      _data.portfolioBytes.add(await x.readAsBytes());
    }
    if (mounted) setState(() {});
  }

  Future<void> _next() async {
    if (_step == 2) {
      setState(() => _busy = true);
      _data.aadharFrontBytes = _front;
      _data.aadharBackBytes = _back;
      // Repository handles byte upload to the private aadhar_scans bucket.
      await const WorkerRepository().submitRegistration(_data);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/w/review');
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Worker Signup   ${'●○○'.substring(0, _step)}${'○' * (2 - _step)}',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: switch (_step) {
            0 => [
              Text('Your name', style: Theme.of(context).textTheme.titleSmall),
              TextField(
                onChanged: (v) => _data.name = v,
                decoration: const InputDecoration(hintText: 'Ramesh Kumar'),
              ),
              const SizedBox(height: KwSpacing.lg),
              Text('Your city', style: Theme.of(context).textTheme.titleSmall),
              DropdownButtonFormField<String>(
                initialValue: 'Pune',
                items: const [
                  DropdownMenuItem(value: 'Pune', child: Text('Pune')),
                  DropdownMenuItem(value: 'Jaipur', child: Text('Jaipur')),
                  DropdownMenuItem(
                    value: 'Hyderabad',
                    child: Text('Hyderabad'),
                  ),
                  DropdownMenuItem(
                    value: 'Ahmedabad',
                    child: Text('Ahmedabad'),
                  ),
                ],
                onChanged: (v) => _data.city = v ?? 'Pune',
              ),
            ],
            1 => [
              Text(
                'What work do you do?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: KwSpacing.md),
              Wrap(
                spacing: KwSpacing.sm,
                runSpacing: KwSpacing.sm,
                children: [
                  for (final c in ServiceCategory.values)
                    ChoiceChip(
                      label: Padding(
                        padding: const EdgeInsets.all(KwSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(c.icon, size: 20),
                            const SizedBox(width: 6),
                            Text(c.labelEn),
                          ],
                        ),
                      ),
                      selected: _data.category == c.dbValue,
                      onSelected: (_) =>
                          setState(() => _data.category = c.dbValue),
                    ),
                ],
              ),
              const SizedBox(height: KwSpacing.lg),
              Text(
                'Starting day rate (₹/day)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '300'),
                onChanged: (v) => _data.priceMin = int.tryParse(v) ?? 300,
              ),
            ],
            _ => [
              Text(
                'Aadhaar card photos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: KwSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _front == null ? Icons.camera_alt : Icons.check_circle,
                        color: _front == null ? null : KwColors.green,
                      ),
                      label: const Text('Front'),
                      onPressed: () => _pickAadhar(true),
                    ),
                  ),
                  const SizedBox(width: KwSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _back == null ? Icons.camera_alt : Icons.check_circle,
                        color: _back == null ? null : KwColors.green,
                      ),
                      label: const Text('Back'),
                      onPressed: () => _pickAadhar(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KwSpacing.md),
              Text(
                'Only our team sees this',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted),
              ),
              const SizedBox(height: KwSpacing.xl),
              Text(
                'Work photos (Optional - max 5)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: KwSpacing.sm),
              OutlinedButton.icon(
                icon: Icon(
                  _data.portfolioBytes.isEmpty
                      ? Icons.add_photo_alternate_outlined
                      : Icons.check_circle,
                  color: _data.portfolioBytes.isEmpty ? null : KwColors.green,
                ),
                label: Text(
                  '🖼️ ${_data.portfolioBytes.length}/5 photos added',
                ),
                onPressed: _data.portfolioBytes.length >= 5
                    ? null
                    : _pickWorkPhotos,
              ),
              Text(
                'Customers see these on your profile',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: KwColors.muted),
              ),
            ],
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: ElevatedButton(
            onPressed: _busy ? null : _next,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_step == 2 ? 'Submit for Approval' : 'Next →'),
          ),
        ),
      ),
    );
  }
}
