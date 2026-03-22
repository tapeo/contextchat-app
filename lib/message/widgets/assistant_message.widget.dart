import 'dart:typed_data';

import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/widgets/base_message.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AssistantMessageWidget extends ConsumerStatefulWidget {
  const AssistantMessageWidget({super.key, required this.message, this.onCopy});

  final Message message;
  final VoidCallback? onCopy;

  @override
  ConsumerState<AssistantMessageWidget> createState() =>
      _AssistantMessageWidgetState();
}

class _AssistantMessageWidgetState
    extends ConsumerState<AssistantMessageWidget> {
  final Map<String, Uint8List> _decodedImageCache = {};

  void _approveToolCalls() async {
    final chatId = ref.read(
      chatsProvider.select((state) => state.selectedChatId),
    );
    if (chatId == null) return;

    try {
      await ref
          .read(chatProvider(chatId).notifier)
          .approveToolCallsAndContinue(widget.message.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to approve tool calls')));
      }
    }
  }

  void _denyToolCalls() async {
    final chatId = ref.read(
      chatsProvider.select((state) => state.selectedChatId),
    );
    if (chatId == null) return;

    try {
      await ref
          .read(chatProvider(chatId).notifier)
          .denyToolCallsAndContinue(widget.message.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to deny tool calls')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = MessageLayout.assistant;
    final colors = MessageColors.fromLayout(layout, colorScheme);

    final hasToolCalls =
        widget.message.toolCallsJson != null &&
        !widget.message.toolCallsProcessed;
    final hasImages =
        widget.message.images != null && widget.message.images!.isNotEmpty;
    final toolHeader = buildToolHeaderText(widget.message);

    return BaseMessageShell(
      layout: layout,
      colors: colors,
      actionRow: buildActionRow(
        context: context,
        message: widget.message,
        colors: colors,
        imageCache: _decodedImageCache,
        onCopy: widget.onCopy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toolHeader != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                toolHeader,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (hasToolCalls || widget.message.content.trim().isNotEmpty)
            buildMarkdownBody(
              context: context,
              data: hasToolCalls
                  ? formatToolCallsSummary(widget.message)
                  : widget.message.content,
              colors: colors,
            ),
          if (hasImages)
            Padding(
              padding: EdgeInsets.only(
                top: widget.message.content.trim().isNotEmpty ? 8 : 0,
              ),
              child: buildImageGallery(
                context: context,
                images: widget.message.images!,
                imageCache: _decodedImageCache,
              ),
            ),
          if (hasToolCalls && !widget.message.toolCallsProcessed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _approveToolCalls,
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Accept tool call'),
                  ),
                  TextButton.icon(
                    onPressed: _denyToolCalls,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Deny'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
