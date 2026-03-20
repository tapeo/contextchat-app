import 'package:contextchat/chat/select_ai_model.dialog.dart';
import 'package:contextchat/chat/select_prompt.widget.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComposerWidget extends StatelessWidget {
  const ComposerWidget({
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
              Row(
                spacing: 4,
                children: [
                  Expanded(
                    child: InputWidget(
                      controller: controller,
                      minLines: 1,
                      maxLines: 6,
                      enabled: !loading,
                      keyboardType: TextInputType.multiline,
                      onChanged: onChanged,
                      hintText: 'Enter text here',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (isPhone)
                    IconButtonWidget(
                      onPressed: canSend ? onSubmit : null,
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
                    child: SelectPromptWidget(
                      onPicked: (promptText) => onInsertPrompt(promptText),
                    ),
                  ),
                  Expanded(child: const SelectAiModelDialog()),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!isPhone)
                    IconButtonWidget(
                      onPressed: canSend ? onSubmit : null,
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
