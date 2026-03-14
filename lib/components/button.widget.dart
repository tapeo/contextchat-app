import 'package:contextchat/components/click_opacity.dart';
import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

class ButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? icon;
  final ButtonSize size;
  final Widget? child;

  const ButtonWidget({
    super.key,
    this.onPressed,
    this.label,
    this.icon,
    this.size = ButtonSize.medium,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final (
      padding,
      borderRadius,
      fontSize,
      iconSpacing,
      blur,
      yOffset,
      iconSize,
    ) = switch (size) {
      ButtonSize.small => (
        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        8.0,
        12.0,
        4.0,
        4.0,
        2.0,
        16.0,
      ),
      ButtonSize.medium => (
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        12.0,
        13.0,
        8.0,
        10.0,
        4.0,
        20.0,
      ),
      ButtonSize.large => (
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        16.0,
        14.0,
        10.0,
        12.0,
        6.0,
        24.0,
      ),
    };

    return ClickOpacity(
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: blur,
              offset: Offset(0, yOffset),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: onPressed == null
                      ? Theme.of(context).disabledColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                child: icon!,
              ),
              SizedBox(width: iconSpacing),
            ],
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: onPressed == null
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
