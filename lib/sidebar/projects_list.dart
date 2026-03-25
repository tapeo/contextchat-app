import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/list_tile.dart';
import 'package:contextchat/components/route_transitions.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_utils.dart';
import 'package:contextchat/projects/project_setup.page.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/sidebar/chats_list.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProjectsList extends ConsumerWidget {
  const ProjectsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);

    if (projectsState.projects.isEmpty) {
      return Center(
        child: ButtonWidget(
          onPressed: () {
            Navigator.of(context).push(
              ThemeTransitionRoute(
                builder: (context) => const ProjectSetupPage(),
              ),
            );
          },
          icon: const Icon(Icons.create_new_folder_outlined),
          label: 'Create project',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: projectsState.projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final project = projectsState.projects[index];
        final isSelected = project.id == projectsState.currentProjectId;

        return ProjectSection(
          projectId: project.id,
          projectName: project.name,
          isSelected: isSelected,
        );
      },
    );
  }
}

class ProjectSection extends ConsumerStatefulWidget {
  const ProjectSection({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.isSelected,
  });

  final String projectId;
  final String projectName;
  final bool isSelected;

  @override
  ConsumerState<ProjectSection> createState() => _ProjectSectionState();
}

class _ProjectSectionState extends ConsumerState<ProjectSection> {
  final ContextMenuController _contextMenuController = ContextMenuController();
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _contextMenuController.remove();
    super.dispose();
  }

  void _editProject() {
    Navigator.of(context).push(
      ThemeTransitionRoute(
        builder: (context) => ProjectSetupPage(projectId: widget.projectId),
      ),
    );
  }

  void _deleteProject() {
    showAppDialog<bool>(
      context: context,
      title: const Text('Delete project'),
      content: const Text(
        'Are you sure you want to delete this project? All associated chats and data will be permanently removed.',
      ),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButtonWidget(
          onPressed: () {
            ref.read(projectsProvider.notifier).deleteProject(widget.projectId);
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

  void _showProjectContextMenu(Offset offset) {
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
                  final directory = ref
                      .read(projectDatabaseProvider)
                      .getProjectDirectory(widget.projectId);
                  await FileUtils.revealInFileManager(directory.path);
                },
              ),
              ContextMenuButtonItem(
                label: 'Edit',
                onPressed: () {
                  _contextMenuController.remove();
                  _editProject();
                },
              ),
              ContextMenuButtonItem(
                label: 'Delete',
                onPressed: () {
                  _contextMenuController.remove();
                  _deleteProject();
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
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onSecondaryTapUp: (details) =>
              _showProjectContextMenu(details.globalPosition),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              final now = DateTime.now();
              final diff = now.difference(_lastTapTime);
              if (diff < const Duration(milliseconds: 300)) {
                _editProject();
                _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
              } else {
                _lastTapTime = now;
              }
            },
            child: ListTileWidget(
              leading: Icon(LucideIcons.folder, size: 12),
              title: Text(widget.projectName),
              selected: widget.isSelected,
              style: ListTileStyle2.compact,
              borderRadius: AppTheme.radiusMedium,
              borderRadiusGeometry: const BorderRadius.all(
                Radius.circular(AppTheme.radiusMedium),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButtonWidget(
                    tooltip: 'New chat',
                    icon: const Icon(LucideIcons.plus, size: 12),
                    onPressed: () async {
                      ref
                          .read(projectsProvider.notifier)
                          .selectProject(widget.projectId);
                      final chatId = await ref
                          .read(chatsProvider.notifier)
                          .createChat(widget.projectId);
                      ref.read(chatsProvider.notifier).selectChat(chatId);
                      if (context.mounted) {
                        Scaffold.of(context).closeDrawer();
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                ref
                    .read(projectsProvider.notifier)
                    .selectProject(widget.projectId);
              },
            ),
          ),
        ),
        if (widget.isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: ChatsList(projectId: widget.projectId),
          ),
      ],
    );
  }
}
