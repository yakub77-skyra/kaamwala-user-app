/// Mock payment gateway (Phase 2 task 17) - dev-only simulation.
///
/// Mirrors the Phase 1 MockSmsGateway pattern: when the app runs in demo
/// payment mode, this gateway shows a clearly-labelled DEV sheet where the
/// tester picks "Simulate success" / "Simulate failure" / "Cancel".
///
/// The mock order id comes from the SERVER (create-order returns
/// `mock_<bookingId>` when Razorpay keys are absent), so no amount logic
/// lives here - the sheet only triggers the outcome.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/core/ui/kw_button.dart';

import 'payment_gateway.dart';
import 'payment_result.dart';

/// Simulated processing delay so progress states are visible.
const Duration kMockPaymentDelay = Duration(milliseconds: 1200);

class MockPaymentGateway implements PaymentGateway {
  const MockPaymentGateway({this.autoResult});

  /// When set, skips the interactive sheet and returns the given result
  /// after [kMockPaymentDelay] (used by tests). Null => interactive sheet.
  final bool? autoResult;

  @override
  bool get isDemoMode => true;

  @override
  Future<PaymentOutcome> pay({
    required BuildContext context,
    required String orderId,
    required int amountPaise,
    required String bookingRef,
    String? contactPhone,
  }) {
    if (autoResult != null) {
      return Future.delayed(kMockPaymentDelay, () {
        return autoResult!
            ? PaymentOutcome.success(paymentId: 'mock_pay_test')
            : const PaymentOutcome.failure(
                message: 'Payment failed. You can retry.',
                code: 'mock_failure',
              );
      });
    }
    final completer = Completer<PaymentOutcome>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (sheetContext) => _MockSheet(
        orderId: orderId,
        amountPaise: amountPaise,
        bookingRef: bookingRef,
        onDone: completer.complete,
      ),
    ).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete(
          const PaymentOutcome.failure(
            message: 'Payment was not completed. You can retry.',
            code: 'cancelled',
          ),
        );
      }
    });
    return completer.future;
  }
}

class _MockSheet extends StatefulWidget {
  const _MockSheet({
    required this.orderId,
    required this.amountPaise,
    required this.bookingRef,
    required this.onDone,
  });

  final String orderId;
  final int amountPaise;
  final String bookingRef;
  final ValueChanged<PaymentOutcome> onDone;

  @override
  State<_MockSheet> createState() => _MockSheetState();
}

class _MockSheetState extends State<_MockSheet> {
  bool _busy = false;

  Future<void> _finish(PaymentOutcome outcome) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (kDebugMode) {
      debugPrint(
        '💳 [MOCK PAYMENT] ${outcome.success ? "success" : "failure"} '
        'order=${widget.orderId} amount=${widget.amountPaise}',
      );
    }
    await Future.delayed(kMockPaymentDelay);
    widget.onDone(outcome);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rupees = widget.amountPaise ~/ 100;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KwSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KwColors.goldLight,
                    borderRadius: BorderRadius.circular(KwRadius.chip),
                  ),
                  child: const Text(
                    'DEV / MOCK PAYMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: KwColors.gold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: KwColors.muted,
                ),
              ],
            ),
            const SizedBox(height: KwSpacing.md),
            Text(
              'Simulate payment of ₹$rupees',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: KwSpacing.xs),
            Text(
              '${widget.bookingRef} • ${widget.orderId}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KwColors.muted),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              'This is a development simulation. No real money moves.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: KwColors.muted),
            ),
            const SizedBox(height: KwSpacing.lg),
            KwButton(
              label: 'Simulate success',
              icon: Icons.check_circle_rounded,
              onPressed: _busy
                  ? null
                  : () => _finish(
                      PaymentOutcome.success(
                        paymentId: 'mock_pay_${widget.orderId}',
                      ),
                    ),
            ),
            const SizedBox(height: KwSpacing.sm),
            KwButton(
              label: 'Simulate failure',
              variant: KwButtonVariant.secondary,
              icon: Icons.error_outline_rounded,
              onPressed: _busy
                  ? null
                  : () => _finish(
                      const PaymentOutcome.failure(
                        message: 'Payment failed (simulated). You can retry.',
                        code: 'mock_failure',
                      ),
                    ),
            ),
            const SizedBox(height: KwSpacing.sm),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
