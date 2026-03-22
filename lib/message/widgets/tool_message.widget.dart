import 'dart:typed_data';

import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/widgets/base_message.widget.dart';
import 'package:flutter/material.dart';

class ToolMessageWidget extends StatefulWidget {
  const ToolMessageWidget({super.key, required this.message, this.onCopy});

  final Message message;
  final VoidCallback? onCopy;

  @override
  State<ToolMessageWidget> createState() => _ToolMessageWidgetState();
}

class _ToolMessageWidgetState extends State<ToolMessageWidget> {
  bool _expanded = false;
  final Map<String, Uint8List> _decodedImageCache = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = MessageLayout.tool;
    final colors = MessageColors.fromLayout(layout, colorScheme);

    final hasImages =
        widget.message.images != null && widget.message.images!.isNotEmpty;
    final toolHeader = buildToolHeaderText(widget.message);
    final contentLength = widget.message.content.length;
    final shouldTruncate = contentLength > 100 && !_expanded;

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
                  color: widget.message.toolError
                      ? colors.errorOnColor
                      : colors.toolHeaderColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (widget.message.content.trim().isNotEmpty)
            buildMarkdownBody(
              context: context,
              data: shouldTruncate
                  ? '${widget.message.content.substring(0, 100)}...'
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
          if (contentLength > 100)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
