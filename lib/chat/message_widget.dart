import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.role,
    required this.content,
    this.onCopy,
  });

  final MessageRole role;
  final String content;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? colorScheme.primary : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: DefaultSelectionStyle(
                selectionColor: isUser
                    ? colorScheme.onPrimary.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.2),
                child: SelectionArea(
                  child: MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 13,
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        height: 1.4,
                      ),
                      code: TextStyle(
                        fontSize: 12,
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
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
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      h2: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      h3: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      listBullet: TextStyle(
                        fontSize: 13,
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      a: TextStyle(
                        fontSize: 13,
                        color: isUser
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
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 12, 0),
            child: IconButtonWidget(
              onPressed:
                  onCopy ??
                  () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
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
}
