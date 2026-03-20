import 'package:contextchat/components/click_opacity.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';

class IconButtonStyle {
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double iconSize;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final double shadowOpacity;

  const IconButtonStyle({
    required this.padding,
    required this.borderRadius,
    required this.iconSize,
    required this.shadowBlurRadius,
    required this.shadowOffset,
    required this.shadowOpacity,
  });

  static const IconButtonStyle normal = IconButtonStyle(
    padding: EdgeInsets.all(8),
    borderRadius: AppTheme.radiusMedium,
    iconSize: 20,
    shadowBlurRadius: 10,
    shadowOffset: Offset(0, 4),
    shadowOpacity: 0.05,
  );

  static const IconButtonStyle small = IconButtonStyle(
    padding: EdgeInsets.all(6),
    borderRadius: AppTheme.radiusMedium,
    iconSize: 16,
    shadowBlurRadius: 4,
    shadowOffset: Offset(0, 2),
    shadowOpacity: 0.05,
  );

  static const IconButtonStyle large = IconButtonStyle(
    padding: EdgeInsets.all(12),
    borderRadius: AppTheme.radiusMedium,
    iconSize: 24,
    shadowBlurRadius: 12,
    shadowOffset: Offset(0, 6),
    shadowOpacity: 0.08,
  );
}

class IconButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final bool small;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final IconButtonStyle style;

  const IconButtonWidget({
    super.key,
    this.onPressed,
    required this.icon,
    this.small = false,
    this.tooltip,
    this.padding,
    this.style = IconButtonStyle.small,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = small ? IconButtonStyle.small : style;
    final effectivePadding = padding ?? effectiveStyle.padding;

    final child = ClickOpacity(
      onTap: onPressed,
      child: Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effectiveStyle.borderRadius),
        ),
        child: IconTheme(
          data: IconThemeData(
            size: effectiveStyle.iconSize,
            color: onPressed == null
                ? Theme.of(context).disabledColor
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          child: icon,
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return child;
    }

    return Tooltip(message: tooltip!, child: child);
  }
}
