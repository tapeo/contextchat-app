import 'package:contextchat/components/click_opacity.dart';
import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const TextButtonWidget({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClickOpacity(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: onPressed == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primary,
          ),
          child: child,
        ),
      ),
    );
  }
}
