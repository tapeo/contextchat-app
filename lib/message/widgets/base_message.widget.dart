import 'dart:convert';
import 'dart:io';

import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/route_transitions.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/image/image_viewer.page.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MessageLayout {
  final Alignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double horizontalMargin;
  final double bottomLeftRadius;
  final double bottomRightRadius;

  const MessageLayout({
    required this.alignment,
    required this.crossAxisAlignment,
    required this.horizontalMargin,
    required this.bottomLeftRadius,
    required this.bottomRightRadius,
  });

  static const user = MessageLayout(
    alignment: Alignment.centerRight,
    crossAxisAlignment: CrossAxisAlignment.end,
    horizontalMargin: 16.0,
    bottomLeftRadius: AppTheme.radiusMedium,
    bottomRightRadius: AppTheme.radiusMedium / 4,
  );

  static const tool = MessageLayout(
    alignment: Alignment.centerRight,
    crossAxisAlignment: CrossAxisAlignment.end,
    horizontalMargin: 16.0,
    bottomLeftRadius: AppTheme.radiusMedium,
    bottomRightRadius: AppTheme.radiusMedium / 4,
  );

  static const assistant = MessageLayout(
    alignment: Alignment.centerLeft,
    crossAxisAlignment: CrossAxisAlignment.start,
    horizontalMargin: 0.0,
    bottomLeftRadius: AppTheme.radiusMedium / 4,
    bottomRightRadius: AppTheme.radiusMedium,
  );

  static const system = MessageLayout(
    alignment: Alignment.centerLeft,
    crossAxisAlignment: CrossAxisAlignment.start,
    horizontalMargin: 0.0,
    bottomLeftRadius: AppTheme.radiusMedium / 4,
    bottomRightRadius: AppTheme.radiusMedium,
  );

  static MessageLayout fromRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return user;
      case MessageRole.tool:
        return tool;
      case MessageRole.assistant:
        return assistant;
      case MessageRole.system:
        return system;
    }
  }
}

class MessageColors {
  final Color? backgroundColor;
  final Color selectionColor;
  final Color onColor;
  final Color errorOnColor;
  final Color toolHeaderColor;

  const MessageColors({
    this.backgroundColor,
    required this.selectionColor,
    required this.onColor,
    required this.errorOnColor,
    required this.toolHeaderColor,
  });

  static MessageColors fromLayout(
    MessageLayout layout,
    ColorScheme colorScheme,
  ) {
    if (layout == MessageLayout.user || layout == MessageLayout.tool) {
      return MessageColors(
        backgroundColor: colorScheme.primary,
        selectionColor: colorScheme.onPrimary.withValues(alpha: 0.3),
        onColor: colorScheme.onPrimary,
        errorOnColor: colorScheme.onPrimary,
        toolHeaderColor: colorScheme.onPrimary,
      );
    }
    if (layout == MessageLayout.assistant) {
      return MessageColors(
        backgroundColor: null,
        selectionColor: colorScheme.primary.withValues(alpha: 0.2),
        onColor: colorScheme.onSurface,
        errorOnColor: colorScheme.error,
        toolHeaderColor: colorScheme.primary,
      );
    }
    return MessageColors(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectionColor: colorScheme.primary.withValues(alpha: 0.2),
      onColor: colorScheme.onSurface,
      errorOnColor: colorScheme.error,
      toolHeaderColor: colorScheme.primary,
    );
  }
}

String? buildToolHeaderText(Message message) {
  if (message.role == MessageRole.tool) {
    final state = message.toolError ? 'error' : 'result';
    return 'Tool $state: ${message.toolName ?? 'unknown'}';
  }
  if (message.role == MessageRole.assistant &&
      message.toolCallsJson != null &&
      !message.toolCallsProcessed) {
    return 'Assistant requested tool call';
  }
  return null;
}

String formatToolCallsSummary(Message message) {
  try {
    final decoded = jsonDecode(message.toolCallsJson!);
    if (decoded is! List) {
      return message.content;
    }

    final lines = <String>['Requested tools:'];
    for (final entry in decoded.whereType<Map>()) {
      final function = entry['function'];
      if (function is! Map) {
        continue;
      }
      final name = function['name']?.toString() ?? 'unknown';
      final arguments = function['arguments']?.toString() ?? '{}';
      lines.add('- `$name` args: `$arguments`');
    }
    return lines.join('\n');
  } catch (_) {
    return message.content;
  }
}

Uint8List? decodeImageBytes(String base64Data, Map<String, Uint8List> cache) {
  if (cache.containsKey(base64Data)) {
    return cache[base64Data];
  }
  try {
    final bytes = base64Decode(base64Data);
    cache[base64Data] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

Future<void> downloadImages(
  List<AssistantImage> images,
  Map<String, Uint8List> cache,
  BuildContext context,
) async {
  if (images.isEmpty) return;

  if (Platform.isIOS) {
    final status = await Permission.photosAddOnly.request();
    if (!status.isGranted) {
      if (context.mounted) {
        showAppSnackBar(context, 'Permission denied');
      }
      return;
    }

    for (int i = 0; i < images.length; i++) {
      final bytes = decodeImageBytes(images[i].base64Data, cache);
      if (bytes == null) continue;

      await Gal.putImageBytes(bytes, album: 'Contextchat');

      if (context.mounted && i == images.length - 1) {
        showAppSnackBar(context, 'Images saved to gallery');
      }
    }
  } else if (Platform.isMacOS) {
    for (int i = 0; i < images.length; i++) {
      final bytes = decodeImageBytes(images[i].base64Data, cache);
      if (bytes == null) continue;

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save image ${i + 1}',
        fileName: 'image_$i.png',
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
      }

      if (context.mounted && i == images.length - 1) {
        showAppSnackBar(context, 'Images downloaded');
      }
    }
  }
}

Widget buildImageGallery({
  required BuildContext context,
  required List<AssistantImage> images,
  required Map<String, Uint8List> imageCache,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: images.map((image) {
      final bytes = decodeImageBytes(image.base64Data, imageCache);
      if (bytes == null) {
        return const SizedBox.shrink();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                ThemeTransitionRoute(
                  builder: (context) => ImageViewerPage(
                    base64Data: image.base64Data,
                    mimeType: image.mimeType,
                  ),
                ),
              );
            },
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              key: ValueKey(image.base64Data.hashCode),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

Widget buildMarkdownBody({
  required BuildContext context,
  required String data,
  required MessageColors colors,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return MarkdownBody(
    data: data,
    styleSheet: MarkdownStyleSheet(
      code: GoogleFonts.jetBrainsMono(color: colors.onColor, fontSize: 11),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    ),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrlString(href, mode: LaunchMode.externalApplication);
      }
    },
  );
}

Widget buildActionRow({
  required BuildContext context,
  required Message message,
  required MessageColors colors,
  required Map<String, Uint8List> imageCache,
  VoidCallback? onCopy,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final hasImages = message.images != null && message.images!.isNotEmpty;

  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 12, 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButtonWidget(
          onPressed:
              onCopy ??
              () {
                Clipboard.setData(ClipboardData(text: message.content));
                showAppSnackBar(context, 'Copied to clipboard');
              },
          icon: Icon(
            LucideIcons.copy,
            size: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        IconButtonWidget(
          onPressed:
              onCopy ??
              () {
                showAppDialog(
                  context: context,
                  title: const Text('Raw message data'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      const JsonEncoder.withIndent(
                        '  ',
                      ).convert(message.toJson()),
                      style: GoogleFonts.jetBrainsMono(
                        color: colors.onColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  actions: [
                    TextButtonWidget(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
          icon: Icon(
            LucideIcons.code,
            size: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        if (hasImages)
          IconButtonWidget(
            onPressed: () =>
                downloadImages(message.images!, imageCache, context),
            icon: Icon(
              LucideIcons.download,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    ),
  );
}

class BaseMessageShell extends StatelessWidget {
  const BaseMessageShell({
    super.key,
    required this.layout,
    required this.colors,
    required this.child,
    required this.actionRow,
  });

  final MessageLayout layout;
  final MessageColors colors;
  final Widget child;
  final Widget actionRow;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: layout.alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: layout.horizontalMargin,
              right: layout.horizontalMargin,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.radiusMedium),
                topRight: const Radius.circular(AppTheme.radiusMedium),
                bottomLeft: Radius.circular(layout.bottomLeftRadius),
                bottomRight: Radius.circular(layout.bottomRightRadius),
              ),
            ),
            child: DefaultSelectionStyle(
              selectionColor: colors.selectionColor,
              child: SelectionArea(child: child),
            ),
          ),
          actionRow,
        ],
      ),
    );
  }
}
