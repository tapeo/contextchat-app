import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final baseTextColor =
      theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface;

  // Neutral-only style: button-like translucent background blended with surface
  final Color background = Color.alphaBlend(
    baseTextColor.withValues(alpha: 0.12),
    colorScheme.surface,
  );
  final Color foreground = baseTextColor.withValues(alpha: 0.95);
  final Color borderColor = baseTextColor.withValues(alpha: 0.12);

  // Compute centered margins to simulate a max width without using SnackBar.width
  const double targetWidth = 360;
  const double minMargin = 32;
  final double screenWidth = MediaQuery.of(context).size.width;
  final double extra = (screenWidth - targetWidth) / 2;
  final double horizontal = extra > minMargin ? extra : minMargin;
  final EdgeInsets margin = EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: minMargin,
  );

  final snackBar = SnackBar(
    content: Text(
      message,
      style:
          theme.textTheme.bodySmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ) ??
          TextStyle(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
      textAlign: TextAlign.center,
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: background,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    duration: duration ?? const Duration(seconds: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: borderColor, width: 1),
    ),
    margin: margin,
    showCloseIcon: false,
    elevation: 0,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
