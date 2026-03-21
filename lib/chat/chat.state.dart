import 'package:contextchat/chat/chat.model.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final Chat chat;
  final bool loading;
  final String? accumulatedResponse;

  const ChatState({
    required this.chat,
    required this.loading,
    this.accumulatedResponse,
  });

  ChatState copyWith({
    Chat? chat,
    bool? loading,
    Nullable<String?>? accumulatedResponse,
  }) {
    return ChatState(
      chat: chat ?? this.chat,
      loading: loading ?? this.loading,
      accumulatedResponse: accumulatedResponse != null
          ? accumulatedResponse.value
          : this.accumulatedResponse,
    );
  }

  @override
  List<Object?> get props => [chat, loading, accumulatedResponse];
}

class Nullable<T> {
  final T? value;

  const Nullable(this.value);
}
