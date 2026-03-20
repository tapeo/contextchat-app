import 'dart:convert';

import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MessageWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = message.role;
    final content = message.content;
    final isUser = role == MessageRole.user;
    final isTool = role == MessageRole.tool;
    final isToolResult = role == MessageRole.tool;
    final hasToolCalls =
        role == MessageRole.assistant && message.toolCallsJson != null;
    final toolHeader = _toolHeaderText();

    return Align(
      alignment: (isUser || isToolResult)
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: (isUser || isToolResult)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: (isUser || isToolResult) ? 16 : 0,
              right: (isUser || isToolResult) ? 16 : 0,
            ),
            padding: isUser
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: (isUser || isToolResult) ? colorScheme.primary : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular((isUser || isToolResult) ? 16 : 4),
                bottomRight: Radius.circular((isUser || isToolResult) ? 4 : 16),
              ),
            ),
            child: DefaultSelectionStyle(
              selectionColor: (isUser || isToolResult)
                  ? colorScheme.onPrimary.withValues(alpha: 0.3)
                  : colorScheme.primary.withValues(alpha: 0.2),
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
                            color: (isUser || isToolResult)
                                ? colorScheme.onPrimary
                                : isTool
                                ? (message.toolError
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                : colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    MarkdownBody(
                      data: hasToolCalls ? _formatToolCallsSummary() : content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 13,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          height: 1.4,
                        ),
                        code: TextStyle(
                          fontSize: 12,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          backgroundColor: (isUser || isToolResult)
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.surfaceContainerHighest,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: (isUser || isToolResult)
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        blockquote: TextStyle(
                          fontSize: 13,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary.withValues(alpha: 0.8)
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: (isUser || isToolResult)
                                  ? colorScheme.onPrimary.withValues(alpha: 0.5)
                                  : colorScheme.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        h1: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        h2: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        h3: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        listBullet: TextStyle(
                          fontSize: 13,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        a: TextStyle(
                          fontSize: 13,
                          color: (isUser || isToolResult)
                              ? colorScheme.onPrimary.withValues(alpha: 0.9)
                              : colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrlString(
                            href,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    if (hasToolCalls &&
                        onApproveToolCalls != null &&
                        !message.toolCallsProcessed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => onApproveToolCalls!(message),
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: const Text('Accept tool call'),
                            ),
                            TextButton.icon(
                              onPressed: () => onDenyToolCalls?.call(message),
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
                  onCopy ??
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
    if (message.role == MessageRole.tool) {
      final state = message.toolError ? 'error' : 'result';
      return 'Tool $state: ${message.toolName ?? 'unknown'}';
    }
    if (message.role == MessageRole.assistant &&
        message.toolCallsJson != null) {
      return 'Assistant requested tool call';
    }
    return null;
  }

  String _formatToolCallsSummary() {
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
}
