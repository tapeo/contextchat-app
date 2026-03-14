import 'package:flutter/material.dart';

/// A reusable application dialog with consistent styling and transitions
/// similar to the New Tab overlay. Use via [showAppDialog] or directly
/// embed [AppDialog] in a `showGeneralDialog`.
class AppDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final double? maxHeight;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
    this.maxWidth = 560,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;
    final shadowColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.2);

    final dialogBody = Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 60,
            offset: const Offset(0, 16),
            spreadRadius: 8,
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 60,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              DefaultTextStyle(
                style: theme.textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: title!,
                ),
              ),
            if (content != null) Flexible(child: content!),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...actions!.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: a,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: dialogBody),
      ),
    );
  }
}

Route<dynamic>? _currentDialogRoute;

Future<T?> showAppDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  Widget? child,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Duration duration = const Duration(milliseconds: 260),
  Duration reverseDuration = const Duration(milliseconds: 130),
}) {
  if (_currentDialogRoute != null && _currentDialogRoute!.isActive) {
    _currentDialogRoute!.navigator?.removeRoute(_currentDialogRoute!);
  }

  final route = RawDialogRoute<T>(
    pageBuilder: (context, _, _) {
      if (child != null) return child;
      return AppDialog(title: title, content: content, actions: actions);
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: duration,
    transitionBuilder: (context, animation, secondaryAnimation, childWidget) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInCubic,
      );
      final slide =
          Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: childWidget),
      );
    },
  );

  _currentDialogRoute = route;

  return Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  ).push<T>(route).then((result) {
    if (_currentDialogRoute == route) {
      _currentDialogRoute = null;
    }
    return result;
  });
}
