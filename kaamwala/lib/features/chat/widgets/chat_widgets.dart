/// Chat UI widgets - bubbles, status ticks, typing dots, image/location.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kaamwala/core/error/failure.dart';
import 'package:kaamwala/core/theme/app_theme.dart';
import 'package:kaamwala/features/chat/models/chat_message.dart';
import 'package:kaamwala/features/chat/providers/chat_providers.dart';

/// Signed-URL resolver for private chat images (participant-only RLS).
final chatImageUrlProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, path) async {
    final res = await ref.watch(chatRepoProvider).signedImageUrl(path);
    return switch (res) {
      Success(:final data) => data,
      Error() => null,
    };
  },
);

/// One message bubble: text / image / location / system.
class ChatBubble extends ConsumerWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.mine,
    this.localImageBytes,
    this.onRetry,
  });

  final ChatMessage message;
  final bool mine;

  /// Optimistic image bytes for a message still uploading.
  final Uint8List? localImageBytes;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: KwSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: KwSpacing.lg,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: KwColors.fill,
            borderRadius: BorderRadius.circular(KwRadius.pill),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KwColors.muted),
          ),
        ),
      );
    }

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: KwSpacing.sm),
      padding: message.type == ChatMessageType.image
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: KwSpacing.lg, vertical: 9),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .74,
      ),
      decoration: BoxDecoration(
        color: mine ? KwColors.primary : Colors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(16),
          topEnd: const Radius.circular(16),
          bottomStart: Radius.circular(mine ? 16 : 4),
          bottomEnd: Radius.circular(mine ? 4 : 16),
        ),
        border: mine ? null : Border.all(color: KwColors.line),
      ),
      child: _bubbleContent(context, ref),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  Widget _bubbleContent(BuildContext context, WidgetRef ref) {
    switch (message.type) {
      case ChatMessageType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: mine ? Colors.white : KwColors.dark,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            _bubbleFooter(context, ref),
          ],
        );
      case ChatMessageType.image:
        return _imageContent(context, ref);
      case ChatMessageType.location:
        return _locationContent(context, ref);
      case ChatMessageType.system:
        return const SizedBox.shrink();
    }
  }

  Widget _imageContent(BuildContext context, WidgetRef ref) {
    final bytes = localImageBytes;
    final path = message.imageUrl ?? message.thumbnailUrl ?? '';
    final progress = message.uploadProgress;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(mine ? 16 : 14),
          child: SizedBox(
            width: 220,
            height: 220,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : path.isEmpty
                ? const ColoredBox(
                    color: KwColors.fill,
                    child: Center(child: Icon(Icons.image_outlined, size: 40)),
                  )
                : Consumer(
                    builder: (context, ref, _) {
                      final url = ref.watch(chatImageUrlProvider(path));
                      return url.when(
                        loading: () => const ColoredBox(
                          color: KwColors.fill,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (e, _) => const ColoredBox(
                          color: KwColors.fill,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: KwColors.muted,
                            ),
                          ),
                        ),
                        data: (url) => url == null
                            ? const ColoredBox(
                                color: KwColors.fill,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 32,
                                    color: KwColors.muted,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _openFullscreen(context, url),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: KwColors.fill,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 32,
                                        color: KwColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ),
        if (progress != null && progress < 1)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 6,
          bottom: 6,
          child: _bubbleFooter(context, ref, onImage: true),
        ),
      ],
    );
  }

  Widget _locationContent(BuildContext context, WidgetRef ref) {
    final lat = message.locationLat;
    final lng = message.locationLng;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16,
              color: mine ? Colors.white : KwColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                message.locationLabel ??
                    (lat != null && lng != null
                        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                        : 'Shared location'),
                style: TextStyle(
                  color: mine ? Colors.white : KwColors.dark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (message.locationLabel != null && lat != null && lng != null) ...[
          const SizedBox(height: 2),
          Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: TextStyle(
              color: mine ? Colors.white70 : KwColors.muted,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 6),
        if (lat != null && lng != null)
          InkWell(
            borderRadius: BorderRadius.circular(KwRadius.sm),
            onTap: () => openInMaps(lat, lng),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KwSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: mine
                    ? Colors.white.withValues(alpha: .18)
                    : KwColors.primaryLight,
                borderRadius: BorderRadius.circular(KwRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 15,
                    color: mine ? Colors.white : KwColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Open in Maps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: mine ? Colors.white : KwColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 2),
        _bubbleFooter(context, ref),
      ],
    );
  }

  /// Time + delivery state row. [onImage] renders it translucent over photos.
  Widget _bubbleFooter(
    BuildContext context,
    WidgetRef ref, {
    bool onImage = false,
  }) {
    final time = (message.createdAt ?? message.sentAt) == null
        ? ''
        : DateFormat('HH:mm').format(message.createdAt ?? message.sentAt!);
    final baseColor = mine
        ? (onImage ? Colors.white : Colors.white70)
        : KwColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mine) ...[
          if (message.isFailed)
            GestureDetector(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            )
          else if (message.isSending)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: baseColor,
              ),
            )
          else if (message.isRead)
            Icon(
              Icons.done_all_rounded,
              size: 13,
              color: onImage ? Colors.white : KwColors.blue,
            )
          else
            Icon(Icons.done_rounded, size: 13, color: baseColor),
          const SizedBox(width: 3),
        ],
        Text(time, style: TextStyle(fontSize: 10, color: baseColor)),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(maxScale: 5, child: Image.network(url)),
          ),
        ),
      ),
    );
  }
}

/// Opens [lat,lng] in the default maps app.
Future<void> openInMaps(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    final fallback = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
}

/// Animated "typing…" dots shown above the input bar.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Opacity(
                    opacity: 0.3 + 0.7 * _wave(i),
                    child: const CircleAvatar(radius: 3),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'typing…',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: KwColors.muted),
        ),
      ],
    );
  }

  double _wave(int i) {
    final t = _ctrl.value;
    final phase = (t + i * 0.2) % 1.0;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  }
}

/// Centered date pill between days.
class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final label = switch (day.difference(today).inDays) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => DateFormat('d MMM yyyy').format(date),
    };
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: KwSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.md,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: KwColors.fill,
          borderRadius: BorderRadius.circular(KwRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: KwColors.muted),
        ),
      ),
    );
  }
}

/// Compact "Chat" button with an unread badge - used on booking/job cards.
class ChatUnreadButton extends ConsumerWidget {
  const ChatUnreadButton({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadProvider(bookingId)).valueOrNull ?? 0;
    return TextButton.icon(
      onPressed: () async {
        await context.push('/chat/$bookingId');
        ref.invalidate(chatUnreadProvider(bookingId));
      },
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: KwColors.red,
        label: Text('$unread'),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
      ),
      label: const Text('Chat'),
    );
  }
}
