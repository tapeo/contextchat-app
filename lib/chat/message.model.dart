import 'package:equatable/equatable.dart';

enum MessageRole {
  system("system"),
  user("user"),
  assistant("assistant"),
  tool("tool");

  final String value;
  const MessageRole(this.value);
}

class Message extends Equatable {
  final String id;
  final String timestamp;
  final String content;
  final MessageRole role;
  final String? toolCallId;
  final String? toolName;
  final String? toolCallsJson;
  final bool toolError;
  final bool toolCallsProcessed;

  const Message({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.role,
    this.toolCallId,
    this.toolName,
    this.toolCallsJson,
    this.toolError = false,
    this.toolCallsProcessed = false,
  });

  @override
  List<Object?> get props => [
    id,
    timestamp,
    content,
    role,
    toolCallId,
    toolName,
    toolCallsJson,
    toolError,
    toolCallsProcessed,
  ];

  Message copyWith({
    String? id,
    String? timestamp,
    String? content,
    MessageRole? role,
    String? toolCallId,
    String? toolName,
    String? toolCallsJson,
    bool? toolError,
    bool? toolCallsProcessed,
  }) {
    return Message(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
      role: role ?? this.role,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      toolCallsJson: toolCallsJson ?? this.toolCallsJson,
      toolError: toolError ?? this.toolError,
      toolCallsProcessed: toolCallsProcessed ?? this.toolCallsProcessed,
    );
  }
}
