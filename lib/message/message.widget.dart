import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/message/widgets/assistant_message.widget.dart';
import 'package:contextchat/message/widgets/system_message.widget.dart';
import 'package:contextchat/message/widgets/tool_message.widget.dart';
import 'package:contextchat/message/widgets/user_message.widget.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({super.key, required this.message, this.onCopy});

  final Message message;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return UserMessageWidget(message: message, onCopy: onCopy);
      case MessageRole.assistant:
        return AssistantMessageWidget(message: message, onCopy: onCopy);
      case MessageRole.tool:
        return ToolMessageWidget(message: message, onCopy: onCopy);
      case MessageRole.system:
        return SystemMessageWidget(message: message, onCopy: onCopy);
    }
  }
}
