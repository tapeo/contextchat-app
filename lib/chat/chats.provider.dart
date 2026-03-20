import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/chat/chats.state.dart';
import 'package:contextchat/database/chat_database.service.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _selectedChatIdKey = 'selected_chat_id';

final chatsProvider = NotifierProvider<ChatsNotifier, ChatsState>(
  () => ChatsNotifier(),
);

class ChatsNotifier extends Notifier<ChatsState> {
  ChatDatabaseService get databaseService => ref.watch(chatDatabaseProvider);

  FileStorage get _fileStorage => ref.watch(fileStorageProvider);

  @override
  ChatsState build() {
    return ChatsState(chats: []);
  }

  Future<void> initialize() async {
    final chats = await databaseService.getAllChats();
    final savedChatId = _fileStorage.getString(_selectedChatIdKey);

    String? selectedChatId;

    if (savedChatId != null && chats.any((c) => c.id == savedChatId)) {
      selectedChatId = savedChatId;
    } else if (chats.isNotEmpty) {
      selectedChatId = chats.first.id;
    }

    state = ChatsState(
      chats: chats,
      selectedChatId: selectedChatId,
      loading: false,
    );
  }

  Future<String> createChat(String? projectId) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final chat = Chat(id: id, projectId: projectId, messages: []);
    state = state.copyWith(chats: [...state.chats, chat]);
    await databaseService.saveChat(chat);
    return id;
  }

  Future<void> deleteChat(String id) async {
    state = state.copyWith(
      chats: state.chats.where((p) => p.id != id).toList(),
      selectedChatId: state.selectedChatId == id ? null : state.selectedChatId,
    );
    await databaseService.deleteChat(id);
  }

  Future<void> deleteChatsForProject(String projectId) async {
    final chatIds = state.chats
        .where((chat) => chat.projectId == projectId)
        .map((chat) => chat.id)
        .toList();

    state = state.copyWith(
      chats: state.chats.where((chat) => chat.projectId != projectId).toList(),
      selectedChatId: chatIds.contains(state.selectedChatId)
          ? null
          : state.selectedChatId,
    );

    for (final chatId in chatIds) {
      await databaseService.deleteChat(chatId);
    }
  }

  void selectChat(String id) {
    state = state.copyWith(selectedChatId: id);
    _fileStorage.setString(_selectedChatIdKey, id);
  }

  void updateChat(Chat updatedChat) {
    state = state.copyWith(
      chats: state.chats.map((chat) {
        return chat.id == updatedChat.id ? updatedChat : chat;
      }).toList(),
    );
  }
}
