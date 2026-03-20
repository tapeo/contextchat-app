import 'package:flutter/material.dart';
import 'package:contextchat/theme.dart';

class AppDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final double? maxHeight;
  final bool useBottomSheetOnPhone;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
    this.maxWidth = 560,
    this.maxHeight,
    this.useBottomSheetOnPhone = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = Breakpoints.isPhone(context);
    final divider = theme.dividerColor;
    final shadowColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.2);

    if (isPhone && useBottomSheetOnPhone) {
      return _buildBottomSheet(context, theme, shadowColor);
    }

    return _buildDialog(context, theme, divider, shadowColor);
  }

  Widget _buildBottomSheet(
    BuildContext context,
    ThemeData theme,
    Color shadowColor,
  ) {
    final effectivePadding = padding.resolve(Directionality.of(context));
    final phonePadding = EdgeInsets.only(
      top: 20,
      left: effectivePadding.left,
      right: effectivePadding.right,
      bottom: 12,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 1.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 60,
            offset: const Offset(0, 16),
            spreadRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: phonePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (title != null)
              DefaultTextStyle(
                style: theme.textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                child: title!,
              ),
            if (content != null) ...[
              const SizedBox(height: 12),
              Flexible(child: content!),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions!
                    .map((a) => Padding(padding: EdgeInsets.zero, child: a))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    ThemeData theme,
    Color divider,
    Color shadowColor,
  ) {
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
  bool useBottomSheetOnPhone = true,
}) {
  final isPhone = Breakpoints.isPhone(context);

  if (isPhone && useBottomSheetOnPhone && child == null) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: barrierDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        useBottomSheetOnPhone: false,
      ),
    );
  }

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
