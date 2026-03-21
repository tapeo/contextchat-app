import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chat.state.dart';
import 'package:contextchat/chat/chat_draft.provider.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/chat/parameters_input.dialog.dart';
import 'package:contextchat/chat/select_ai_model.dialog.dart';
import 'package:contextchat/chat/select_prompt.widget.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComposerWidget extends ConsumerStatefulWidget {
  const ComposerWidget({super.key});

  @override
  ConsumerState<ComposerWidget> createState() => _ComposerWidgetState();
}

class _ComposerWidgetState extends ConsumerState<ComposerWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _chatId =>
      ref.watch(chatsProvider.select((state) => state.selectedChatId));

  bool get _loading =>
      _chatId != null &&
      ref.watch(chatProvider(_chatId!).select((state) => state.loading));

  String? get _selectedModelId => _chatId != null
      ? ref.watch(
          chatProvider(_chatId!).select((state) => state.selectedModelId),
        )
      : null;

  bool get _canSend =>
      !_loading && _selectedModelId != null && _selectedModelId!.isNotEmpty;

  void _onChanged(String value) {
    if (_chatId == null) return;
    ref.read(chatDraftProvider(_chatId!).notifier).setDraft(value);
  }

  void _onInsertPrompt(String promptText) {
    if (_chatId == null) return;
    ref
        .read(chatDraftProvider(_chatId!).notifier)
        .insert(promptText, replace: false);
  }

  Future<void> _submit() async {
    if (!_canSend || _chatId == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty || _selectedModelId == null) return;

    final openRouterState = ref.read(openRouterProvider);
    if (openRouterState.apiKey == null || openRouterState.apiKey!.isEmpty) {
      _showSetupRequiredDialog();
      return;
    }

    final chatState = ref.read(chatProvider(_chatId!));
    final openRouterModelsState = ref.read(openRouterModelsProvider);
    final selectedModel = openRouterModelsState.models.firstWhereOrNull(
      (model) => model.id == _selectedModelId,
    );

    final imageGeneration = _buildImageGenerationOptions(
      chatState: chatState,
      selectedModel: selectedModel,
    );

    try {
      await ref
          .read(chatProvider(_chatId!).notifier)
          .sendMessage(text, imageGeneration: imageGeneration);

      _controller.clear();
      ref.read(chatDraftProvider(_chatId!).notifier).clear();
    } catch (e) {
      _showOpenRouterErrorDialog(e);
    }
  }

  OpenRouterImageGenerationOptions? _buildImageGenerationOptions({
    required ChatState chatState,
    required OpenRouterModel? selectedModel,
  }) {
    if (!chatState.imageOutputEnabled) {
      return null;
    }

    if (selectedModel == null || !selectedModel.supportsImageOutput) {
      return null;
    }

    final supportsTextOutput = selectedModel.architecture.outputModalities.any(
      (modality) => modality.toLowerCase() == 'text',
    );

    final selectedModalities = supportsTextOutput
        ? chatState.imageModalities
        : ImageModalities.imageOnly;

    return OpenRouterImageGenerationOptions(
      modalities: selectedModalities,
      imageConfig: ImageConfig(
        imageSize: chatState.imageSize,
        aspectRatio: chatState.imageAspectRatio,
      ),
    );
  }

  void _showSetupRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Required'),
        content: const Text(
          'Please add your OpenRouter API key in settings to start chatting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenRouterErrorDialog(Object error) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = Breakpoints.isPhone(context);

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
              if (_canSend) {
                HapticFeedback.lightImpact();
                _submit();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              Row(
                spacing: 4,
                children: [
                  Expanded(
                    child: InputWidget(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 6,
                      enabled: !_loading,
                      keyboardType: TextInputType.multiline,
                      onChanged: _onChanged,
                      hintText: 'Enter text here',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (isPhone)
                    IconButtonWidget(
                      onPressed: _canSend
                          ? () {
                              HapticFeedback.lightImpact();
                              _submit();
                            }
                          : null,
                      icon: const Icon(LucideIcons.send),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 8,
                children: [
                  if (!isPhone)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Cmd+Enter to send',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  Expanded(
                    child: SelectPromptWidget(onPicked: _onInsertPrompt),
                  ),
                  const Expanded(child: SelectAiModelDialog()),
                  const ParametersInputDialog(),
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!isPhone)
                    IconButtonWidget(
                      onPressed: _canSend
                          ? () {
                              HapticFeedback.lightImpact();
                              _submit();
                            }
                          : null,
                      icon: const Icon(LucideIcons.send),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}
