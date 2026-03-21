import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final double? maxHeight;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.2);

    final effectivePadding = padding.resolve(Directionality.of(context));
    final sheetPadding = EdgeInsets.only(
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
        padding: sheetPadding,
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
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  Widget? child,
  bool barrierDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: barrierDismissible,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      final sheetBackground = theme.cardColor.withValues(alpha: 1.0);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child:
              child ??
              AppDialog(title: title, content: content, actions: actions),
        ),
      );
    },
  );
}
