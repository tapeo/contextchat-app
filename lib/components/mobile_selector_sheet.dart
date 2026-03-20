import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/card.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/list_tile.dart';
import 'package:contextchat/projects/project_setup.page.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MobileSelectorSheet extends ConsumerWidget {
  const MobileSelectorSheet({super.key});

  Future<void> _show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MobileSelectorContent(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final chatsState = ref.watch(chatsProvider);
    final currentProjectId = projectsState.currentProjectId;
    final selectedChatId = chatsState.selectedChatId;

    final currentProject = currentProjectId == null
        ? null
        : projectsState.projects.firstWhereOrNull(
            (p) => p.id == currentProjectId,
          );

    final currentChat = selectedChatId == null
        ? null
        : chatsState.chats.firstWhereOrNull((c) => c.id == selectedChatId);

    String label = 'Select project';
    if (currentProject != null) {
      label = currentProject.name;
      if (currentChat != null) {
        label = '${currentProject.name} / ${currentChat.title ?? 'Chat'}';
      }
    }

    return ButtonWidget(
      onPressed: () => _show(context, ref),
      icon: const Icon(LucideIcons.folderOpen, size: 18),
      label: label,
      size: ButtonSize.small,
    );
  }
}

class _MobileSelectorContent extends ConsumerWidget {
  const _MobileSelectorContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectsProvider);
    final chatsState = ref.watch(chatsProvider);
    final currentProjectId = projectsState.currentProjectId;
    final selectedChatId = chatsState.selectedChatId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Projects', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButtonWidget(
                  tooltip: 'New project',
                  icon: const Icon(LucideIcons.plus),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProjectSetupPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: projectsState.projects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No projects yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ButtonWidget(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProjectSetupPage(),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.plus),
                          label: 'Create project',
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: projectsState.projects.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final project = projectsState.projects[index];
                      final isProjectSelected = project.id == currentProjectId;
                      final projectChats = chatsState.chats
                          .where((c) => c.projectId == project.id)
                          .toList();

                      return CardWidget(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            ListTileWidget(
                              style: ListTileStyle2.normal,
                              leading: Icon(
                                LucideIcons.folder,
                                size: 20,
                                color: isProjectSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              title: Text(
                                project.name,
                                style: TextStyle(
                                  fontWeight: isProjectSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isProjectSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              trailing: IconButtonWidget(
                                tooltip: 'New chat',
                                icon: const Icon(LucideIcons.plus, size: 18),
                                onPressed: () async {
                                  ref
                                      .read(projectsProvider.notifier)
                                      .selectProject(project.id);
                                  final chatId = await ref
                                      .read(chatsProvider.notifier)
                                      .createChat(project.id);
                                  ref
                                      .read(chatsProvider.notifier)
                                      .selectChat(chatId);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                              onTap: () {
                                ref
                                    .read(projectsProvider.notifier)
                                    .selectProject(project.id);
                              },
                            ),
                            if (isProjectSelected &&
                                projectChats.isNotEmpty) ...[
                              Divider(height: 1, color: theme.dividerColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Column(
                                  children: [
                                    for (
                                      int i = 0;
                                      i < projectChats.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(height: 4),
                                      _ChatListItem(
                                        chat: projectChats[i],
                                        isSelected:
                                            projectChats[i].id ==
                                            selectedChatId,
                                        onTap: () {
                                          ref
                                              .read(projectsProvider.notifier)
                                              .selectProject(project.id);
                                          ref
                                              .read(chatsProvider.notifier)
                                              .selectChat(projectChats[i].id);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.isSelected,
    required this.onTap,
  });

  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chat.title ?? 'Chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
