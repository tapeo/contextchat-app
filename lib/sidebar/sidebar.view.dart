import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/no_transition_route.dart';
import 'package:contextchat/projects/project_setup.view.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/prompts/prompts_library.view.dart';
import 'package:contextchat/settings/settings.view.dart';
import 'package:contextchat/sidebar/projects_list.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SidebarView extends ConsumerWidget {
  const SidebarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          const Expanded(
            child: ProjectsList(),
          ),
          Divider(height: 1, color: theme.dividerColor),
          const _SidebarFooter(),
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
