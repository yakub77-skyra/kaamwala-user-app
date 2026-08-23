/// Chat screen (Phase 3 C11) - text only MVP, Supabase Realtime.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/client/providers/client_providers.dart';
import 'package:kaamwala/features/client/repositories/chat_repository.dart';
import 'package:kaamwala/models/review.dart';
import 'package:kaamwala/services/supabase_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  RealtimeChannel? _channel;
  bool _sending = false;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = SupabaseService.currentUserId ?? 'demo-client';
    _load();
    _channel =
        ref.read(chatRepoProvider).subscribe(widget.bookingId, _load);
  }

  Future<void> _load() async {
    final result = await ref.read(chatRepoProvider).history(widget.bookingId);
    if (!mounted) return;
    setState(() {
      if (result case Success(:final data)) {
        _messages = data;
      }
    });
    if (_scroll.hasClients) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _sending = true;
    _ctrl.clear();
    await ref.read(chatRepoProvider).send(
          bookingId: widget.bookingId,
          senderId: _myId!,
          content: text,
        );
    _sending = false;
    await _load();
  }

  @override
  void dispose() {
    final ch = _channel;
    if (ch != null) ChatRepository.unsubscribe(ch);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Worker'),
            const SizedBox(width: KwSpacing.sm),
            Icon(Icons.circle, size: 8, color: KwColors.green),
            const SizedBox(width: 2),
            const Text('online', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(KwSpacing.lg),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final mine = m.senderId == _myId;
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: KwSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: KwSpacing.lg, vertical: KwSpacing.md),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .72),
                      decoration: BoxDecoration(
                        color: mine ? KwColors.primary : KwColors.surface,
                        borderRadius: BorderRadius.circular(KwRadius.button),
                        border: Border.all(color: const Color(0x141A1A2E)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(m.content,
                              style: TextStyle(
                                  color: mine ? Colors.white : KwColors.dark)),
                          const SizedBox(height: 2),
                          Text(mine ? '✓✓' : '',
                              style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KwSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(hintText: 'Type a message…'),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
