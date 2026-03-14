import 'package:app/chat/chat.model.dart';
import 'package:equatable/equatable.dart';

const _selectedChatIdUnset = Object();

class ChatsState extends Equatable {
  final List<Chat> chats;
  final String? selectedChatId;
  final bool loading;

  const ChatsState({
    required this.chats,
    this.selectedChatId,
    this.loading = true,
  });

  ChatsState copyWith({
    List<Chat>? chats,
    Object? selectedChatId = _selectedChatIdUnset,
    bool? loading,
  }) {
    return ChatsState(
      chats: chats ?? this.chats,
      selectedChatId: identical(selectedChatId, _selectedChatIdUnset)
          ? this.selectedChatId
          : selectedChatId as String?,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [chats, selectedChatId, loading];
}
