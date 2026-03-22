import 'dart:typed_data';

import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/widgets/base_message.widget.dart';
import 'package:flutter/material.dart';

class SystemMessageWidget extends StatefulWidget {
  const SystemMessageWidget({super.key, required this.message, this.onCopy});

  final Message message;
  final VoidCallback? onCopy;

  @override
  State<SystemMessageWidget> createState() => _SystemMessageWidgetState();
}

class _SystemMessageWidgetState extends State<SystemMessageWidget> {
  final Map<String, Uint8List> _decodedImageCache = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = MessageLayout.system;
    final colors = MessageColors.fromLayout(layout, colorScheme);
    final hasImages =
        widget.message.images != null && widget.message.images!.isNotEmpty;

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
          if (widget.message.content.trim().isNotEmpty)
            buildMarkdownBody(
              context: context,
              data: widget.message.content,
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
        ],
      ),
    );
  }
}
