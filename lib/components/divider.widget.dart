import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  const DividerWidget({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
