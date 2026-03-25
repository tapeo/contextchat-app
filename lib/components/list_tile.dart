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
    trailingSpacing: 4,
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

class ListTileWidget extends StatefulWidget {
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
  State<ListTileWidget> createState() => _ListTileWidgetState();
}

class _ListTileWidgetState extends State<ListTileWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    if (widget.selected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
    } else if (_isHovered) {
      backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    } else {
      backgroundColor = Colors.transparent;
    }

    Widget content = Container(
      padding: widget.padding ?? widget.style.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            widget.borderRadiusGeometry ??
            BorderRadius.circular(AppTheme.radiusMedium),
        border: widget.showBorder
            ? Border.all(color: theme.dividerColor)
            : null,
        boxShadow: widget.showShadow
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
          if (widget.leading != null) ...[
            IconTheme(
              data: theme.iconTheme.copyWith(
                size: widget.style.iconSize,
                color: widget.selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              child: widget.leading!,
            ),
            SizedBox(width: widget.style.leadingSpacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: widget.style.titleFontSize,
                  ),
                  child: widget.title,
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: widget.style.subtitleSpacing),
                  DefaultTextStyle(
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: widget.style.subtitleFontSize,
                    ),
                    child: widget.subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            SizedBox(width: widget.style.trailingSpacing),
            widget.trailing!,
          ],
        ],
      ),
    );

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: content,
    );

    if (widget.onTap != null) {
      return ClickOpacity(onTap: widget.onTap, child: child);
    }

    return child;
  }
}
