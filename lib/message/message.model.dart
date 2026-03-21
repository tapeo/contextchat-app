import 'package:contextchat/openrouter/openrouter.model.dart';
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
  final List<AssistantImage>? images;

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
    this.images,
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
    images,
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
    List<AssistantImage>? images,
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
      images: images ?? this.images,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere((r) => r.name == json['role']),
      toolCallId: json['toolCallId'] as String?,
      toolName: json['toolName'] as String?,
      toolCallsJson: json['toolCallsJson'] as String?,
      toolError: (json['toolError'] as bool?) ?? false,
      toolCallsProcessed: (json['toolCallsProcessed'] as bool?) ?? false,
      images: json['images'] != null
          ? (json['images'] as List)
                .map(
                  (image) =>
                      AssistantImage.fromJson(image as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'content': content,
      'role': role.name,
      'toolCallId': toolCallId,
      'toolName': toolName,
      'toolCallsJson': toolCallsJson,
      'toolError': toolError,
      'toolCallsProcessed': toolCallsProcessed,
      'images': images?.map((image) => image.toJson()).toList(),
    };
  }
}
