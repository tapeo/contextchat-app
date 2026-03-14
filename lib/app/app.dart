import 'package:contextchat/chat/chat.ui.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/sidebar/sidebar.view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  static const double _minSidebarFraction = 0.2;
  static const double _maxSidebarFraction = 0.4;

  double _sidebarFraction = 0.25;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).initialize();
      ref.read(chatsProvider.notifier).initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = constraints.maxWidth * _sidebarFraction;

          return Row(
            children: [
              SizedBox(width: sidebarWidth, child: const SidebarView()),
              _ResizeHandle(
                onDragUpdate: (delta) {
                  setState(() {
                    _sidebarFraction =
                        (_sidebarFraction + (delta / constraints.maxWidth))
                            .clamp(_minSidebarFraction, _maxSidebarFraction);
                  });
                },
              ),
              const Expanded(child: ChatUi()),
            ],
          );
        },
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
            alignment: Alignment.centerLeft,
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
