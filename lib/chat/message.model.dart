import 'package:equatable/equatable.dart';

enum MessageRole {
  system("system"),
  user("user"),
  assistant("assistant");

  final String value;
  const MessageRole(this.value);
}

class Message extends Equatable {
  final String id;
  final String timestamp;
  final String content;
  final MessageRole role;

  const Message({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.role,
  });

  @override
  List<Object?> get props => [id, timestamp, content, role];
}
