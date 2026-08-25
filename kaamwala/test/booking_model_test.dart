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

    test('unknown/missing status falls back to pending', () {
      expect(
        Booking.fromMap({'id': 'x', 'status': 'weird'}).status,
        BookingStatus.pending,
      );
      expect(Booking.fromMap({'id': 'x'}).status, BookingStatus.pending);
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
        BookingStatus.pending,
        BookingStatus.accepted,
        BookingStatus.traveling,
        BookingStatus.arrived,
        BookingStatus.inProgress,
      ]) {
        expect(s.isActive, isTrue);
      }
    });
  });

  group('cancel gating', () {
    test('canCancel only while pending', () {
      expect(
        Booking.fromMap({'id': 'x', 'status': 'pending'}).canCancel,
        isTrue,
      );
      expect(
        Booking.fromMap({'id': 'x', 'status': 'accepted'}).canCancel,
        isFalse,
      );
      expect(_fullRow().canCancel, isFalse); // in_progress
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
