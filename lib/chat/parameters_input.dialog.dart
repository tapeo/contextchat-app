import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/button_selector.dart';
import 'package:contextchat/components/dropdown.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/switch.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ParametersInputDialog extends ConsumerStatefulWidget {
  const ParametersInputDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ParametersInputViewState();
  }

  static const aspectRatios = [
    '1:1',
    '16:9',
    '9:16',
    '4:3',
    '3:4',
    '3:2',
    '2:3',
  ];

  static const imageSizes = ['0.5K', '1K', '2K', '4K'];
}

class _ParametersInputViewState extends ConsumerState<ParametersInputDialog> {
  String? get chatId =>
      ref.watch(chatsProvider.select((state) => state.selectedChatId));

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return const SizedBox.shrink();
    }

    return IconButtonWidget(
      onPressed: () => _openParametersDialog(context),
      small: true,
      icon: const Icon(LucideIcons.settings),
    );
  }

  Future<void> _openParametersDialog(BuildContext context) async {
    HapticFeedback.lightImpact();

    await showAppDialog<void>(
      context: context,
      title: const Text('Parameters'),
      content: _ParametersContent(chatId: chatId!),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ParametersContent extends ConsumerWidget {
  const _ParametersContent({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(chatId));
    final notifier = ref.read(chatProvider(chatId).notifier);
    final isPhone = Breakpoints.isPhone(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: isPhone ? MediaQuery.sizeOf(context).height * 0.5 : 400,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SwitchWidget(
            value: chatState.imageOutputEnabled,
            onChanged: (value) => notifier.setImageOutputEnabled(value),
            label: 'Image output',
          ),
          if (chatState.imageOutputEnabled) ...[
            ButtonSelectorWidget<ImageModalities>(
              options: ImageModalities.values,
              selectedOption: chatState.imageModalities,
              labelBuilder: (option) {
                switch (option) {
                  case ImageModalities.imageOnly:
                    return 'Image only';
                  case ImageModalities.imagePlusText:
                    return 'Image + text';
                  case ImageModalities.textOnly:
                    return 'Text only';
                }
              },
              onSelected: (value) => notifier.setImageModalities(value),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DropdownWidget<String>(
                    value:
                        ParametersInputDialog.aspectRatios.contains(
                          chatState.imageAspectRatio,
                        )
                        ? chatState.imageAspectRatio
                        : ParametersInputDialog.aspectRatios.first,
                    items: ParametersInputDialog.aspectRatios,
                    labelBuilder: (value) => value,
                    labelText: 'Aspect ratio',
                    onChanged: (value) {
                      if (value != null) {
                        notifier.setImageAspectRatio(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: DropdownWidget<String>(
                    value:
                        ParametersInputDialog.imageSizes.contains(
                          chatState.imageSize,
                        )
                        ? chatState.imageSize
                        : '1K',
                    items: ParametersInputDialog.imageSizes,
                    labelBuilder: (value) => value,
                    labelText: 'Image size',
                    onChanged: (value) {
                      if (value != null) {
                        notifier.setImageSize(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
