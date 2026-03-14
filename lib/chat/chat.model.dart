import 'package:app/chat/message.model.dart';
import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String? projectId;
  final List<Message> messages;

  const Chat({required this.id, this.projectId, required this.messages});

  Chat copyWith({String? id, String? projectId, List<Message>? messages}) {
    return Chat(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'messages': messages
          .map(
            (m) => {
              'id': m.id,
              'timestamp': m.timestamp,
              'content': m.content,
              'role': m.role.name,
            },
          )
          .toList(),
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map(
            (m) => Message(
              id: m['id'] as String,
              timestamp: m['timestamp'] as String,
              content: m['content'] as String,
              role: MessageRole.values.firstWhere((r) => r.name == m['role']),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, projectId, messages];
}
