/// App notification model - Phase 3: typed, deep-linkable, DB-backed.
library;

enum AppNotificationType {
  booking('booking'),
  payment('payment'),
  system('system'),
  newMessage('new_message'),
  bookingCreated('booking_created'),
  paymentPending('payment_pending'),
  paymentSuccess('payment_success'),
  paymentFailed('payment_failed'),
  bookingDeclined('booking_declined'),
  bookingCancelled('booking_cancelled'),
  workerApproved('worker_approved'),
  workerRejected('worker_rejected');

  const AppNotificationType(this.dbValue);
  final String dbValue;

  static AppNotificationType fromDb(String? raw) =>
      AppNotificationType.values.firstWhere(
        (t) => t.dbValue == raw,
        orElse: () => AppNotificationType.system,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.dataJson = const {},
    this.actionRoute,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> dataJson;
  final String? actionRoute;
  final bool isRead;
  final DateTime? createdAt;

  String? get bookingId => dataJson['booking_id'] as String?;

  /// Deep-link target: explicit action_route when present, else a sensible
  /// default per type (legacy rows without routes).
  String resolveRoute() => actionRoute ?? defaultRouteFor(type, dataJson);

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    dataJson: dataJson,
    actionRoute: actionRoute,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: (map['id'] ?? '') as String,
    userId: (map['user_id'] ?? '') as String,
    type: AppNotificationType.fromDb(map['type'] as String?),
    title: (map['title'] ?? '') as String,
    body: (map['body'] ?? '') as String,
    dataJson: Map<String, dynamic>.from(map['data_json'] as Map? ?? {}),
    actionRoute: map['action_route'] as String?,
    isRead: (map['is_read'] ?? false) as bool,
    createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
  );
}

/// Type-based fallback route (used when the row has no action_route).
/// Pure - unit-tested.
String defaultRouteFor(AppNotificationType type, Map<String, dynamic> data) {
  final bookingId = data['booking_id'] as String?;
  switch (type) {
    case AppNotificationType.newMessage:
      return bookingId == null ? '/notifications' : '/chat/$bookingId';
    case AppNotificationType.paymentPending:
    case AppNotificationType.paymentFailed:
      return bookingId == null ? '/bookings' : '/payment/$bookingId';
    case AppNotificationType.bookingCreated:
    case AppNotificationType.bookingDeclined:
    case AppNotificationType.bookingCancelled:
    case AppNotificationType.paymentSuccess:
    case AppNotificationType.booking:
    case AppNotificationType.payment:
      return bookingId == null ? '/bookings' : '/booking/$bookingId';
    case AppNotificationType.workerApproved:
    case AppNotificationType.workerRejected:
      return '/w/home';
    case AppNotificationType.system:
      return '/notifications';
  }
}
