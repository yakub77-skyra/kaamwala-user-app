// ChatMessage model parsing + status/type semantics (Phase 3).
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/features/chat/models/chat_message.dart';

ChatMessage _textRow({String type = 'text'}) => ChatMessage.fromMap({
  'id': 'm-1',
  'booking_id': 'b-1',
  'sender_id': 'c1',
  'receiver_id': 'w1',
  'message_type': type,
  'content': 'Hello',
  'status': 'sent',
  'is_read': false,
  'created_at': '2026-08-25T06:30:00Z',
});

void main() {
  group('ChatMessage.fromMap', () {
    test('parses a text row', () {
      final m = _textRow();
      expect(m.id, 'm-1');
      expect(m.type, ChatMessageType.text);
      expect(m.content, 'Hello');
      expect(m.status, ChatMessageStatus.sent);
      expect(m.createdAt, isNotNull);
      expect(m.isLocal, isFalse);
    });

    test('parses image + location rows with their payloads', () {
      final img = ChatMessage.fromMap({
        'id': 'm-2',
        'booking_id': 'b-1',
        'sender_id': 'c1',
        'message_type': 'image',
        'content': 'Photo',
        'image_url': 'chat/b-1/m-2.jpg',
        'thumbnail_url': 'chat/b-1/m-2.jpg',
        'metadata_json': {'size': 1024},
        'status': 'read',
        'read_at': '2026-08-25T06:31:00Z',
      });
      expect(img.type, ChatMessageType.image);
      expect(img.imageUrl, 'chat/b-1/m-2.jpg');
      expect(img.metadata['size'], 1024);
      expect(img.status, ChatMessageStatus.read);
      expect(img.readAt, isNotNull);

      final loc = ChatMessage.fromMap({
        'id': 'm-3',
        'booking_id': 'b-1',
        'sender_id': 'w1',
        'message_type': 'location',
        'content': 'Kharadi, Pune',
        'location_lat': 18.55,
        'location_lng': 73.94,
        'location_label': 'Kharadi, Pune',
      });
      expect(loc.type, ChatMessageType.location);
      expect(loc.locationLat, 18.55);
      expect(loc.locationLng, 73.94);
      expect(loc.locationLabel, 'Kharadi, Pune');
    });

    test('unknown type/status fall back safely', () {
      final m = ChatMessage.fromMap({
        'id': 'm-4',
        'booking_id': 'b-1',
        'message_type': 'video',
        'status': 'flying',
      });
      expect(m.type, ChatMessageType.text);
      expect(m.status, ChatMessageStatus.sent);
      expect(m.isSystem, isFalse);
    });

    test('system rows parse and are flagged', () {
      final m = ChatMessage.fromMap({
        'id': 'm-5',
        'booking_id': 'b-1',
        'message_type': 'system',
        'content': 'Booking accepted',
        'status': 'sent',
      });
      expect(m.isSystem, isTrue);
      expect(m.senderId, isNull);
    });
  });

  group('ChatMessage status helpers', () {
    test('local optimistic message reports isSending', () {
      final m = ChatMessage(
        id: 'm-6',
        bookingId: 'b-1',
        senderId: 'c1',
        type: ChatMessageType.text,
        content: 'hi',
        status: ChatMessageStatus.sending,
        isLocal: true,
        createdAt: DateTime.now(),
      );
      expect(m.isLocal, isTrue);
      expect(m.isSending, isTrue);
      expect(m.isFailed, isFalse);
    });

    test('failed message reports failed, not sending', () {
      final m = _textRow().copyWith(status: ChatMessageStatus.failed);
      expect(m.isFailed, isTrue);
      expect(m.isSending, isFalse);
    });

    test('copyWith flips fields and keeps id (idempotent retry identity)', () {
      final m = _textRow().copyWith(status: ChatMessageStatus.failed);
      expect(m.id, 'm-1');
      expect(m.status, ChatMessageStatus.failed);
    });
  });

  group('ChatMessage.toInsertMap', () {
    test('carries client id + typed payload', () {
      final m = ChatMessage(
        id: 'm-7',
        bookingId: 'b-1',
        senderId: 'c1',
        receiverId: 'w1',
        type: ChatMessageType.location,
        content: 'Pune',
        locationLat: 18.5,
        locationLng: 73.9,
        locationLabel: 'Pune',
        metadata: {'accuracy': 12.5},
        status: ChatMessageStatus.sent,
      );
      final map = m.toInsertMap();
      expect(map['id'], 'm-7');
      expect(map['message_type'], 'location');
      expect(map['location_lat'], 18.5);
      expect(map['location_lng'], 73.9);
      expect(map['location_label'], 'Pune');
      expect(map['metadata_json'], {'accuracy': 12.5});
      expect(map['sent_at'], isNotNull);
    });
  });
}
