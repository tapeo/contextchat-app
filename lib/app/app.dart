import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.page.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/custom_app_bar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/prompts/prompts.provider.dart';
import 'package:contextchat/sidebar/sidebar.view.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  double _sidebarFraction = 0.25;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).initialize();
      ref.read(chatsProvider.notifier).initialize();
      ref.read(promptsProvider.notifier).initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Breakpoints.isPhone(context);

    if (isPhone) {
      return _PhoneShell();
    }

    return _DesktopShell(
      sidebarFraction: _sidebarFraction,
      onSidebarFractionChanged: (value) {
        setState(() {
          _sidebarFraction = value;
        });
      },
    );
  }
}

class _PhoneShell extends ConsumerWidget {
  const _PhoneShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectsProvider);
    final currentProjectId = projectsState.currentProjectId;
    final currentProject = currentProjectId == null
        ? null
        : projectsState.projects.firstWhereOrNull(
            (p) => p.id == currentProjectId,
          );

    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
        title: currentProject?.name ?? 'Select project',
        leading: Builder(
          builder: (context) => IconButtonWidget(
            icon: const Icon(LucideIcons.panelLeft),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: SafeArea(child: SidebarView()),
      ),
      body: SafeArea(child: const ChatPage()),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.sidebarFraction,
    required this.onSidebarFractionChanged,
  });

  static const double _minSidebarFraction = 0.3;
  static const double _maxSidebarFraction = 0.5;

  final double sidebarFraction;
  final ValueChanged<double> onSidebarFractionChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidebarWidth = constraints.maxWidth * sidebarFraction;

            return Stack(
              children: [
                Row(
                  children: [
                    SizedBox(width: sidebarWidth, child: const SidebarView()),
                    const Expanded(child: ChatPage()),
                  ],
                ),
                Positioned(
                  left: sidebarWidth - 8,
                  top: 0,
                  bottom: 0,
                  child: _ResizeHandle(
                    onDragUpdate: (delta) {
                      onSidebarFractionChanged(
                        (sidebarFraction + (delta / constraints.maxWidth))
                            .clamp(_minSidebarFraction, _maxSidebarFraction),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDragUpdate});

  final ValueChanged<double> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
        child: Container(
          width: 16,
          alignment: Alignment.center,
          child: Container(
            width: 1,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
