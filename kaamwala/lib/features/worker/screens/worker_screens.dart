/// Under Review (W2), Dashboard (W3), Job Requests (W4), Job Detail (W5),
/// Active Job (W6), Earnings (W7), Payment Setup (W8) - Hindi-first.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/worker/repositories/worker_repository.dart';

/// W2 - Profile under review gate. Worker cannot see jobs until approved.
class UnderReviewScreen extends StatelessWidget {
  const UnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⏳', style: TextStyle(fontSize: 72)),
              SizedBox(height: KwSpacing.lg),
              Text('आपकी प्रोफ़ाइल जांच के अधीन है',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: KwSpacing.sm),
              Text('(Profile under review)',
                  style: TextStyle(color: KwColors.muted)),
              SizedBox(height: KwSpacing.md),
              Text('We verify your Aadhar within 24 hours.\n'
                  'You\'ll get a message when approved. ✅',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// W3 - Worker dashboard: availability toggle, today stats, new jobs.
class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _available = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('नमस्ते, Ramesh 🙏'), actions: [
        IconButton(onPressed: () => context.go('/w/notifications'), icon: const Badge(child: Icon(Icons.notifications_outlined))),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Card(
            color: _available ? KwColors.green.withValues(alpha: .08) : KwColors.surface,
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              value: _available,
              onChanged: (v) async {
                setState(() => _available = v);
                await const WorkerRepository().setAvailability(v);
              },
              activeThumbColor: KwColors.green,
              title: Text('काम के लिए उपलब्ध?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: const Text('Available for jobs'),
            ),
          ),
          const SizedBox(height: KwSpacing.md),
          Row(
            children: [
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(KwSpacing.lg),
                    child: Column(children: [
                      Text('आज के काम', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text('2',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: KwSpacing.md),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(KwSpacing.lg),
                    child: Column(children: [
                      Text('आज की कमाई', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text('₹900',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KwSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text('नए काम (2)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => context.go('/w/jobs'),
                child: const Text('सभी देखें ›'),
              ),
            ],
          ),
          _jobCard(context, emoji: '🌀', title: 'Fan repair', meta: 'Rohit • Kharadi • Today 10 AM • ~₹300'),
          _jobCard(context, emoji: '💡', title: 'Wiring check', meta: 'Priya • Viman Nagar • Tomorrow 2 PM • ~₹500'),
        ],
      ),
    );
  }

  Widget _jobCard(BuildContext context,
      {required String emoji, required String title, required String meta}) {
    return Card(
      margin: const EdgeInsets.only(bottom: KwSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: KwSpacing.md),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const SizedBox(height: 4),
            Text(meta,
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(color: KwColors.muted)),
            const SizedBox(height: KwSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: KwColors.red),
                    onPressed: () {},
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: KwSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('✅ Accept'),
                    onPressed: () => context.go('/w/job/new'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// W5/W6 - Job detail with accept/decline + status progression buttons.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, this.jobId});
  final String? jobId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: KwColors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: KwSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('✅ Accept'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Text('👤', style: TextStyle(fontSize: 24)), title: const Text('Rohit Sharma')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Text('🌀', style: TextStyle(fontSize: 24)), title: const Text('Fan is not working')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Text('📍', style: TextStyle(fontSize: 24)), title: const Text('A-402, Kharadi (1.2 km)')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Text('📅', style: TextStyle(fontSize: 24)), title: const Text('Today • 10 AM – 12 PM')),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimate'),
              const Text('₹300 – ₹800', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: KwSpacing.sm),
          Row(
            children: [
              Text('You earn (90%)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('₹270 – ₹720',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: KwColors.green, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: KwSpacing.sm),
          Text('Platform commission ${(AppConstants.commissionRate * 100).toStringAsFixed(0)}% — transparent.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: KwColors.muted)),
        ],
      ),
    );
  }
}

/// Active job status screen with ONE next-action button (Phase 3 W6).
class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Job')),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          const StatusRow(done: true, label: 'Started travel'),
          const StatusRow(done: false, current: true, label: 'Arrived'),
          const StatusRow(done: false, label: 'Working'),
          const StatusRow(done: false, label: 'Completed'),
          const SizedBox(height: KwSpacing.xl),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text('✅ I have Arrived'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.done, this.current = false, required this.label});
  final bool done;
  final bool current;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: done
          ? const Icon(Icons.check_circle, color: KwColors.green)
          : current
              ? const Icon(Icons.radio_button_checked, color: KwColors.gold)
              : const Icon(Icons.circle_outlined, color: KwColors.muted),
      title: Text(label,
          style: TextStyle(
              fontWeight: current ? FontWeight.w700 : FontWeight.w400,
              color: done || current ? KwColors.dark : KwColors.muted)),
    );
  }
}

/// W7 - Earnings (Hindi-first).
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('कमाई (Earnings)')),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(KwSpacing.xl),
              child: Column(
                children: [
                  Text('इस महीने (This Month)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: KwSpacing.sm),
                  Text('₹12,400',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: KwSpacing.sm),
                  const Text('This Week ₹3,200'),
                  const Divider(height: KwSpacing.xl),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.currency_rupee, size: 18, color: KwColors.green),
                    Text('Paid to ramesh@ybl ✅',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: KwColors.green)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: KwSpacing.lg),
          Text('HISTORY',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: KwColors.muted, letterSpacing: 1)),
          const ListTile(leading: Text('🌀'), title: Text('Fan repair'), trailing: Text('+₹270 ✅')),
          const ListTile(leading: Text('💡'), title: Text('Wiring'), trailing: Text('+₹720 ✅')),
          const ListTile(leading: Text('🎨'), title: Text('Painting'), trailing: Text('+₹1,800 🟡')),
          const SizedBox(height: KwSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Payment Setup'),
            onPressed: () => context.go('/w/payment-setup'),
          ),
        ],
      ),
    );
  }
}

/// W8 - One-time payment setup. UPI regex from FR-WORKER-10.
class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({super.key});

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  bool _upi = true;
  final _upiCtrl = TextEditingController();
  bool get _upiValid =>
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{2,}$').hasMatch(_upiCtrl.text.trim());

  @override
  void dispose() {
    _upiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Setup')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: !_upi || (_upi && !_upiValid)
                ? null
                : () async {
                    await const WorkerRepository().savePaymentInfo(
                      upi: _upi,
                      upiId: _upiCtrl.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.xl),
        children: [
          const Center(child: Text('Money will come here 👇', style: TextStyle(fontSize: 16))),
          const SizedBox(height: KwSpacing.lg),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('UPI')),
              ButtonSegment(value: false, label: Text('Bank')),
            ],
            selected: {_upi},
            onSelectionChanged: (s) => setState(() => _upi = s.first),
          ),
          const SizedBox(height: KwSpacing.lg),
          if (_upi) ...[
            TextField(
              controller: _upiCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'ramesh@ybl'),
            ),
            const SizedBox(height: KwSpacing.sm),
            if (_upiCtrl.text.isNotEmpty)
              Text(
                _upiValid ? '✅ UPI ID looks valid' : '❌ Invalid UPI ID format',
                style: TextStyle(
                    color: _upiValid ? KwColors.green : KwColors.red,
                    fontSize: 12),
              ),
          ] else ...[
            const TextField(decoration: InputDecoration(hintText: 'Account Number')),
            const SizedBox(height: KwSpacing.md),
            const TextField(decoration: InputDecoration(hintText: 'IFSC Code')),
            const SizedBox(height: KwSpacing.md),
            const TextField(decoration: InputDecoration(hintText: 'Account Holder Name')),
          ],
        ],
      ),
    );
  }
}
