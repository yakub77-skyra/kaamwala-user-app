/// Payment screen (Phase 2) - no hardcoded amounts.
///
/// Flow: create/reuse server order -> show amount ONLY from the server ->
/// gateway checkout (Razorpay SDK or dev mock sheet, chosen by the server's
/// order.mock flag) -> "Checking payment status…" poll via
/// check-payment-status -> success receipt / actionable failure with retry
/// (limited attempts) and a manual "Check payment status" recovery path.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/services/payment/mock_payment_gateway.dart';
import 'package:kaamwala/core/services/payment/payment_gateway_provider.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/core_ui.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/models/booking.dart';
import 'package:kaamwala/services/analytics_service.dart';
import 'package:kaamwala/services/supabase_service.dart';

enum PayStage { creating, ready, processing, success, failed }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PayStage _stage = PayStage.creating;
  BookingOrderDraft? _order;
  String? _error;
  int _failedAttempts = 0;
  BookingPaymentStatus? _verified;

  static const _maxFailedAttempts = 3;
  static const _pollInterval = Duration(seconds: 2);
  static const _maxPolls = 10;

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
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        unawaited(
          AnalyticsService.logEvent('booking_payment_started', {
            'booking_id': widget.bookingId,
            'amount': data.amountPaise,
            'mock': data.mock,
          }),
        );
        setState(() {
          _order = data;
          _stage = PayStage.ready;
        });
      case Error(:final failure):
        // Already-paid recovery: jump straight to status check (task 11.3).
        if (failure.message.toLowerCase().contains('already paid')) {
          await _checkStatus();
          return;
        }
        unawaited(
          AnalyticsService.logEvent('booking_payment_failed', {
            'booking_id': widget.bookingId,
            'step': 'order',
          }),
        );
        setState(() {
          _stage = PayStage.failed;
          _error = failure.message;
        });
    }
  }

  /// Opens the gateway. The server's `mock` flag decides which gateway UI
  /// to use; the env-selected provider is the fallback/default.
  Future<void> _openCheckout() async {
    final order = _order;
    if (order == null || _stage != PayStage.ready) return;
    final defaultGateway = ref.read(paymentGatewayProvider);
    final gateway = order.mock ? const MockPaymentGateway() : defaultGateway;
    if (order.mock) {
      unawaited(
        AnalyticsService.logEvent('booking_payment_started', {
          'booking_id': widget.bookingId,
          'mock': true,
        }),
      );
    }

    setState(() {
      _stage = PayStage.processing;
      _error = null;
    });

    final outcome = await gateway.pay(
      context: context,
      orderId: order.orderId,
      amountPaise: order.amountPaise,
      bookingRef: order.bookingRef,
      contactPhone: SupabaseService.currentSession?.user.phone,
    );
    if (!mounted) return;

    if (outcome.success) {
      if (order.mock) {
        // Dev path: server marks the mock booking paid (gated on provider).
        await ref
            .read(bookingsRepoProvider)
            .confirmMockPayment(order.bookingId);
      }
      unawaited(
        AnalyticsService.logEvent('booking_payment_success', {
          'booking_id': widget.bookingId,
          'mock': order.mock,
        }),
      );
      await _checkStatus();
    } else {
      _handleFailure(outcome.errorMessage ?? 'Payment was not completed.');
    }
  }

  /// Polls check-payment-status until the server says paid (or timeout).
  Future<void> _checkStatus() async {
    unawaited(
      AnalyticsService.logEvent('booking_payment_status_checked', {
        'booking_id': widget.bookingId,
      }),
    );
    setState(() {
      _stage = PayStage.processing;
      _error = null;
    });
    for (var i = 0; i < _maxPolls; i++) {
      final result = await ref
          .read(bookingsRepoProvider)
          .checkPaymentStatus(widget.bookingId);
      if (!mounted) return;
      switch (result) {
        case Success(:final data):
          if (data.paid) {
            setState(() {
              _verified = data;
              _stage = PayStage.success;
            });
            ref.read(myBookingsProvider.notifier).refresh();
            return;
          }
          if (data.status == BookingStatus.cancelled) {
            setState(() {
              _stage = PayStage.failed;
              _error = 'This booking was cancelled. No payment was taken.';
            });
            return;
          }
        case Error():
          break;
      }
      await Future.delayed(_pollInterval);
      if (!mounted) return;
    }
    // Gateway/webhook latency exceeded: offer manual re-check (task 10.10).
    setState(() {
      _stage = PayStage.failed;
      _error =
          'We could not verify your payment yet. Tap "Check payment status" '
          'to confirm, or contact support.';
    });
  }

  void _handleFailure(String message) {
    _failedAttempts += 1;
    unawaited(
      AnalyticsService.logEvent('booking_payment_failed', {
        'booking_id': widget.bookingId,
        'attempt': _failedAttempts,
      }),
    );
    setState(() {
      _stage = PayStage.failed;
      _error = _failedAttempts >= _maxFailedAttempts
          ? 'Payment failed multiple times. Please try again later or '
                'contact support. You can also retry from My Bookings.'
          : message;
    });
  }

  void _retry() {
    unawaited(
      AnalyticsService.logEvent('booking_payment_retry', {
        'booking_id': widget.bookingId,
      }),
    );
    _createOrder();
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailProvider(widget.bookingId)).value;
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: switch (_stage) {
          PayStage.creating => const _LoadingBody(
            title: 'Creating your payment…',
            note: 'Contacting the payment gateway securely.',
          ),
          PayStage.ready => _ReadyBody(
            order: order!,
            booking: booking,
            onPay: _openCheckout,
          ),
          PayStage.processing => _LoadingBody(
            title: 'Checking payment status…',
            note: 'Please wait — do not close the app.',
            spinner: true,
          ),
          PayStage.success => _ReceiptBody(
            booking: booking,
            verified: _verified!,
            order: order,
            onBookings: () => context.go('/bookings'),
            onHome: () => context.go('/home'),
          ),
          PayStage.failed => _FailedBody(
            message: _error ?? 'Payment was not completed.',
            attempts: _failedAttempts,
            maxAttempts: _maxFailedAttempts,
            onRetry: _retry,
            onCheckStatus: _checkStatus,
            onBookings: () => context.go('/bookings'),
          ),
        },
      ),
    );
  }
}

// ---------------- ready: amount + pay ----------------

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.order,
    required this.booking,
    required this.onPay,
  });

  final BookingOrderDraft order;
  final Booking? booking;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final rupees = order.amountPaise ~/ 100;
    final demo = order.mock;
    final b = booking;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(KwSpacing.lg),
            children: [
              const SizedBox(height: KwSpacing.md),
              if (demo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: KwColors.goldLight,
                    borderRadius: BorderRadius.circular(KwRadius.chip),
                  ),
                  child: const Text(
                    'DEV MODE — MOCK PAYMENT (no real money)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: KwColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: KwSpacing.lg),
              ],
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
                          demo ? 'Simulated payment' : 'Secured by Razorpay',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: KwColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KwSpacing.xl),
              if (b != null) _BookingSummary(booking: b),
              const SizedBox(height: KwSpacing.md),
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(KwSpacing.lg),
                  child: Column(
                    children: [
                      _PerkRow(
                        icon: Icons.undo_rounded,
                        tint: KwColors.primaryLight,
                        fg: KwColors.primary,
                        title: 'Full refund if you cancel before the worker accepts',
                      ),
                      SizedBox(height: KwSpacing.md),
                      _PerkRow(
                        icon: Icons.verified_user_rounded,
                        tint: KwColors.greenLight,
                        fg: KwColors.green,
                        title:
                            'Service charge paid only after the work is done',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KwSpacing.md),
              Center(
                child: Text(
                  'Ref: ${order.bookingRef} • ${order.orderId}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: KwColors.muted),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KwSpacing.lg),
            child: KwButton(
              label: 'Pay ₹$rupees',
              onPressed: onPay,
              icon: Icons.currency_rupee_rounded,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- success: receipt (task 12) ----------------

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({
    required this.booking,
    required this.verified,
    required this.order,
    required this.onBookings,
    required this.onHome,
  });

  final Booking? booking;
  final BookingPaymentStatus verified;
  final BookingOrderDraft? order;
  final VoidCallback onBookings;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final amountPaise = verified.amountPaise ?? order?.amountPaise ?? 0;
    final paidAt = DateTime.now();
    final b = booking;
    return ListView(
      padding: const EdgeInsets.all(KwSpacing.lg),
      children: [
        const SizedBox(height: KwSpacing.md),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: KwColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 42,
              color: KwColors.green,
            ),
          ),
        ),
        const SizedBox(height: KwSpacing.md),
        Center(
          child: Text(
            'Payment successful',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: KwSpacing.xs),
        Center(
          child: Text(
            'Your booking request has been sent to the worker.\n'
            'Waiting for the worker to accept your request.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: KwColors.muted),
          ),
        ),
        const SizedBox(height: KwSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(KwSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment receipt',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: KwSpacing.md),
                _ReceiptRow(
                  label: 'Booking ID',
                  value:
                      '${verified.bookingRef} (${verified.bookingId.substring(0, 8)})',
                ),
                _ReceiptRow(
                  label: 'Amount paid',
                  value: '₹${amountPaise ~/ 100}',
                ),
                _ReceiptRow(
                  label: 'Payment method',
                  value: verified.mock
                      ? 'Mock (dev)'
                      : 'UPI / Cards / Netbanking',
                ),
                if (verified.transactionReference != null)
                  _ReceiptRow(
                    label: 'Transaction ID',
                    value: verified.transactionReference!,
                  ),
                if (verified.paymentId != null)
                  _ReceiptRow(label: 'Payment ID', value: verified.paymentId!),
                _ReceiptRow(
                  label: 'Date & time',
                  value: DateFormat('dd MMM yyyy, hh:mm a').format(paidAt),
                ),
                if (b != null) ...[
                  const Divider(height: KwSpacing.lg),
                  Text(
                    b.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (b.serviceDate != null)
                    Text(
                      '${DateFormat('dd MMM yyyy').format(b.serviceDate!)}'
                      ' • ${b.timeSlot}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: KwColors.muted),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: KwSpacing.lg),
        KwButton(
          label: 'View My Bookings',
          onPressed: onBookings,
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: KwSpacing.sm),
        KwButton(
          label: 'Go Home',
          variant: KwButtonVariant.secondary,
          onPressed: onHome,
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: KwSpacing.md),
      ],
    );
  }
}

// ---------------- failed: actionable retry ----------------

class _FailedBody extends StatelessWidget {
  const _FailedBody({
    required this.message,
    required this.attempts,
    required this.maxAttempts,
    required this.onRetry,
    required this.onCheckStatus,
    required this.onBookings,
  });

  final String message;
  final int attempts;
  final int maxAttempts;
  final VoidCallback onRetry;
  final VoidCallback onCheckStatus;
  final VoidCallback onBookings;

  @override
  Widget build(BuildContext context) {
    final tooMany = attempts >= maxAttempts;
    return ListView(
      padding: const EdgeInsets.all(KwSpacing.lg),
      children: [
        const SizedBox(height: KwSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: KwColors.redLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: KwColors.red,
            ),
          ),
        ),
        const SizedBox(height: KwSpacing.md),
        Center(
          child: Text(
            'Payment not completed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: KwSpacing.sm),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: KwColors.muted),
          ),
        ),
        const SizedBox(height: KwSpacing.md),
        Center(
          child: Text(
            'Your booking is safe — you can pay anytime from My Bookings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KwColors.muted),
          ),
        ),
        const SizedBox(height: KwSpacing.xl),
        if (!tooMany) ...[
          KwButton(
            label: 'Retry Payment',
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
          ),
          const SizedBox(height: KwSpacing.sm),
        ],
        KwButton(
          label: 'Check payment status',
          variant: KwButtonVariant.secondary,
          onPressed: onCheckStatus,
          icon: Icons.manage_search_rounded,
        ),
        const SizedBox(height: KwSpacing.sm),
        KwButton(
          label: 'My Bookings',
          variant: KwButtonVariant.ghost,
          onPressed: onBookings,
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }
}

// ---------------- bits ----------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    required this.title,
    required this.note,
    this.spinner = true,
  });

  final String title;
  final String note;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinner)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              const KwSkeleton(width: 32, height: 32, radius: KwRadius.pill),
            const SizedBox(height: KwSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.xs),
            Text(
              note,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final dateLine = [
      if (booking.serviceDate != null)
        DateFormat('dd MMM yyyy').format(booking.serviceDate!),
      if (booking.timeSlot.isNotEmpty) booking.timeSlot,
    ].join(' • ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: KwSpacing.md),
            _SummaryRow(label: 'Service', value: booking.category.labelEn),
            if (dateLine.isNotEmpty)
              _SummaryRow(label: 'When', value: dateLine),
            _SummaryRow(label: 'Address', value: booking.address, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KwSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KwSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
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
