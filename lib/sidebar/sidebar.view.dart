import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/custom_app_bar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/route_transitions.dart';
import 'package:contextchat/projects/project_setup.page.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/prompts/prompts_library.page.dart';
import 'package:contextchat/settings/settings.page.dart';
import 'package:contextchat/sidebar/projects_list.dart';
import 'package:contextchat/sync/models/enums.dart';
import 'package:contextchat/sync/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SidebarView extends ConsumerWidget {
  const SidebarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    ref.listen(syncProvider, (previous, next) {
      if (previous?.status == SyncStatus.pulling &&
          next.status == SyncStatus.idle) {
        ref.read(projectsProvider.notifier).initialize();
        ref.read(chatsProvider.notifier).initialize();
      }
    });

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarHeader(title: 'ContextChat'),
          const Expanded(child: ProjectsList()),
          Divider(height: 1, color: theme.dividerColor),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: CustomAppBar().preferredSize.height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style:
            theme.appBarTheme.titleTextStyle ??
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              tooltip: 'License',
              icon: const Icon(LucideIcons.fileText),
              onPressed: () {
                showLicensePage(context: context);
              },
            ),
          IconButtonWidget(
            tooltip: 'Add project',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () {
              Navigator.of(context).push(
                ThemeTransitionRoute(
                  builder: (context) => const ProjectSetupPage(),
                ),
              );
            },
          ),
          IconButtonWidget(
            tooltip: 'Prompts',
            icon: const Icon(LucideIcons.bookText),
            onPressed: () {
              Navigator.of(context).push(
                ThemeTransitionRoute(
                  builder: (context) => const PromptsLibraryPage(),
                ),
              );
            },
          ),
          IconButtonWidget(
            tooltip: 'Settings',
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.of(context).push(
                ThemeTransitionRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
