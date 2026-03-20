import 'package:flutter/material.dart';

class ResizableTextArea extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double minHeight;
  final double maxHeight;
  final double initialHeight;
  final Widget? child;
  final TextStyle? textStyle;

  const ResizableTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.enabled = true,
    this.onChanged,
    this.minHeight = 100,
    this.maxHeight = 500,
    this.initialHeight = 150,
    this.child,
    this.textStyle,
  });

  @override
  State<ResizableTextArea> createState() => _ResizableTextAreaState();
}

class _ResizableTextAreaState extends State<ResizableTextArea> {
  late double _height;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: _height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: BoxBorder.fromLTRB(
              left: BorderSide(color: theme.dividerColor),
              top: BorderSide(color: theme.dividerColor),
              right: BorderSide(color: theme.dividerColor),
            ),
          ),
          child:
              widget.child ??
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                onChanged: widget.onChanged,
                style: widget.textStyle,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodySmall,
                  labelStyle: theme.textTheme.bodySmall,
                ),
              ),
        ),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _height = (_height + details.delta.dy).clamp(
                widget.minHeight,
                widget.maxHeight,
              );
            });
          },
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(color: theme.dividerColor),
                right: BorderSide(color: theme.dividerColor),
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
