import 'package:contextchat/theme.dart';
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
  final TextStyle? style;
  final bool? obscureText;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final String? labelText;
  final TextStyle? labelStyle;
  final Widget? prefixIcon;
  final String? errorText;
  final TextStyle? hintStyle;

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
    this.style,
    this.obscureText,
    this.trailing,
    this.padding,
    this.labelText,
    this.labelStyle,
    this.prefixIcon,
    this.errorText,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      constraints: BoxConstraints(minHeight: labelText != null ? 50 : 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
                labelStyle: labelStyle,
                isDense: true,
                prefixIcon: prefixIcon,
                errorText: errorText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle:
                    hintStyle ??
                    TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
              ),
              style: style ?? const TextStyle(fontSize: 14),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
