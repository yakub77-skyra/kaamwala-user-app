// Phase 2 task 17/20: mock payment gateway success/failure paths.
// The autoResult mode drives the same decision logic the interactive
// dev sheet uses, minus the UI (so no BuildContext is touched).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/services/payment/mock_payment_gateway.dart';

/// BuildContext stand-in: never dereferenced in autoResult mode.
class _NoopContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('MockPaymentGateway', () {
    final ctx = _NoopContext();

    test('is always demo mode (never shown as real payment)', () {
      expect(const MockPaymentGateway().isDemoMode, isTrue);
      expect(const MockPaymentGateway(autoResult: true).isDemoMode, isTrue);
    });

    test('success path returns a payment id', () async {
      final gw = MockPaymentGateway(autoResult: true);
      final outcome = await gw.pay(
        context: ctx,
        orderId: 'mock_b1',
        amountPaise: 2000,
        bookingRef: 'KW-2026-0001',
      );
      expect(outcome.success, isTrue);
      expect(outcome.paymentId, isNotNull);
      expect(outcome.errorMessage, isNull);
    });

    test('failure path returns a user-facing message', () async {
      final gw = MockPaymentGateway(autoResult: false);
      final outcome = await gw.pay(
        context: ctx,
        orderId: 'mock_b1',
        amountPaise: 2000,
        bookingRef: 'KW-2026-0001',
      );
      expect(outcome.success, isFalse);
      expect(outcome.errorMessage, isNotNull);
      expect(outcome.errorCode, 'mock_failure');
    });

    test(
      'simulates a processing delay (progress states stay visible)',
      () async {
        final gw = MockPaymentGateway(autoResult: true);
        final sw = Stopwatch()..start();
        await gw.pay(
          context: ctx,
          orderId: 'mock_b1',
          amountPaise: 2000,
          bookingRef: 'KW-2026-0001',
        );
        sw.stop();
        expect(sw.elapsed, greaterThanOrEqualTo(kMockPaymentDelay));
      },
    );
  });
}
