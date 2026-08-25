/// Chat screen (Phase 3 C11) - text only MVP, Supabase Realtime.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  String _title = 'Chat';

  @override
  void initState() {
    super.initState();
    // Null in unconfigured dev builds - send/markRead stay disabled.
    _myId = SupabaseService.currentUserId;
    _load();
    _loadTitle();
    _channel = ref.read(chatRepoProvider).subscribe(widget.bookingId, _load);
  }

  Future<void> _loadTitle() async {
    final res = await ref
        .read(bookingsRepoProvider)
        .counterpartName(widget.bookingId);
    if (!mounted) return;
    if (res case Success(:final data) when data.isNotEmpty) {
      setState(() => _title = data);
    }
  }

  Future<void> _load() async {
    final result = await ref.read(chatRepoProvider).history(widget.bookingId);
    if (!mounted) return;
    setState(() {
      if (result case Success(:final data)) {
        _messages = data;
      }
    });
    // Read receipts: everything from the counterpart is now seen (FR-CHAT-03).
    final myId = _myId;
    if (myId != null) {
      unawaited(
        ref
            .read(chatRepoProvider)
            .markRead(bookingId: widget.bookingId, readerId: myId),
      );
    }
    if (_scroll.hasClients) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients && mounted) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final myId = _myId;
    if (text.isEmpty || _sending || myId == null) return;
    setState(() => _sending = true);
    _ctrl.clear();
    await ref
        .read(chatRepoProvider)
        .send(bookingId: widget.bookingId, senderId: myId, content: text);
    if (!mounted) return;
    setState(() => _sending = false);
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
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: KwColors.primaryLight,
              child: Icon(
                Icons.person_rounded,
                size: 19,
                color: KwColors.primary.withValues(alpha: .8),
              ),
            ),
            const SizedBox(width: KwSpacing.md),
            Expanded(child: Text(_title, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: KwColors.muted.withValues(alpha: .4),
                          ),
                          const SizedBox(height: KwSpacing.md),
                          Text(
                            'Say hello to $_title 👋',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: KwColors.muted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(KwSpacing.lg),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) => _bubble(_messages[i]),
                    ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: KwSpacing.md,
                right: KwSpacing.sm,
                top: KwSpacing.sm,
                bottom: MediaQuery.paddingOf(context).bottom + KwSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: KwColors.surface,
                border: Border(top: BorderSide(color: KwColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        fillColor: KwColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: KwSpacing.lg,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KwSpacing.xs),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctrl,
                    builder: (_, v, _) => IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: v.text.trim().isEmpty
                            ? KwColors.fill
                            : KwColors.primary,
                      ),
                      onPressed: v.text.trim().isEmpty ? null : _send,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: v.text.trim().isEmpty
                            ? KwColors.muted
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderId == _myId;
    final time = m.createdAt == null
        ? ''
        : DateFormat('HH:mm').format(m.createdAt!);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: KwSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.lg,
          vertical: 9,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .74,
        ),
        decoration: BoxDecoration(
          color: mine ? KwColors.primary : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(mine ? 16 : 4),
            bottomEnd: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: KwColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              m.content,
              style: TextStyle(color: mine ? Colors.white : KwColors.dark),
            ),
            const SizedBox(height: 2),
            Text(
              mine ? '$time ${m.isRead ? '✓✓' : '✓'}' : time,
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : KwColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
