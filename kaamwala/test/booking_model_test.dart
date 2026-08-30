// Model parsing - DB rows are the app's single source of truth for money and
// lifecycle state; a parse regression silently corrupts both.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/core/constants/app_constants.dart';
import 'package:kaamwala/models/booking.dart';

Booking _fullRow() => Booking.fromMap({
  'id': 'b-1',
  'ref': 'KW-2026-0148',
  'client_id': 'c1',
  'worker_id': 'w1',
  'category': 'carpenter',
  'description': 'Fix wardrobe door',
  'service_date': '2026-09-01',
  'time_slot': '10-12',
  'address': 'Kharadi, Pune',
  'status': 'in_progress',
  'estimate_min': 400,
  'estimate_max': 800,
  'booking_fee': 20,
  'commission_rate': 0.10,
  'commission_amount': 36,
  'worker_earning': 324,
  'client_confirmed': true,
  'created_at': '2026-08-25T06:30:00Z',
  'users': {'name': 'Asha'},
  'workers': {
    'users': {'name': 'Ramesh', 'photo_url': 'https://x/y.png'},
  },
});

void main() {
  group('Booking.fromMap', () {
    test('parses full row incl. counterpart embeds', () {
      final b = _fullRow();
      expect(b.id, 'b-1');
      expect(b.ref, 'KW-2026-0148');
      expect(b.category, ServiceCategory.carpenter);
      expect(b.status, BookingStatus.inProgress);
      expect(b.estimateMin, 400);
      expect(b.estimateMax, 800);
      expect(b.commissionAmount, 36);
      expect(b.workerEarning, 324);
      expect(b.clientConfirmed, isTrue);
      expect(b.clientName, 'Asha');
      expect(b.workerName, 'Ramesh');
      expect(b.workerPhoto, 'https://x/y.png');
      expect(b.createdAt, isNotNull);
    });

    test(
      'money defaults: server-computed fields default to 0, fee to Rs.20',
      () {
        final b = Booking.fromMap({
          'id': 'b-2',
          'client_id': 'c1',
          'worker_id': 'w1',
        });
        expect(b.bookingFee, AppConstants.bookingFeeRupees);
        expect(b.commissionRate, AppConstants.commissionRate);
        expect(b.commissionAmount, 0);
        expect(b.workerEarning, 0);
      },
    );

    test('unknown/missing status falls back to payment_pending', () {
      expect(
        Booking.fromMap({'id': 'x', 'status': 'weird'}).status,
        BookingStatus.paymentPending,
      );
      expect(Booking.fromMap({'id': 'x'}).status, BookingStatus.paymentPending);
      // Legacy 'pending' rows still parse as pending (Phase 1 compat).
      expect(
        Booking.fromMap({'id': 'x', 'status': 'pending'}).status,
        BookingStatus.pending,
      );
    });

    test('payment fields parse from row', () {
      final b = Booking.fromMap({
        'id': 'x',
        'status': 'pending_acceptance',
        'payment_status': 'paid',
        'payment_provider': 'razorpay',
        'payment_order_id': 'order_X',
        'payment_id': 'pay_Y',
        'payment_signature_verified': true,
        'amount_paise': 2000,
        'booking_fee_paise': 2000,
        'estimated_min_paise': 30000,
        'estimated_max_paise': 80000,
        'payment_attempts': 2,
        'payment_error_message': 'declined',
        'payment_expires_at': '2026-08-25T07:30:00Z',
        'transaction_reference': 'pay_Y',
        'cancellation_reason': 'Worker not responding',
        'cancelled_at': '2026-08-25T08:00:00Z',
        'refund_status': 'pending',
        'refund_message': 'Refund initiated',
      });
      expect(b.status, BookingStatus.pendingAcceptance);
      expect(b.paymentStatus, PaymentStatus.paid);
      expect(b.paymentProvider, 'razorpay');
      expect(b.paymentOrderId, 'order_X');
      expect(b.paymentId, 'pay_Y');
      expect(b.paymentSignatureVerified, isTrue);
      expect(b.amountPaise, 2000);
      expect(b.bookingFeePaise, 2000);
      expect(b.estimateMinPaise, 30000);
      expect(b.paymentAttempts, 2);
      expect(b.paymentErrorMessage, 'declined');
      expect(b.paymentExpiresAt, isNotNull);
      expect(b.transactionReference, 'pay_Y');
      expect(b.cancellationReason, 'Worker not responding');
      expect(b.cancelledAt, isNotNull);
      expect(b.refundStatus, RefundStatus.pending);
      expect(b.refundMessage, 'Refund initiated');
      expect(b.needsPayment, isFalse);
    });

    test('missing payment fields default safely', () {
      final b = Booking.fromMap({'id': 'x'});
      expect(b.paymentStatus, PaymentStatus.pending);
      expect(b.paymentAttempts, 0);
      expect(b.refundStatus, isNull);
      expect(b.amountPaise, isNull);
    });

    test('missing embeds yield empty names, not crashes', () {
      final b = Booking.fromMap({'id': 'x'});
      expect(b.clientName, '');
      expect(b.workerName, '');
      expect(b.workerPhoto, isNull);
    });
  });

  group('BookingStatus round-trip', () {
    test('every db value survives enum->db->enum', () {
      for (final s in BookingStatus.values) {
        expect(BookingStatus.fromDb(s.dbValue), s);
      }
    });

    test('isActive matches terminal set', () {
      expect(BookingStatus.completed.isActive, isFalse);
      expect(BookingStatus.cancelled.isActive, isFalse);
      expect(BookingStatus.declined.isActive, isFalse);
      for (final s in [
        BookingStatus.paymentPending,
        BookingStatus.paymentFailed,
        BookingStatus.pendingAcceptance,
        BookingStatus.pending,
        BookingStatus.accepted,
        BookingStatus.traveling,
        BookingStatus.arrived,
        BookingStatus.inProgress,
      ]) {
        expect(s.isActive, isTrue);
      }
    });

    test('occupiesSlot covers the booking window', () {
      expect(BookingStatus.paymentPending.occupiesSlot, isTrue);
      expect(BookingStatus.paymentFailed.occupiesSlot, isTrue);
      expect(BookingStatus.pendingAcceptance.occupiesSlot, isTrue);
      expect(BookingStatus.inProgress.occupiesSlot, isTrue);
      expect(BookingStatus.completed.occupiesSlot, isFalse);
      expect(BookingStatus.cancelled.occupiesSlot, isFalse);
      expect(BookingStatus.declined.occupiesSlot, isFalse);
    });
  });

  group('cancel gating', () {
    test('canCancel before worker acceptance (Phase 2 states)', () {
      expect(
        Booking.fromMap({'id': 'x', 'status': 'pending'}).canCancel,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'payment_pending'}).canCancel,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'payment_failed'}).canCancel,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'pending_acceptance'}).canCancel,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'accepted'}).canCancel,
        isFalse,
      );
      expect(_fullRow().canCancel, isFalse); // in_progress
    });

    test('needsPayment only for unpaid pre-acceptance states', () {
      expect(
        Booking.fromMap({'id': 'x', 'status': 'payment_pending'}).needsPayment,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'payment_failed'}).needsPayment,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'pending_acceptance'})
            .needsPayment,
        isFalse,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'completed'}).needsPayment,
        isFalse,
      );
    });

    test('refundNote only on cancelled bookings', () {
      final cancelled = Booking.fromMap({
        'id': 'x',
        'status': 'cancelled',
        'refund_status': 'pending',
        'refund_message': 'Refund initiated — 3-5 business days',
      });
      expect(cancelled.refundNote, contains('3-5 business days'));
      expect(
        Booking.fromMap({
          'id': 'x',
          'status': 'cancelled',
          'refund_status': 'processed',
        }).refundNote,
        'Refund completed',
      );
      // Never paid -> no refund note.
      expect(
        Booking.fromMap({'id': 'x', 'status': 'cancelled'}).refundNote,
        isNull,
      );
      // Active booking -> no note.
      expect(_fullRow().refundNote, isNull);
    });
  });

  group('BookingOrderDraft.fromMap', () {
    test('parses server order response incl. mock flag', () {
      final d = BookingOrderDraft.fromMap({
        'order_id': 'mock_b1',
        'amount': 2000,
        'currency': 'INR',
        'booking_id': 'b1',
        'booking_ref': 'KW-2026-0001',
        'mock': true,
      });
      expect(d.orderId, 'mock_b1');
      expect(d.amountPaise, 2000);
      expect(d.bookingId, 'b1');
      expect(d.mock, isTrue);
      expect(d.keyId, '');
    });
  });

  group('BookingPaymentStatus.fromMap', () {
    test('parses paid state with references', () {
      final s = BookingPaymentStatus.fromMap({
        'booking_id': 'b1',
        'booking_ref': 'KW-2026-0001',
        'status': 'pending_acceptance',
        'payment_status': 'paid',
        'paid': true,
        'mock': false,
        'amount_paise': 2000,
        'payment_id': 'pay_X',
        'transaction_reference': 'pay_X',
      });
      expect(s.paid, isTrue);
      expect(s.status, BookingStatus.pendingAcceptance);
      expect(s.paymentStatus, PaymentStatus.paid);
      expect(s.transactionReference, 'pay_X');
      expect(s.mock, isFalse);
    });
  });

  group('PaymentOrder.fromMap', () {
    test('parses paid order with ids and amount', () {
      final o = PaymentOrder.fromMap({
        'id': 'o1',
        'booking_id': 'b1',
        'razorpay_order_id': 'order_X',
        'razorpay_payment_id': 'pay_Y',
        'amount': 2000,
        'status': 'paid',
        'paid_at': '2026-08-25T07:00:00Z',
      });
      expect(o.status, OrderStatus.paid);
      expect(o.amount, 2000);
      expect(o.razorpayOrderId, 'order_X');
      expect(o.paidAt, isNotNull);
    });

    test('uppercase/unknown status falls back to created', () {
      expect(
        PaymentOrder.fromMap(_orderRow('CREATED')).status,
        OrderStatus.created,
      );
      expect(
        PaymentOrder.fromMap(_orderRow('PAID')).status,
        OrderStatus.created,
      );
    });
  });

  group('Payout.fromMap', () {
    test('parses amount + lowercase status from server', () {
      final p = Payout.fromMap({
        'id': 'p1',
        'booking_id': 'b1',
        'worker_id': 'w1',
        'amount': 324,
        'status': 'processing',
      });
      expect(p.amount, 324);
      expect(p.status, PayoutStatus.processing);
    });

    test('missing status -> pending', () {
      expect(
        Payout.fromMap({
          'id': 'p2',
          'booking_id': 'b1',
          'worker_id': 'w1',
          'amount': 100,
        }).status,
        PayoutStatus.pending,
      );
    });
  });
}

Map<String, dynamic> _orderRow(String status) => {
  'id': 'o1',
  'booking_id': 'b1',
  'amount': 2000,
  'status': status,
};
