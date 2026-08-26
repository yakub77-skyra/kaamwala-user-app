/// Payment screen (UI 2.0) - amount hero, trust badges, KwButton states.
/// Order created by Edge Function; client only gets order_id + key_id.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_button.dart';
import 'package:kaamwala/core/ui/kw_icon_well.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/razorpay_service.dart';

enum PayStage { creating, checkout, processing, success }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PayStage _stage = PayStage.creating;
  String? _razorpayOrderId;
  int _amountPaise = 2000;
  String? _error;
  final _rzp = RazorpayService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createOrder());
  }

  Future<void> _createOrder() async {
    setState(() {
      _stage = PayStage.creating;
      _error = null;
    });
    final result = await ref
        .read(bookingsRepoProvider)
        .createOrder(widget.bookingId);
    switch (result) {
      case Success(:final data):
        _razorpayOrderId = data['order_id'] as String?;
        _amountPaise = (data['amount'] as num? ?? 2000).toInt();
        unawaited(
          AnalyticsService.logEvent('order_created', {
            'booking_id': widget.bookingId,
            'amount': _amountPaise,
          }),
        );
        setState(() => _stage = PayStage.checkout);
      case Error(:final failure):
        unawaited(
          AnalyticsService.logEvent('order_failed', {
            'booking_id': widget.bookingId,
          }),
        );
        setState(() {
          _stage = PayStage.checkout;
          _error = failure.message;
        });
    }
  }

  void _openCheckout() {
    if (_razorpayOrderId == null) return;
    setState(() => _stage = PayStage.processing);
    _rzp.openCheckout(
      orderId: _razorpayOrderId!,
      amountPaise: _amountPaise,
      name: 'KaamWala',
      description: 'Booking fee',
      onSuccess: (_) {
        if (!mounted) return;
        unawaited(
          AnalyticsService.logEvent('payment_succeeded', {
            'booking_id': widget.bookingId,
            'amount': _amountPaise,
          }),
        );
        setState(() => _stage = PayStage.success);
      },
      onError: (msg) {
        if (!mounted) return;
        unawaited(
          AnalyticsService.logEvent('payment_failed', {
            'booking_id': widget.bookingId,
            'reason': msg.length > 90 ? msg.substring(0, 90) : msg,
          }),
        );
        setState(() {
          _stage = PayStage.checkout;
          _error = msg;
        });
      },
    );
  }

  @override
  void dispose() {
    _rzp.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rupees = _amountPaise ~/ 100;
    final busy = _stage == PayStage.creating || _stage == PayStage.processing;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: _stage == PayStage.success
              ? KwButton(
                  label: 'View My Bookings',
                  onPressed: () => context.go('/bookings'),
                  icon: Icons.receipt_long_rounded,
                )
              : KwButton(
                  label: busy
                      ? (_stage == PayStage.creating
                            ? 'Creating order…'
                            : 'Processing…')
                      : 'Pay ₹$rupees',
                  onPressed:
                      (_razorpayOrderId == null ||
                          _stage == PayStage.processing)
                      ? null
                      : _openCheckout,
                  loading: busy,
                  icon: Icons.currency_rupee_rounded,
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          const SizedBox(height: KwSpacing.md),
          // ---------- amount hero ----------
          Center(
            child: Column(
              children: [
                Text(
                  'BOOKING FEE',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted, letterSpacing: 1.2),
                ),
                const SizedBox(height: KwSpacing.sm),
                Text(
                  '₹$rupees',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: KwSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: KwColors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secured by Razorpay',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: KwColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: KwSpacing.xl),
          // ---------- what you get ----------
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(KwSpacing.lg),
              child: Column(
                children: [
                  _PerkRow(
                    icon: Icons.event_available_rounded,
                    tint: KwColors.blueLight,
                    fg: KwColors.blue,
                    title: 'Priority booking with your worker',
                  ),
                  const SizedBox(height: KwSpacing.md),
                  _PerkRow(
                    icon: Icons.undo_rounded,
                    tint: KwColors.primaryLight,
                    fg: KwColors.primary,
                    title: 'Full refund if you cancel before acceptance',
                  ),
                  const SizedBox(height: KwSpacing.md),
                  _PerkRow(
                    icon: Icons.verified_user_rounded,
                    tint: KwColors.greenLight,
                    fg: KwColors.green,
                    title: 'Money held until you confirm the work',
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: KwSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.red),
            ),
          ],
          const SizedBox(height: KwSpacing.lg),
          Center(
            child: Text(
              'UPI • Cards • Netbanking via Razorpay',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ),
          const SizedBox(height: KwSpacing.xl),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.tint,
    required this.fg,
    required this.title,
  });

  final IconData icon;
  final Color tint;
  final Color fg;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KwIconWell(icon: icon, size: 38, background: tint, foreground: fg),
        const SizedBox(width: KwSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
