// AppNotification model + deep-link route resolution (Phase 3).
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/features/notifications/models/app_notification.dart';

AppNotification _row({
  String type = 'new_message',
  Map<String, dynamic>? data,
  String? actionRoute,
  bool isRead = false,
}) => AppNotification.fromMap({
  'id': 'n-1',
  'user_id': 'u-1',
  'type': type,
  'title': 'Hi',
  'body': 'Body',
  'data_json': data,
  'action_route': actionRoute,
  'is_read': isRead,
  'created_at': '2026-08-25T06:30:00Z',
});

void main() {
  group('AppNotification.fromMap', () {
    test('parses a full row incl. payload + route', () {
      final n = _row(
        data: {'booking_id': 'b-1', 'message_id': 'm-1'},
        actionRoute: '/chat/b-1',
      );
      expect(n.id, 'n-1');
      expect(n.type, AppNotificationType.newMessage);
      expect(n.bookingId, 'b-1');
      expect(n.actionRoute, '/chat/b-1');
      expect(n.createdAt, isNotNull);
    });

    test('unknown type falls back to system', () {
      expect(_row(type: 'spam').type, AppNotificationType.system);
    });

    test('legacy types still parse (booking/payment)', () {
      expect(_row(type: 'booking').type, AppNotificationType.booking);
      expect(_row(type: 'payment').type, AppNotificationType.payment);
    });
  });

  group('resolveRoute / defaultRouteFor', () {
    test('explicit action_route wins', () {
      final n = _row(actionRoute: '/w/jobs');
      expect(n.resolveRoute(), '/w/jobs');
    });

    test('new_message defaults to the booking chat', () {
      final n = _row(data: {'booking_id': 'b-1'});
      expect(n.resolveRoute(), '/chat/b-1');
    });

    test('payment pending/failed go to the payment screen', () {
      expect(
        defaultRouteFor(AppNotificationType.paymentPending, {
          'booking_id': 'b1',
        }),
        '/payment/b1',
      );
      expect(
        defaultRouteFor(AppNotificationType.paymentFailed, {
          'booking_id': 'b1',
        }),
        '/payment/b1',
      );
    });

    test('booking lifecycle events go to the booking detail', () {
      for (final t in [
        AppNotificationType.bookingCreated,
        AppNotificationType.bookingDeclined,
        AppNotificationType.bookingCancelled,
        AppNotificationType.paymentSuccess,
        AppNotificationType.booking,
        AppNotificationType.payment,
      ]) {
        expect(defaultRouteFor(t, {'booking_id': 'b1'}), '/booking/b1');
      }
    });

    test('worker approval events go to the worker dashboard', () {
      expect(
        defaultRouteFor(AppNotificationType.workerApproved, {}),
        '/w/home',
      );
      expect(
        defaultRouteFor(AppNotificationType.workerRejected, {}),
        '/w/home',
      );
    });

    test('missing booking id degrades to /bookings or /notifications', () {
      expect(
        defaultRouteFor(AppNotificationType.newMessage, {}),
        '/notifications',
      );
      expect(
        defaultRouteFor(AppNotificationType.paymentSuccess, {}),
        '/bookings',
      );
    });
  });
}
