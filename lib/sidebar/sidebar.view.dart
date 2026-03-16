import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/button.widget.dart';
import 'package:contextchat/components/card.widget.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/list_tile.widget.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/no_transition_route.dart';
import 'package:contextchat/projects/project_setup.view.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/prompts/prompts_library.view.dart';
import 'package:contextchat/settings/settings.view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SidebarView extends ConsumerWidget {
  const SidebarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Expanded(
            child: projectsState.projects.isEmpty
                ? Center(
                    child: ButtonWidget(
                      onPressed: () {
                        Navigator.of(context).push(
                          NoTransitionRoute(
                            builder: (context) => const ProjectSetupView(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: 'Create project',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                    itemCount: projectsState.projects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = projectsState.projects[index];
                      final isSelected =
                          project.id == projectsState.currentProjectId;

                      return _ProjectSection(
                        projectId: project.id,
                        projectName: project.name,
                        isSelected: isSelected,
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _ProjectSection extends ConsumerWidget {
  const _ProjectSection({
    required this.projectId,
    required this.projectName,
    required this.isSelected,
  });

  final String projectId;
  final String projectName;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(
      chatsProvider.select(
        (state) => state.chats.where((c) => c.projectId == projectId).toList(),
      ),
    );
    final selectedChatId = ref.watch(
      chatsProvider.select((state) => state.selectedChatId),
    );
    final theme = Theme.of(context);

    return CardWidget(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTileWidget(
            leading: const Icon(LucideIcons.folder),
            title: Text(projectName),
            selected: isSelected,
            style: ListTileStyle2.compact,
            borderRadius: 16,
            borderRadiusGeometry: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButtonWidget(
                  tooltip: 'Edit project',
                  icon: Icon(LucideIcons.pencil, size: 10),
                  onPressed: () {
                    Navigator.of(context).push(
                      NoTransitionRoute(
                        builder: (context) =>
                            ProjectSetupView(projectId: projectId),
                      ),
                    );
                  },
                ),
                IconButtonWidget(
                  tooltip: 'Add chat',
                  icon: Icon(LucideIcons.plus, size: 12),
                  onPressed: () async {
                    ref
                        .read(projectsProvider.notifier)
                        .selectProject(projectId);
                    final chatId = await ref
                        .read(chatsProvider.notifier)
                        .createChat(projectId);
                    ref.read(chatsProvider.notifier).selectChat(chatId);
                  },
                ),
              ],
            ),
            onTap: () {
              ref.read(projectsProvider.notifier).selectProject(projectId);
            },
          ),
          if (isSelected) Divider(height: 1, color: theme.dividerColor),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: chats.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No chats yet'),
                      ),
                    )
                  : Column(
                      children: [
                        for (var index = 0; index < chats.length; index++)
                          ListTileWidget(
                            selected: chats[index].id == selectedChatId,
                            style: ListTileStyle2.compact,
                            title: Text('Chat ${index + 1}'),
                            trailing: IconButtonWidget(
                              tooltip: 'Delete chat',
                              icon: const Icon(LucideIcons.trash2, size: 10),
                              onPressed: () {
                                showAppDialog<bool>(
                                  context: context,
                                  title: const Text('Delete chat'),
                                  content: const Text(
                                    'Are you sure you want to delete this chat? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(chatsProvider.notifier)
                                            .deleteChat(chats[index].id);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(projectsProvider.notifier)
                                  .selectProject(projectId);
                              ref
                                  .read(chatsProvider.notifier)
                                  .selectChat(chats[index].id);
                            },
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final hasProjects = projectsState.projects.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          if (hasProjects)
            IconButtonWidget(
              tooltip: 'Add project',
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  NoTransitionRoute(
                    builder: (context) => const ProjectSetupView(),
                  ),
                );
              },
            ),
          IconButtonWidget(
            tooltip: 'Prompts',
            icon: const Icon(LucideIcons.bookText),
            onPressed: () {
              Navigator.of(context).push(
                NoTransitionRoute(
                  builder: (context) => const PromptsLibraryView(),
                ),
              );
            },
          ),
          IconButtonWidget(
            tooltip: 'Settings',
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.of(context).push(
                NoTransitionRoute(builder: (context) => const SettingsView()),
              );
            },
          ),
        ],
      ),
    );
  }
}
