import 'package:contextchat/components/click_opacity.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';

class ListTileStyle2 {
  final EdgeInsets padding;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final double leadingSpacing;
  final double trailingSpacing;
  final double subtitleSpacing;

  const ListTileStyle2({
    required this.padding,
    required this.iconSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.leadingSpacing,
    required this.trailingSpacing,
    required this.subtitleSpacing,
  });

  static const ListTileStyle2 normal = ListTileStyle2(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    iconSize: 24,
    titleFontSize: 14,
    subtitleFontSize: 12,
    leadingSpacing: 16,
    trailingSpacing: 8,
    subtitleSpacing: 2,
  );

  static const ListTileStyle2 dense = ListTileStyle2(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    iconSize: 20,
    titleFontSize: 13,
    subtitleFontSize: 11,
    leadingSpacing: 10,
    trailingSpacing: 8,
    subtitleSpacing: 2,
  );

  static const ListTileStyle2 compact = ListTileStyle2(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    iconSize: 18,
    titleFontSize: 12,
    subtitleFontSize: 10,
    leadingSpacing: 8,
    trailingSpacing: 2,
    subtitleSpacing: 0,
  );
}

class ListTileWidget extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showBorder;
  final bool showShadow;
  final BorderRadius? borderRadiusGeometry;
  final ListTileStyle2 style;

  const ListTileWidget({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.padding,
    this.borderRadius = AppTheme.radiusMedium,
    this.showBorder = false,
    this.showShadow = false,
    this.borderRadiusGeometry,
    this.style = ListTileStyle2.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Container(
      padding: padding ?? style.padding,
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius:
            borderRadiusGeometry ??
            BorderRadius.circular(AppTheme.radiusMedium),
        border: showBorder ? Border.all(color: theme.dividerColor) : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: theme.iconTheme.copyWith(
                size: style.iconSize,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              child: leading!,
            ),
            SizedBox(width: style.leadingSpacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: style.titleFontSize,
                  ),
                  child: title,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: style.subtitleSpacing),
                  DefaultTextStyle(
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: style.subtitleFontSize,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: style.trailingSpacing),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return ClickOpacity(onTap: onTap, child: content);
    }

    return content;
  }
}
