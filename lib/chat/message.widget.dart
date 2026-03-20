import 'dart:convert';

import 'package:contextchat/chat/message.model.dart';
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

    final isUser = role == MessageRole.user;
    final isTool = role == MessageRole.tool;

    final hasToolCalls =
        role == MessageRole.assistant && widget.message.toolCallsJson != null;

    final toolHeader = _toolHeaderText();

    final contentLength = content.length;
    final shouldTruncate = isTool && contentLength > 100 && !_expanded;

    final alignment = (isUser || isTool)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final crossAxisAlignment = (isUser || isTool)
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final horizontalMargin = (isUser || isTool) ? 16.0 : 0.0;
    final backgroundColor = (isUser || isTool) ? colorScheme.primary : null;
    final bottomLeftRadius = (isUser || isTool) ? 16.0 : 4.0;
    final bottomRightRadius = (isUser || isTool) ? 4.0 : 16.0;
    final selectionColor = (isUser || isTool)
        ? colorScheme.onPrimary.withValues(alpha: 0.3)
        : colorScheme.primary.withValues(alpha: 0.2);

    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: horizontalMargin,
              right: horizontalMargin,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(bottomLeftRadius),
                bottomRight: Radius.circular(bottomRightRadius),
              ),
            ),
            child: DefaultSelectionStyle(
              selectionColor: selectionColor,
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
                            color: (isUser || isTool)
                                ? colorScheme.onPrimary
                                : isTool
                                ? (widget.message.toolError
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                : colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (shouldTruncate)
                      MarkdownBody(
                        data: '${content.substring(0, 100)}...',
                        styleSheet: _markdownStyleSheet(context),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrlString(
                              href,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      )
                    else
                      MarkdownBody(
                        data: hasToolCalls
                            ? _formatToolCallsSummary()
                            : content,
                        styleSheet: _markdownStyleSheet(context),
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
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              ),
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

  MarkdownStyleSheet _markdownStyleSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = widget.message.role == MessageRole.user;
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 13,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
        height: 1.4,
      ),
      code: TextStyle(
        fontSize: 12,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
        backgroundColor: isUser
            ? colorScheme.primary.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: isUser
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquote: TextStyle(
        fontSize: 13,
        color: isUser
            ? colorScheme.onPrimary.withValues(alpha: 0.8)
            : colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isUser
                ? colorScheme.onPrimary.withValues(alpha: 0.5)
                : colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      h1: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      listBullet: TextStyle(
        fontSize: 13,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      a: TextStyle(
        fontSize: 13,
        color: isUser
            ? colorScheme.onPrimary.withValues(alpha: 0.9)
            : colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  String? _toolHeaderText() {
    if (widget.message.role == MessageRole.tool) {
      final state = widget.message.toolError ? 'error' : 'result';
      return 'Tool $state: ${widget.message.toolName ?? 'unknown'}';
    }
    if (widget.message.role == MessageRole.assistant &&
        widget.message.toolCallsJson != null) {
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
