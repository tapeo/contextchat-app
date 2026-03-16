import 'package:contextchat/chat/select_ai_model.view.dart';
import 'package:contextchat/chat/select_prompt.view.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/input.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Composer extends StatelessWidget {
  const Composer({
    super.key,
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
          child: Column(
            children: [
              InputWidget(
                controller: controller,
                minLines: 1,
                maxLines: 6,
                enabled: !loading,
                keyboardType: TextInputType.multiline,
                onChanged: onChanged,
                hintText: 'Enter text here',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text('Cmd+Enter to send', style: theme.textTheme.bodySmall),
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
    );
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}
