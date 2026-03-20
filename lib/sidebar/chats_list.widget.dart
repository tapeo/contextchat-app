import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/list_tile.widget.dart';
import 'package:contextchat/components/text_button.widget.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_utils.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatsList extends ConsumerStatefulWidget {
  const ChatsList({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends ConsumerState<ChatsList> {
  final ContextMenuController _contextMenuController = ContextMenuController();

  @override
  void dispose() {
    _contextMenuController.remove();
    super.dispose();
  }

  String? _formatChatTitle(String? title) {
    if (title == null || title.isEmpty) return null;
    return title[0].toUpperCase() + title.substring(1);
  }

  void _deleteChat(String chatId) {
    showAppDialog<bool>(
      context: context,
      title: const Text('Delete chat'),
      content: const Text(
        'Are you sure you want to delete this chat? This action cannot be undone.',
      ),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButtonWidget(
          onPressed: () {
            ref.read(chatsProvider.notifier).deleteChat(chatId);
            Navigator.of(context).pop();
          },
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  void _showChatContextMenu(Offset offset, String chatId) {
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (context) {
        return TapRegion(
          onTapOutside: (event) => _contextMenuController.remove(),
          child: AdaptiveTextSelectionToolbar.buttonItems(
            anchors: TextSelectionToolbarAnchors(primaryAnchor: offset),
            buttonItems: [
              ContextMenuButtonItem(
                label: 'Open in file explorer',
                onPressed: () async {
                  _contextMenuController.remove();
                  final file = ref
                      .read(chatDatabaseProvider)
                      .getChatFile(chatId);

                  await FileUtils.revealInFileManager(file.path);
                },
              ),
              ContextMenuButtonItem(
                label: 'Delete',
                onPressed: () {
                  _contextMenuController.remove();
                  _deleteChat(chatId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);
    final chats = chatsState.chats
        .where((c) => c.projectId == widget.projectId)
        .toList();
    final selectedChatId = chatsState.selectedChatId;

    if (chats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No chats yet'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: chats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return GestureDetector(
          onSecondaryTapUp: (details) =>
              _showChatContextMenu(details.globalPosition, chat.id),
          child: ListTileWidget(
            key: ValueKey(chat.id),
            selected: chat.id == selectedChatId,
            style: ListTileStyle2.compact,
            title: Text(
              _formatChatTitle(chat.title) ?? 'Chat ${index + 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              ref
                  .read(projectsProvider.notifier)
                  .selectProject(widget.projectId);
              ref.read(chatsProvider.notifier).selectChat(chat.id);
            },
          ),
        );
      },
    );
  }
}
