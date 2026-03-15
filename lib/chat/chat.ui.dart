import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chat.state.dart';
import 'package:contextchat/chat/chat_draft.provider.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/chat/select_ai_model.view.dart';
import 'package:contextchat/chat/select_prompt.view.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/no_transition_route.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:contextchat/settings/settings.view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatUi extends ConsumerStatefulWidget {
  const ChatUi({super.key});

  @override
  ConsumerState<ChatUi> createState() => _ChatUiState();
}

class _ChatUiState extends ConsumerState<ChatUi> {
  static const double _bottomTolerancePx = 48.0;

  final TextEditingController _textController = TextEditingController();
  late ScrollController _scrollController;

  bool _autoScrollEnabled = true;
  bool _scrollScheduled = false;
  bool _programmaticScrollInProgress = false;

  String? get chatId =>
      ref.watch(chatsProvider.select((state) => state.selectedChatId));

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openRouterModelsProvider.notifier).loadModels();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return true;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return distanceToBottom <= _bottomTolerancePx;
  }

  void _setAutoScrollEnabledFromScrollPosition({required bool userInitiated}) {
    if (_programmaticScrollInProgress) return;
    final nearBottom = _isNearBottom();

    if (nearBottom) {
      if (_autoScrollEnabled != true) {
        setState(() => _autoScrollEnabled = true);
      }
      return;
    }

    if (userInitiated && _autoScrollEnabled != false) {
      setState(() => _autoScrollEnabled = false);
    }
  }

  void _scheduleScrollToBottom() {
    if (!_autoScrollEnabled) return;
    if (_scrollScheduled) return;
    _scrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scrollScheduled = false;
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      if (!_autoScrollEnabled) return;

      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      final distance = (target - position.pixels).abs();
      if (distance <= 0.5) return;

      _programmaticScrollInProgress = true;
      try {
        // For frequent streaming updates, jumping keeps things stable and avoids queuing animations.
        _scrollController.jumpTo(target);
      } finally {
        _programmaticScrollInProgress = false;
      }
    });
  }

  Future<void> _submitCurrentMessage(String? selectedModelId) async {
    final text = _textController.text.trim();
    if (text.isEmpty || selectedModelId == null) return;

    final openRouterState = ref.read(openRouterProvider);
    if (openRouterState.apiKey == null || openRouterState.apiKey!.isEmpty) {
      _showSetupRequiredDialog();
      return;
    }

    await send(text, selectedModelId);
  }

  void _showSetupRequiredDialog() {
    showAppDialog(
      context: context,
      title: const Text('OpenRouter setup required'),
      content: const Text(
        'You need to configure your OpenRouter API key before sending messages. Please go to Settings to set it up.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              NoTransitionRoute(builder: (context) => const SettingsView()),
            );
          },
          child: const Text('Go to Settings'),
        ),
      ],
    );
  }

  Widget _buildMessage({required MessageRole role, required String content}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = role == MessageRole.user;
    final isSystem = role == MessageRole.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primary
                  : isSystem
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
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
                    // TODO: Implement link handling (e.g., url_launcher)
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            child: IconButtonWidget(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                showAppSnackBar(context, 'Copied to clipboard');
              },
              icon: Icon(
                LucideIcons.copy,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return Center(
        child: Text('Please select or create a chat from the sidebar.'),
      );
    }

    ChatState chatState = ref.watch(chatProvider(chatId!));
    ref.watch(chatDraftProvider(chatId!));

    ref.listen<String>(chatDraftProvider(chatId!), (previous, next) {
      if (!mounted) return;
      if (_textController.text == next) return;
      _textController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });

    ref.listen<ChatState>(chatProvider(chatId!), (previous, next) {
      // If user is at/near bottom, keep following new messages and streamed content.
      if (_autoScrollEnabled) {
        _scheduleScrollToBottom();
      }
    });

    String? selectedModelId = chatState.selectedModelId;

    bool loading = chatState.loading;

    if (loading && chatState.chat.messages.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final userInitiated =
                  notification is UserScrollNotification ||
                  (notification is ScrollUpdateNotification &&
                      notification.dragDetails != null);

              if (notification is ScrollUpdateNotification ||
                  notification is UserScrollNotification ||
                  notification is ScrollEndNotification) {
                _setAutoScrollEnabledFromScrollPosition(
                  userInitiated: userInitiated,
                );
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...chatState.chat.messages.map(
                    (msg) =>
                        _buildMessage(role: msg.role, content: msg.content),
                  ),
                  if (chatState.accumulatedResponse != null)
                    _buildMessage(
                      role: MessageRole.assistant,
                      content: chatState.accumulatedResponse!,
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          child: _Composer(
            controller: _textController,
            onChanged: (value) =>
                ref.read(chatDraftProvider(chatId!).notifier).setDraft(value),
            loading: loading,
            selectedModelId: selectedModelId,
            onInsertPrompt: (promptText) {
              if (chatId == null) return;
              ref
                  .read(chatDraftProvider(chatId!).notifier)
                  .insert(promptText, replace: false);
            },
            onSubmit: () => _submitCurrentMessage(selectedModelId),
          ),
        ),
      ],
    );
  }

  Future<void> send(String text, String? modelId) async {
    if (text.isEmpty || modelId == null || chatId == null) return;

    String temporaryText = text;

    try {
      await ref.read(chatProvider(chatId!).notifier).sendMessage(text);
      _textController.clear();
      ref.read(chatDraftProvider(chatId!).notifier).clear();
    } catch (e) {
      _textController.text = temporaryText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      rethrow;
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.loading,
    required this.selectedModelId,
    required this.onInsertPrompt,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool loading;
  final String? selectedModelId;
  final ValueChanged<String> onInsertPrompt;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSend =
        !loading && selectedModelId != null && selectedModelId!.isNotEmpty;
    final theme = Theme.of(context);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _SendMessageIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _SendMessageIntent(),
      },
      child: Actions(
        actions: {
          _SendMessageIntent: CallbackAction<_SendMessageIntent>(
            onInvoke: (_) {
              if (canSend) {
                onSubmit();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 6,
                  enabled: !loading,
                  keyboardType: TextInputType.multiline,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Enter text here',
                    hintStyle: theme.textTheme.bodyMedium,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Cmd+Enter to send',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      SelectPromptView(
                        onPicked: (promptText) => onInsertPrompt(promptText),
                      ),
                      const SizedBox(width: 8),
                      const SelectAiModelView(),
                      const SizedBox(width: 8),
                      if (loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (loading) const SizedBox(width: 8),
                      IconButtonWidget(
                        onPressed: canSend ? onSubmit : null,
                        icon: const Icon(LucideIcons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}
