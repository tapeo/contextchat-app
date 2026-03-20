import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';

extension ResponsiveBuildContext on BuildContext {
  bool get isPhone => Breakpoints.isPhone(this);
  bool get isTablet => Breakpoints.isTablet(this);
  bool get isDesktop => Breakpoints.isDesktop(this);
  bool get isWideScreen => Breakpoints.isWideScreen(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get phonePadding => Spacing.phonePadding(this);

  double get dialogMaxWidth => ContentWidths.dialog(this);
  double get messageMaxWidth => ContentWidths.message(this);
}
