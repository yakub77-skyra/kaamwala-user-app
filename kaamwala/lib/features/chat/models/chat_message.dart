/// Chat message model - Phase 3: text/image/location/system + delivery state.
library;

import 'dart:typed_data';

enum ChatMessageType {
  text,
  image,
  location,
  system;

  static ChatMessageType fromDb(String? raw) => ChatMessageType.values
      .firstWhere((t) => t.name == raw, orElse: () => ChatMessageType.text);

  String get dbValue => name;
}

/// Server-persisted lifecycle (sent/delivered/read/failed). [sending] is a
/// client-only optimistic state - never written to the DB.
enum ChatMessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static ChatMessageStatus fromDb(String? raw) => ChatMessageStatus.values
      .firstWhere((t) => t.name == raw, orElse: () => ChatMessageStatus.sent);

  String get dbValue => name;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    this.senderId,
    this.receiverId,
    this.type = ChatMessageType.text,
    this.content = '',
    this.imageUrl,
    this.thumbnailUrl,
    this.locationLat,
    this.locationLng,
    this.locationLabel,
    this.metadata = const {},
    this.status = ChatMessageStatus.sent,
    this.isRead = false,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.createdAt,
    this.uploadProgress,
    this.isLocal = false,
  });

  /// Client-generated uuid -> idempotent retry (re-insert same id never
  /// duplicates).
  final String id;
  final String bookingId;
  final String? senderId;
  final String? receiverId;
  final ChatMessageType type;
  final String content;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? locationLat;
  final double? locationLng;
  final String? locationLabel;

  /// Free-form jsonb (image size, width/height, ...).
  final Map<String, dynamic> metadata;
  final ChatMessageStatus status;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? createdAt;

  /// Client-only: 0..1 upload progress of an outgoing image.
  final double? uploadProgress;

  /// Optimistic row created on-device; not yet confirmed by the server.
  final bool isLocal;

  bool get isSystem => type == ChatMessageType.system;

  bool get isFailed => status == ChatMessageStatus.failed;

  bool get isSending =>
      status == ChatMessageStatus.sending ||
      (isLocal && status != ChatMessageStatus.failed);

  ChatMessage copyWith({
    String? id,
    String? bookingId,
    String? senderId,
    String? receiverId,
    ChatMessageType? type,
    String? content,
    String? imageUrl,
    String? thumbnailUrl,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    Map<String, dynamic>? metadata,
    ChatMessageStatus? status,
    bool? isRead,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? createdAt,
    double? uploadProgress,
    bool clearUploadProgress = false,
    bool? isLocal,
  }) => ChatMessage(
    id: id ?? this.id,
    bookingId: bookingId ?? this.bookingId,
    senderId: senderId ?? this.senderId,
    receiverId: receiverId ?? this.receiverId,
    type: type ?? this.type,
    content: content ?? this.content,
    imageUrl: imageUrl ?? this.imageUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    locationLat: locationLat ?? this.locationLat,
    locationLng: locationLng ?? this.locationLng,
    locationLabel: locationLabel ?? this.locationLabel,
    metadata: metadata ?? this.metadata,
    status: status ?? this.status,
    isRead: isRead ?? this.isRead,
    sentAt: sentAt ?? this.sentAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt ?? this.createdAt,
    uploadProgress: clearUploadProgress
        ? null
        : uploadProgress ?? this.uploadProgress,
    isLocal: isLocal ?? this.isLocal,
  );

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: (map['id'] ?? '') as String,
    bookingId: (map['booking_id'] ?? '') as String,
    senderId: map['sender_id'] as String?,
    receiverId: map['receiver_id'] as String?,
    type: ChatMessageType.fromDb(map['message_type'] as String?),
    content: (map['content'] ?? '') as String,
    imageUrl: map['image_url'] as String?,
    thumbnailUrl: map['thumbnail_url'] as String?,
    locationLat: (map['location_lat'] as num?)?.toDouble(),
    locationLng: (map['location_lng'] as num?)?.toDouble(),
    locationLabel: map['location_label'] as String?,
    metadata: Map<String, dynamic>.from(map['metadata_json'] as Map? ?? {}),
    status: ChatMessageStatus.fromDb(map['status'] as String?),
    isRead: (map['is_read'] ?? false) as bool,
    sentAt: DateTime.tryParse((map['sent_at'] ?? '') as String),
    deliveredAt: DateTime.tryParse((map['delivered_at'] ?? '') as String),
    readAt: DateTime.tryParse((map['read_at'] ?? '') as String),
    createdAt: DateTime.tryParse((map['created_at'] ?? '') as String),
  );

  Map<String, dynamic> toInsertMap() => {
    'id': id,
    'booking_id': bookingId,
    if (senderId != null) 'sender_id': senderId,
    if (receiverId != null) 'receiver_id': receiverId,
    'message_type': type.dbValue,
    'content': content,
    if (imageUrl != null) 'image_url': imageUrl,
    if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    if (locationLat != null) 'location_lat': locationLat,
    if (locationLng != null) 'location_lng': locationLng,
    if (locationLabel != null && locationLabel!.isNotEmpty)
      'location_label': locationLabel,
    if (metadata.isNotEmpty) 'metadata_json': metadata,
    'status': status.dbValue,
    'sent_at': DateTime.now().toUtc().toIso8601String(),
  };
}

/// A draft ready to send - typed payload before it becomes a ChatMessage.
sealed class ChatDraft {
  const ChatDraft();
}

class TextDraft extends ChatDraft {
  const TextDraft(this.text);
  final String text;
}

class ImageDraft extends ChatDraft {
  const ImageDraft({
    required this.bytes,
    required this.mimeType,
    this.name = 'image.jpg',
  });
  final Uint8List bytes;
  final String mimeType;
  final String name;
}

class LocationDraft extends ChatDraft {
  const LocationDraft({
    required this.lat,
    required this.lng,
    this.label,
    this.accuracy,
  });
  final double lat;
  final double lng;
  final String? label;
  final double? accuracy;
}

/// Failure marker for draft validation (empty text etc.).
class DraftValidationException implements Exception {
  const DraftValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}
