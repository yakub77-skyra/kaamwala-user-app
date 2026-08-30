/// Pure chat helpers - no Supabase/Flutter dependencies (unit-testable).
library;

import 'dart:async';
import 'dart:math';

import 'package:kaamwala/features/chat/models/chat_message.dart';

/// RFC-4122 v4 uuid (chat_messages.id is a uuid column). Client-generated so
/// retries can re-insert the same id idempotently.
String chatLocalId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Merges [incoming] rows into [existing] by id (newest wins), sorted
/// ascending by createdAt. Never duplicates; safe for realtime + pagination.
List<ChatMessage> mergeMessages(
  List<ChatMessage> existing,
  List<ChatMessage> incoming,
) {
  final byId = <String, ChatMessage>{
    for (final m in existing) m.id: m,
    for (final m in incoming) m.id: m,
  };
  final out = byId.values.toList()
    ..sort((a, b) {
      final ta =
          a.createdAt ?? a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb =
          b.createdAt ?? b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });
  return out;
}

/// Validates a text draft: trims, rejects empty/over-long messages.
/// Returns the trimmed text or throws [DraftValidationException].
String validateTextDraft(String raw, {int maxLength = 1000}) {
  final text = raw.trim();
  if (text.isEmpty) {
    throw const DraftValidationException('Message is empty');
  }
  if (text.length > maxLength) {
    throw DraftValidationException('Message is too long ($maxLength max)');
  }
  return text;
}

/// Debounces typing events: emits start immediately, auto-stops after
/// [stopAfter] of silence. Testable with fakeAsync.
class TypingDebouncer {
  TypingDebouncer({
    this.stopAfter = const Duration(seconds: 3),
    required this.onChange,
  });

  final Duration stopAfter;

  /// Called with true when the user starts typing, false when they stop
  /// (idle timeout or explicit stop).
  final void Function(bool typing) onChange;

  Timer? _timer;
  bool _typing = false;

  bool get isTyping => _typing;

  /// Call on every keystroke. Only fires the first transition per burst.
  void onKeystroke() {
    if (!_typing) {
      _typing = true;
      onChange(true);
    }
    _timer?.cancel();
    _timer = Timer(stopAfter, stop);
  }

  /// Call when the message is sent or the input cleared.
  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_typing) {
      _typing = false;
      onChange(false);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
