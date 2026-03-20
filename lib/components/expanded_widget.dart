import 'package:flutter/material.dart';

class ExpandedWidget extends StatelessWidget {
  const ExpandedWidget({super.key, required this.child, required this.expand});

  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return Expanded(child: child);
    } else {
      return child;
    }
  }
}
