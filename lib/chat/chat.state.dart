import 'package:contextchat/chat/chat.model.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final Chat chat;
  final bool loading;
  final String? accumulatedResponse;
  final String? selectedModelId;

  const ChatState({
    required this.chat,
    required this.loading,
    this.accumulatedResponse,
    this.selectedModelId,
  });

  ChatState copyWith({
    Chat? chat,
    bool? loading,
    Nullable<String?>? accumulatedResponse,
    String? selectedModelId,
  }) {
    return ChatState(
      chat: chat ?? this.chat,
      loading: loading ?? this.loading,
      accumulatedResponse: accumulatedResponse != null
          ? accumulatedResponse.value
          : this.accumulatedResponse,
      selectedModelId: selectedModelId ?? this.selectedModelId,
    );
  }

  @override
  List<Object?> get props => [
    chat,
    loading,
    accumulatedResponse,
    selectedModelId,
  ];
}

class Nullable<T> {
  final T? value;

  const Nullable(this.value);
}
