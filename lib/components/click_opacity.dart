import 'package:flutter/material.dart';

class ClickOpacity extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;
  final Duration duration;

  const ClickOpacity({
    super.key,
    required this.child,
    this.onTap,
    this.pressedOpacity = 0.5,
    this.duration = const Duration(milliseconds: 100),
  }) : assert(pressedOpacity >= 0.0 && pressedOpacity <= 1.0);

  @override
  State<ClickOpacity> createState() => _ClickOpacityState();
}

class _ClickOpacityState extends State<ClickOpacity> {
  bool _isPressed = false;
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _opacity = 0.6),
      onExit: (_) => setState(() => _opacity = 1.0),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 180),
        opacity: _opacity,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            setState(() {
              _isPressed = true;
            });
          },
          onTapUp: (TapUpDetails details) {
            setState(() {
              _isPressed = false;
            });
            widget.onTap?.call();
          },
          onTapCancel: () {
            setState(() {
              _isPressed = false;
            });
          },
          child: AnimatedOpacity(
            opacity: _isPressed ? widget.pressedOpacity : 1.0,
            duration: widget.duration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
