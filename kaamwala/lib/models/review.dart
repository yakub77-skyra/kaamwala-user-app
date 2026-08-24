/// reviews + chat_messages + notifications models - Phase 3 section 7.1.
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

/// Text-only chat in MVP - FR-CHAT-01.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    this.createdAt,
  });

  static const String typeText = 'text';

  final String id;
  final String bookingId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as String,
    bookingId: map['booking_id'] as String,
    senderId: map['sender_id'] as String,
    content: (map['content'] ?? '') as String,
    isRead: (map['is_read'] ?? false) as bool,
    createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
  );
}

enum NotificationType { booking, payment, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    type: NotificationType.values.firstWhere(
      (t) => t.name == (map['type'] ?? 'system'),
      orElse: () => NotificationType.system,
    ),
    title: (map['title'] ?? '') as String,
    body: (map['body'] ?? '') as String,
    isRead: (map['is_read'] ?? false) as bool,
    createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
  );
}
