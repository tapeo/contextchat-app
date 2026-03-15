import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatDraftProvider =
    NotifierProvider.family<ChatDraftNotifier, String, String>(
      (chatId) => ChatDraftNotifier(chatId),
    );

class ChatDraftNotifier extends Notifier<String> {
  ChatDraftNotifier(this.chatId);

  final String chatId;

  @override
  String build() => '';

  void setDraft(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }

  void insert(String text, {bool replace = true}) {
    if (replace) {
      state = text;
      return;
    }
    if (state.trim().isEmpty) {
      state = text;
      return;
    }
    state = '${state.trimRight()}\n\n$text';
  }
}

