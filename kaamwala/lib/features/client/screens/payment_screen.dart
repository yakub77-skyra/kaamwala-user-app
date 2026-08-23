/// Payment screen (Phase 3 C9) - opens native Razorpay checkout.
/// Order created by Edge Function; client only gets order_id + key_id.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
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
    final result = await ref.read(bookingsRepoProvider).createOrder(widget.bookingId);
    switch (result) {
      case Success(:final data):
        _razorpayOrderId = data['order_id'] as String?;
        _amountPaise = (data['amount'] as num? ?? 2000).toInt();
        setState(() => _stage = PayStage.checkout);
      case Error(:final failure):
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
      contactPhone: '+919876543210',
      onSuccess: (_) {
        if (!mounted) return;
        setState(() => _stage = PayStage.success);
      },
      onError: (msg) {
        if (!mounted) return;
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
        PayStage.creating => '◌ Creating order…',
        PayStage.checkout => 'Ready to pay',
        PayStage.processing => '◌ Processing…',
        PayStage.success => '✅ Success',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.lg),
          child: _stage == PayStage.success
              ? ElevatedButton(
                  onPressed: () => context.go('/bookings'),
                  child: const Text('View My Bookings'))
              : ElevatedButton.icon(
                  icon: const Icon(Icons.currency_rupee),
                  label: Text('Pay ₹${_amountPaise ~/ 100}'),
                  onPressed:
                      (_razorpayOrderId == null || _stage == PayStage.processing)
                          ? null
                          : _openCheckout,
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KwSpacing.lg),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text('Booking #${widget.bookingId.substring(0, 8)}'),
              subtitle: const Text('Booking Fee'),
              trailing: Text('₹${_amountPaise ~/ 100}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: KwSpacing.lg),
          Text('Pay with', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: KwSpacing.sm),
          Wrap(
            spacing: KwSpacing.sm,
            runSpacing: KwSpacing.sm,
            children: [
              for (final upi in ['GPay', 'PhonePe', 'Paytm', 'Other UPI'])
                FilterChip(label: Text(upi), selected: upi == 'GPay', onSelected: (_) {}),
              FilterChip(label: const Text('Card / NetBanking'), onSelected: (_) {}),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: KwSpacing.md),
            Text('⚠️ $_error',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: KwColors.red)),
          ],
          const SizedBox(height: KwSpacing.xl),
          Center(
            child: Text(_statusText,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: KwColors.muted)),
          ),
          const SizedBox(height: KwSpacing.sm),
          Text(
            'Payment verified server-side via webhook (HMAC-SHA256).\n'
            'Cancel before worker accepts = full ₹20 refund.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: KwColors.muted),
          ),
        ],
      ),
    );
  }
}
