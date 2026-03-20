import 'package:flutter/material.dart';

class ListViewGradientOverlay extends StatelessWidget {
  const ListViewGradientOverlay({
    super.key,
    required this.child,
    this.height = 16,
    this.showTop = true,
    this.showBottom = true,
  });

  final Widget child;
  final double height;
  final bool showTop;
  final bool showBottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showTop)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.85),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.1),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
        if (showBottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: height,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.25),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.25, 0.55, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
