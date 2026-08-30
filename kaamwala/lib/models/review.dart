/// Review model (FR-CLIENT-08).
///
/// Chat + notification models moved to their feature folders in Phase 3:
///  - features/chat/models/chat_message.dart
///  - features/notifications/models/app_notification.dart
library;

class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.workerId,
    required this.clientId,
    required this.rating,
    this.text = '',
    this.tags = const [],
  });

  final String id;
  final String bookingId;

  /// UNIQUE per booking - one review per booking (FR-CLIENT-08).
  final String workerId;
  final String clientId;
  final int rating;
  final String text;
  final List<String> tags;

  factory Review.fromMap(Map<String, dynamic> map) => Review(
    id: map['id'] as String,
    bookingId: map['booking_id'] as String,
    workerId: map['worker_id'] as String,
    clientId: map['client_id'] as String,
    rating: (map['rating'] ?? 0) as int,
    text: (map['text'] ?? '') as String,
    tags: [
      for (final t in (map['tags'] as List<dynamic>? ?? const [])) t as String,
    ],
  );
}
