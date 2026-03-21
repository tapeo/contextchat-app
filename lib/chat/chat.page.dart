import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chat.state.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/list_view_gradient_overlay.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/message/composer.widget.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/message.widget.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatUiState();
}

class _ChatUiState extends ConsumerState<ChatPage> {
  static const double _bottomTolerancePx = 48.0;

  late ScrollController _scrollController;

  bool _autoScrollEnabled = true;
  bool _scrollScheduled = false;
  bool _programmaticScrollInProgress = false;
  String? _previousChatId;

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

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottomWithRetries();
    });
  }

  void _scrollToBottomWithRetries() {
    _scrollToBottomAttempt();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scrollToBottomAttempt();
    });
  }

  void _scrollToBottomAttempt() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    _programmaticScrollInProgress = true;
    try {
      _scrollController.jumpTo(position.maxScrollExtent);
    } finally {
      _programmaticScrollInProgress = false;
    }
  }

  void _showOpenRouterErrorDialog(Object error) {
    showAppDialog(
      context: context,
      title: const Text('OpenRouter Error'),
      content: Text(error.toString()),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
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

    final isInitialLoad = _previousChatId != chatId && !chatState.loading;
    if (isInitialLoad) {
      _autoScrollEnabled = true;
    }
    _previousChatId = chatId;

    ref.listen<ChatState>(chatProvider(chatId!), (previous, next) {
      if (_autoScrollEnabled) {
        _scheduleScrollToBottom();
      }
    });

    if (isInitialLoad && chatState.chat.messages.isNotEmpty) {
      _scrollToBottomAfterBuild();
    }

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
                if (userInitiated) {
                  FocusScope.of(context).unfocus();
                }
                _setAutoScrollEnabledFromScrollPosition(
                  userInitiated: userInitiated,
                );
              }
              return false;
            },
            child: ListViewGradientOverlay(
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 16, bottom: 16),
                itemCount:
                    chatState.chat.messages.length +
                    (chatState.accumulatedResponse != null ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final visibleMessages = chatState.chat.messages;

                  if (index < visibleMessages.length) {
                    final msg = visibleMessages[index];
                    return MessageWidget(
                      message: msg,
                      onApproveToolCalls: (assistantMessage) async {
                        if (chatId == null) {
                          return;
                        }

                        try {
                          await ref
                              .read(chatProvider(chatId!).notifier)
                              .approveToolCallsAndContinue(assistantMessage.id);
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          _showOpenRouterErrorDialog(error);
                        }
                      },
                    );
                  } else {
                    return MessageWidget(
                      message: Message(
                        id: 'streaming-preview',
                        timestamp: DateTime.now().toIso8601String(),
                        content: chatState.accumulatedResponse!,
                        role: MessageRole.assistant,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Padding(padding: const EdgeInsets.all(8), child: ComposerWidget()),
      ],
    );
  }
}
