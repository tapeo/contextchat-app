import 'package:flutter/material.dart';

/// A page route with no animation, suitable for desktop apps.
/// This avoids the iOS-style slide transition that MaterialPageRoute
/// uses on macOS/iOS.
class NoTransitionRoute<T> extends PageRouteBuilder<T> {
  NoTransitionRoute({required this.builder, this.title})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: RouteSettings(name: title),
      );

  final WidgetBuilder builder;
  final String? title;
}
