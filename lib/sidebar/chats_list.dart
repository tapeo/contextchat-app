import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/list_tile.dart';
import 'package:contextchat/components/popup_menu.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_utils.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ChatMenuAction { openInExplorer, delete }

class ChatsList extends ConsumerStatefulWidget {
  const ChatsList({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends ConsumerState<ChatsList> {
  @override
  void dispose() {
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

  void _onChatMenuSelected(ChatMenuAction action, String chatId) {
    switch (action) {
      case ChatMenuAction.openInExplorer:
        final file = ref.read(chatDatabaseProvider).getChatFile(chatId);
        FileUtils.revealInFileManager(file.path);
      case ChatMenuAction.delete:
        _deleteChat(chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);

    final chats =
        chatsState.chats.where((c) => c.projectId == widget.projectId).toList()
          ..sort((a, b) {
            final aTime = a.updatedAt;
            final bTime = b.updatedAt;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Dismissible(
          key: ValueKey(chat.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            _deleteChat(chat.id);
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: ListTileWidget(
            selected: chat.id == selectedChatId,
            style: ListTileStyle2.dense,
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
              Scaffold.maybeOf(context)?.closeDrawer();
            },
            trailing: PopupMenuWidget<ChatMenuAction>(
              key: ValueKey('chat_menu_${chat.id}'),
              items: [
                PopupMenuItemWidget(
                  value: ChatMenuAction.openInExplorer,
                  label: 'Open file',
                  icon: const Icon(LucideIcons.folder, size: 16),
                ),
                PopupMenuItemWidget(
                  value: ChatMenuAction.delete,
                  label: 'Delete',
                  icon: const Icon(LucideIcons.trash, size: 16),
                ),
              ],
              onSelected: (action) => _onChatMenuSelected(action, chat.id),
              child: IconButtonWidget(
                icon: const Icon(LucideIcons.ellipsisVertical, size: 14),
                onPressed: null,
              ),
            ),
          ),
        );
      },
    );
  }
}
