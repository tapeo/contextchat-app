import 'dart:convert';

import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/chat/message.style.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    required this.message,
    this.onCopy,
    this.onApproveToolCalls,
    this.onDenyToolCalls,
  });

  final Message message;
  final VoidCallback? onCopy;
  final ValueChanged<Message>? onApproveToolCalls;
  final ValueChanged<Message>? onDenyToolCalls;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    final role = widget.message.role;
    final content = widget.message.content;

    final isTool = role == MessageRole.tool;

    final hasToolCalls =
        role == MessageRole.assistant &&
        widget.message.toolCallsJson != null &&
        !widget.message.toolCallsProcessed;

    final toolHeader = _toolHeaderText();

    final contentLength = content.length;
    final shouldTruncate = isTool && contentLength > 100 && !_expanded;

    final style = MessageStyle.fromRole(role);
    final colors = style.colors(colorScheme);

    return Align(
      alignment: style.alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: style.crossAxisAlignment,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: style.horizontalMargin,
              right: style.horizontalMargin,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(style.bottomLeftRadius),
                bottomRight: Radius.circular(style.bottomRightRadius),
              ),
            ),
            child: DefaultSelectionStyle(
              selectionColor: colors.selectionColor,
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (toolHeader != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          toolHeader,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isTool
                                ? (widget.message.toolError
                                      ? colors.errorOnColor
                                      : colors.toolHeaderColor)
                                : colors.onColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    MarkdownBody(
                      data: shouldTruncate
                          ? '${content.substring(0, 100)}...'
                          : (hasToolCalls
                                ? _formatToolCallsSummary()
                                : content),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrlString(
                            href,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    if (isTool && contentLength > 100)
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
                    if (hasToolCalls &&
                        widget.onApproveToolCalls != null &&
                        !widget.message.toolCallsProcessed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  widget.onApproveToolCalls!(widget.message),
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: const Text('Accept tool call'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  widget.onDenyToolCalls?.call(widget.message),
                              icon: const Icon(LucideIcons.x, size: 16),
                              label: const Text('Deny'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 12, 0),
            child: IconButtonWidget(
              onPressed:
                  widget.onCopy ??
                  () {
                    Clipboard.setData(ClipboardData(text: content));
                    showAppSnackBar(context, 'Copied to clipboard');
                  },
              icon: Icon(
                LucideIcons.copy,
                size: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _toolHeaderText() {
    if (widget.message.role == MessageRole.tool) {
      final state = widget.message.toolError ? 'error' : 'result';
      return 'Tool $state: ${widget.message.toolName ?? 'unknown'}';
    }
    if (widget.message.role == MessageRole.assistant &&
        widget.message.toolCallsJson != null &&
        !widget.message.toolCallsProcessed) {
      return 'Assistant requested tool call';
    }
    return null;
  }

  String _formatToolCallsSummary() {
    try {
      final decoded = jsonDecode(widget.message.toolCallsJson!);
      if (decoded is! List) {
        return widget.message.content;
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
      return widget.message.content;
    }
  }
}
