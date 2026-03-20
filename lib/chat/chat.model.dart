import 'package:contextchat/chat/message.model.dart';
import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String? projectId;
  final String? title;
  final List<Message> messages;
  final DateTime? updatedAt;

  const Chat({
    required this.id,
    this.projectId,
    this.title,
    required this.messages,
    this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? projectId,
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'messages': messages
          .map(
            (m) => {
              'id': m.id,
              'timestamp': m.timestamp,
              'content': m.content,
              'role': m.role.name,
              'toolCallId': m.toolCallId,
              'toolName': m.toolName,
              'toolCallsJson': m.toolCallsJson,
              'toolError': m.toolError,
              'toolCallsProcessed': m.toolCallsProcessed,
            },
          )
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      title: json['title'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map(
            (m) => Message(
              id: m['id'] as String,
              timestamp: m['timestamp'] as String,
              content: m['content'] as String,
              role: MessageRole.values.firstWhere((r) => r.name == m['role']),
              toolCallId: m['toolCallId'] as String?,
              toolName: m['toolName'] as String?,
              toolCallsJson: m['toolCallsJson'] as String?,
              toolError: (m['toolError'] as bool?) ?? false,
              toolCallsProcessed: (m['toolCallsProcessed'] as bool?) ?? false,
            ),
          )
          .toList(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, projectId, title, messages, updatedAt];
}
