import 'package:flutter/material.dart';

enum RowColumnType { row, column }

class RowColumn extends StatelessWidget {
  const RowColumn({super.key, required this.children, required this.type});

  final List<Widget> children;
  final RowColumnType type;

  @override
  Widget build(BuildContext context) {
    if (type == RowColumnType.column) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }
}
