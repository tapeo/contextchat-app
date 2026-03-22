import 'dart:typed_data';

import 'package:contextchat/components/card.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/widgets/base_message.widget.dart';
import 'package:flutter/material.dart';

class UserMessageWidget extends StatefulWidget {
  const UserMessageWidget({super.key, required this.message, this.onCopy});

  final Message message;
  final VoidCallback? onCopy;

  @override
  State<UserMessageWidget> createState() => _UserMessageWidgetState();
}

class _UserMessageWidgetState extends State<UserMessageWidget> {
  final Map<String, Uint8List> _decodedImageCache = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImages =
        widget.message.images != null && widget.message.images!.isNotEmpty;
    final selectionColor = colorScheme.primary.withValues(alpha: 0.2);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CardWidget(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: DefaultSelectionStyle(
              selectionColor: selectionColor,
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.content.trim().isNotEmpty)
                      buildMarkdownBody(
                        context: context,
                        data: widget.message.content,
                        colors: MessageColors(
                          selectionColor: selectionColor,
                          onColor: colorScheme.onSurface,
                          errorOnColor: colorScheme.error,
                          toolHeaderColor: colorScheme.primary,
                        ),
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
                  ],
                ),
              ),
            ),
          ),
          buildActionRow(
            context: context,
            message: widget.message,
            colors: MessageColors(
              selectionColor: selectionColor,
              onColor: colorScheme.onSurface,
              errorOnColor: colorScheme.error,
              toolHeaderColor: colorScheme.primary,
            ),
            imageCache: _decodedImageCache,
            onCopy: widget.onCopy,
          ),
        ],
      ),
    );
  }
}
