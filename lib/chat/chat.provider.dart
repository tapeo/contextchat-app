import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/chat/chat.state.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/chat/message.model.dart';
import 'package:contextchat/database/chat_database.service.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:contextchat/projects/project_file_types.dart';
import 'package:contextchat/projects/projects.model.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, String>(
  (chatId) => ChatNotifier(chatId),
);

class ChatNotifier extends Notifier<ChatState> {
  final String chatId;

  ChatNotifier(this.chatId);

  OpenRouterNotifier get openRouter => ref.watch(openRouterProvider.notifier);
  ChatDatabaseService get chatsDatabase => ref.watch(chatDatabaseProvider);
  ProjectDatabaseService get projectsDatabase =>
      ref.watch(projectDatabaseProvider);

  @override
  ChatState build() {
    final chat = ref
        .watch(chatsProvider)
        .chats
        .firstWhereOrNull((c) => c.id == chatId);

    final effectiveChat = chat ?? Chat(id: 'default', messages: []);

    String? initialModelId;
    if (effectiveChat.projectId != null) {
      final projects = ref.watch(
        projectsProvider.select((state) => state.projects),
      );
      final project = projects.firstWhereOrNull(
        (p) => p.id == effectiveChat.projectId,
      );
      initialModelId = project?.defaultModelId;
    }

    return ChatState(
      chat: effectiveChat,
      loading: false,
      selectedModelId: initialModelId,
    );
  }

  Future<void> _saveChat() async {
    await chatsDatabase.saveChat(state.chat);
  }

  Future<void> sendMessage(String text) async {
    try {
      List<Message> currentMessages = List.from(state.chat.messages);

      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        timestamp: DateTime.now().toString(),
        role: MessageRole.user,
      );

      state = state.copyWith(
        chat: state.chat.copyWith(messages: [...currentMessages, message]),
        loading: true,
      );

      final project = ref
          .read(projectsProvider)
          .projects
          .firstWhereOrNull((item) => item.id == state.chat.projectId);

      final projectContext = project == null
          ? const _ProjectContextPayload.empty()
          : await _buildProjectContext(project);

      final effectiveModelId =
          state.selectedModelId ?? ref.read(openRouterProvider).modelId;
      final selectedModel = ref
          .read(openRouterModelsProvider)
          .models
          .firstWhereOrNull((model) => model.id == effectiveModelId);

      if (projectContext.imageParts.isNotEmpty &&
          selectedModel != null &&
          !selectedModel.supportsImageInput) {
        throw Exception(
          'The selected model does not support image input. Choose a vision-capable model.',
        );
      }

      final openRouterMessages = state.chat.messages.map((msg) {
        final isCurrentUserMessage =
            msg.id == message.id &&
            msg.role == MessageRole.user &&
            projectContext.imageParts.isNotEmpty;

        if (isCurrentUserMessage) {
          return OpenRouterMessage.multipart(
            role: msg.role.value,
            contentParts: [
              OpenRouterMessageContentPart.text(msg.content),
              ...projectContext.imageParts,
            ],
          );
        }

        return OpenRouterMessage(role: msg.role.value, content: msg.content);
      }).toList();

      if (projectContext.systemContext.isNotEmpty) {
        openRouterMessages.insert(
          0,
          OpenRouterMessage(
            role: 'system',
            content: projectContext.systemContext,
          ),
        );
      }

      final stream = openRouter.send(
        messages: openRouterMessages,
        modelId: state.selectedModelId,
      );

      String accumulatedResponse = '';
      String? apiId;
      DateTime? apiCreated;

      await for (final chunk in stream) {
        if (apiId == null && chunk.id != null) {
          apiId = chunk.id;
        }
        if (apiCreated == null && chunk.created != null) {
          apiCreated = DateTime.fromMillisecondsSinceEpoch(
            chunk.created! * 1000,
          );
        }
        if (chunk.content != null) {
          accumulatedResponse += chunk.content!;
          state = state.copyWith(
            accumulatedResponse: Nullable(accumulatedResponse),
          );
        }
      }

      final finalMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: accumulatedResponse,
        timestamp: DateTime.now().toString(),
        role: MessageRole.assistant,
      );

      state = state.copyWith(
        chat: state.chat.copyWith(
          messages: [...state.chat.messages, finalMessage],
        ),
        accumulatedResponse: const Nullable(null),
        loading: false,
      );
      await _saveChat();
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  void selectModel(String id) {
    state = state.copyWith(selectedModelId: id);

    final projectId = state.chat.projectId;
    if (projectId != null && id.isNotEmpty) {
      ref.read(projectsProvider.notifier).setProjectDefaultModel(projectId, id);
    }
  }

  Future<_ProjectContextPayload> _buildProjectContext(Project project) async {
    final systemContext = StringBuffer();
    final baseContext = project.baseContext.trim();
    final imageParts = <OpenRouterMessageContentPart>[];

    if (baseContext.isNotEmpty) {
      systemContext.write(baseContext);
    }

    for (final file in project.files) {
      final mimeType = imageMimeTypeForFileName(file.filename);
      if (mimeType != null) {
        final bytes = await projectsDatabase.readProjectFileBytes(
          project.id,
          file,
        );
        if (bytes == null) {
          continue;
        }

        imageParts.add(
          OpenRouterMessageContentPart.imageUrl(
            'data:$mimeType;base64,${base64Encode(bytes)}',
          ),
        );
        continue;
      }

      final contents = await projectsDatabase.readProjectFileContents(
        project.id,
        file,
      );
      if (contents == null) {
        continue;
      }
      if (systemContext.isNotEmpty) {
        systemContext.write('\n\n');
      }
      systemContext
        ..writeln('File: ${file.name}')
        ..write(contents.trimRight());
    }

    return _ProjectContextPayload(
      systemContext: systemContext.toString(),
      imageParts: imageParts,
    );
  }
}

class _ProjectContextPayload {
  const _ProjectContextPayload({
    required this.systemContext,
    required this.imageParts,
  });

  const _ProjectContextPayload.empty()
    : systemContext = '',
      imageParts = const [];

  final String systemContext;
  final List<OpenRouterMessageContentPart> imageParts;
}
