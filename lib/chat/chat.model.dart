import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
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
            (message) => {
              'id': message.id,
              'timestamp': message.timestamp,
              'content': message.content,
              'role': message.role.name,
              'toolCallId': message.toolCallId,
              'toolName': message.toolName,
              'toolCallsJson': message.toolCallsJson,
              'toolError': message.toolError,
              'toolCallsProcessed': message.toolCallsProcessed,
              'images': message.images?.map((image) => image.toJson()).toList(),
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
            (message) => Message(
              id: message['id'] as String,
              timestamp: message['timestamp'] as String,
              content: message['content'] as String,
              role: MessageRole.values.firstWhere(
                (r) => r.name == message['role'],
              ),
              toolCallId: message['toolCallId'] as String?,
              toolName: message['toolName'] as String?,
              toolCallsJson: message['toolCallsJson'] as String?,
              toolError: (message['toolError'] as bool?) ?? false,
              toolCallsProcessed:
                  (message['toolCallsProcessed'] as bool?) ?? false,
              images: message['images'] != null
                  ? (message['images'] as List)
                        .map(
                          (image) => AssistantImage.fromJson(
                            image as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : null,
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
