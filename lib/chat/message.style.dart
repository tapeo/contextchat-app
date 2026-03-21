import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';

class MessageColors {
  final Color? backgroundColor;
  final Color selectionColor;
  final Color onColor;
  final Color errorOnColor;
  final Color toolHeaderColor;

  const MessageColors({
    this.backgroundColor,
    required this.selectionColor,
    required this.onColor,
    required this.errorOnColor,
    required this.toolHeaderColor,
  });
}

class MessageStyle {
  final Alignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double horizontalMargin;
  final double bottomLeftRadius;
  final double bottomRightRadius;

  const MessageStyle({
    required this.alignment,
    required this.crossAxisAlignment,
    required this.horizontalMargin,
    required this.bottomLeftRadius,
    required this.bottomRightRadius,
  });

  static const user = MessageStyle(
    alignment: Alignment.centerRight,
    crossAxisAlignment: CrossAxisAlignment.end,
    horizontalMargin: 16.0,
    bottomLeftRadius: AppTheme.radiusMedium,
    bottomRightRadius: AppTheme.radiusMedium / 4,
  );

  static const tool = MessageStyle(
    alignment: Alignment.centerRight,
    crossAxisAlignment: CrossAxisAlignment.end,
    horizontalMargin: 16.0,
    bottomLeftRadius: AppTheme.radiusMedium,
    bottomRightRadius: AppTheme.radiusMedium / 4,
  );

  static const assistant = MessageStyle(
    alignment: Alignment.centerLeft,
    crossAxisAlignment: CrossAxisAlignment.start,
    horizontalMargin: 0.0,
    bottomLeftRadius: AppTheme.radiusMedium / 4,
    bottomRightRadius: AppTheme.radiusMedium,
  );

  static const system = MessageStyle(
    alignment: Alignment.centerLeft,
    crossAxisAlignment: CrossAxisAlignment.start,
    horizontalMargin: 0.0,
    bottomLeftRadius: AppTheme.radiusMedium / 4,
    bottomRightRadius: AppTheme.radiusMedium,
  );

  static MessageStyle fromRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return user;
      case MessageRole.tool:
        return tool;
      case MessageRole.assistant:
        return assistant;
      case MessageRole.system:
        return system;
    }
  }

  MessageColors colors(ColorScheme colorScheme) {
    if (this == user || this == tool) {
      return MessageColors(
        backgroundColor: colorScheme.primary,
        selectionColor: colorScheme.onPrimary.withValues(alpha: 0.3),
        onColor: colorScheme.onPrimary,
        errorOnColor: colorScheme.onPrimary,
        toolHeaderColor: colorScheme.onPrimary,
      );
    }
    if (this == assistant) {
      return MessageColors(
        backgroundColor: null,
        selectionColor: colorScheme.primary.withValues(alpha: 0.2),
        onColor: colorScheme.onSurface,
        errorOnColor: colorScheme.error,
        toolHeaderColor: colorScheme.primary,
      );
    }
    return MessageColors(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectionColor: colorScheme.primary.withValues(alpha: 0.2),
      onColor: colorScheme.onSurface,
      errorOnColor: colorScheme.error,
      toolHeaderColor: colorScheme.primary,
    );
  }
}
