/// Payment screen (Phase 3 C9) - opens native Razorpay checkout.
/// Order created by Edge Function; client only gets order_id + key_id.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
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

  String get _statusText => switch (_stage) {
    PayStage.creating => 'Creating order…',
    PayStage.checkout => 'Ready to pay',
    PayStage.processing => 'Processing…',
    PayStage.success => 'Payment successful',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: _stage == PayStage.success
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded),
                  onPressed: () => context.go('/bookings'),
                  label: const Text('View My Bookings'),
                )
              : ElevatedButton.icon(
                  icon:
                      _stage == PayStage.processing ||
                          _stage == PayStage.creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.currency_rupee_rounded),
                  onPressed:
                      (_razorpayOrderId == null ||
                          _stage == PayStage.processing)
                      ? null
                      : _openCheckout,
                  label: Text(
                    _stage == PayStage.checkout
                        ? 'Pay ₹${_amountPaise ~/ 100}'
                        : _statusText,
                  ),
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(KwSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Booking fee'),
                      Text(
                        '₹${_amountPaise ~/ 100}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Divider(height: KwSpacing.lg),
                  Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 15, color: KwColors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Secured by Razorpay • UPI, cards & netbanking',
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
          const SizedBox(height: KwSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KwColors.blueLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.undo_rounded,
                  size: 19,
                  color: KwColors.blue,
                ),
              ),
              title: const Text(
                'Full refund if you cancel',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Cancel any time before the worker accepts — money returns to your source automatically.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              isThreeLine: true,
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
          const SizedBox(height: KwSpacing.xl),
          Center(
            child: Text(
              _statusText,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: KwColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
