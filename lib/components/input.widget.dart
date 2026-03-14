import 'package:flutter/material.dart';

class InputWidget extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool? expands;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextAlignVertical? textAlignVertical;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool? obscureText;
  final Widget? trailing;

  const InputWidget({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.expands,
    this.maxLines,
    this.minLines,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textAlignVertical,
    this.decoration,
    this.style,
    this.obscureText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              expands: expands ?? false,
              maxLines: maxLines ?? (expands == true ? null : 1),
              minLines: minLines,
              keyboardType: keyboardType,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textAlignVertical: textAlignVertical,
              obscureText: obscureText ?? false,
              decoration:
                  decoration ??
                  InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle: Theme.of(context).textTheme.bodySmall,
                  ),
              style: style ?? const TextStyle(fontSize: 14),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
