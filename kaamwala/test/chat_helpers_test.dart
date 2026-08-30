// Pure chat helpers: id generation, merge/dedup, draft validation, typing
// debounce (Phase 3).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala/features/chat/chat_helpers.dart';
import 'package:kaamwala/features/chat/models/chat_message.dart';

ChatMessage _msg(String id, DateTime at) => ChatMessage(
  id: id,
  bookingId: 'b-1',
  senderId: 'c1',
  type: ChatMessageType.text,
  content: 'm',
  createdAt: at,
);

void main() {
  group('chatLocalId', () {
    test('returns RFC-4122 v4 uuids, unique across calls', () {
      final a = chatLocalId();
      final b = chatLocalId();
      final re = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(re.hasMatch(a), isTrue, reason: a);
      expect(re.hasMatch(b), isTrue, reason: b);
      expect(a, isNot(b));
    });
  });

  group('mergeMessages', () {
    test('dedups by id and sorts ascending by createdAt', () {
      final t1 = DateTime(2026, 8, 25, 6);
      final t2 = DateTime(2026, 8, 25, 7);
      final t3 = DateTime(2026, 8, 25, 8);
      final merged = mergeMessages(
        [_msg('a', t1), _msg('b', t2)],
        [_msg('b', t2), _msg('c', t3)],
      );
      expect(merged.map((m) => m.id).toList(), ['a', 'b', 'c']);
    });

    test('newer copy of the same id wins (realtime update after insert)', () {
      final old = _msg('x', DateTime(2026, 8, 25, 6));
      final updated = old.copyWith(
        status: ChatMessageStatus.read,
        readAt: DateTime(2026, 8, 25, 6, 1),
      );
      final merged = mergeMessages([old], [updated]);
      expect(merged.single.status, ChatMessageStatus.read);
    });

    test('does not duplicate the same list twice', () {
      final msgs = [_msg('a', DateTime(2026)), _msg('b', DateTime(2026))];
      expect(mergeMessages(msgs, msgs).length, 2);
    });
  });

  group('validateTextDraft', () {
    test('trims whitespace', () {
      expect(validateTextDraft('  hello  '), 'hello');
    });

    test('rejects empty / whitespace-only messages', () {
      expect(
        () => validateTextDraft('   '),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => validateTextDraft(''),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test('rejects over-long messages', () {
      expect(
        () => validateTextDraft('x' * 1001),
        throwsA(isA<DraftValidationException>()),
      );
      expect(validateTextDraft('x' * 1000).length, 1000);
    });
  });

  group('TypingDebouncer', () {
    test('fires start once per burst and stops after idle timeout', () {
      fakeAsync((async) {
        final events = <bool>[];
        final debouncer = TypingDebouncer(
          stopAfter: const Duration(seconds: 3),
          onChange: events.add,
        );
        debouncer.onKeystroke();
        async.elapse(const Duration(milliseconds: 500));
        debouncer.onKeystroke();
        async.elapse(const Duration(milliseconds: 500));
        debouncer.onKeystroke();
        expect(events, [true]); // one start for the whole burst

        async.elapse(const Duration(seconds: 3));
        expect(events, [true, false]); // idle -> stop

        debouncer.dispose();
      });
    });

    test('explicit stop fires immediately (message sent)', () {
      fakeAsync((async) {
        final events = <bool>[];
        final debouncer = TypingDebouncer(onChange: events.add);
        debouncer.onKeystroke();
        debouncer.stop();
        expect(events, [true, false]);
        debouncer.dispose();
      });
    });

    test('stop after already-stopped does not re-fire', () {
      final events = <bool>[];
      final debouncer = TypingDebouncer(onChange: events.add);
      debouncer.stop();
      expect(events, isEmpty);
      debouncer.dispose();
    });
  });
}
