import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/chat/chat.state.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/database/chat_database.service.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter.state.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:contextchat/openrouter/tooling.dart';
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
      toolsEnabled: effectiveChat.toolsEnabled,
      imageOutputEnabled: effectiveChat.imageOutputEnabled,
      imageModalities: effectiveChat.imageModalities,
      imageAspectRatio: effectiveChat.imageAspectRatio,
      imageSize: effectiveChat.imageSize,
    );
  }

  Future<void> _saveChat() async {
    await chatsDatabase.saveChat(state.chat);
  }

  Future<void> sendMessage(
    String text, {
    OpenRouterImageGenerationOptions? imageGeneration,
  }) async {
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

      if (imageGeneration != null &&
          selectedModel != null &&
          !selectedModel.supportsImageOutput) {
        throw Exception(
          'The selected model does not support image output. Choose an image-capable model.',
        );
      }

      final settings = ref.read(openRouterProvider);
      final initialMessages = _buildOpenRouterMessages(
        sourceMessages: state.chat.messages,
        projectContext: projectContext,
        currentUserMessageId: message.id,
      );

      Chat updatedChat;

      if (state.toolsEnabled) {
        final registry = buildGlobalToolRegistry(
          project: project,
          projectsDatabase: projectsDatabase,
        );
        updatedChat = await _sendMessageWithTools(
          initialMessages: initialMessages,
          registry: registry,
          modelId: state.selectedModelId,
          settings: settings,
          imageGeneration: imageGeneration,
        );
      } else {
        updatedChat = await _sendMessageStreaming(
          initialMessages: initialMessages,
          modelId: state.selectedModelId,
          imageGeneration: imageGeneration,
        );
      }

      if (updatedChat.title == null && currentMessages.isEmpty) {
        try {
          final title = await openRouter.sendNonStreaming(
            messages: [
              OpenRouterMessage(
                role: 'system',
                content:
                    'Generate a short, concise chat title (3-5 words max) based on the user message. Return only the title, no quotes or extra text.',
              ),
              OpenRouterMessage(role: 'user', content: text),
            ],
            modelId: state.selectedModelId,
          );
          updatedChat = updatedChat.copyWith(
            title: title.replaceAll('"', '').replaceAll("'", ''),
          );
        } catch (e) {
          // If title generation fails, we'll just use the default title
        }
      }

      state = state.copyWith(
        chat: updatedChat,
        accumulatedResponse: const Nullable(null),
        loading: false,
      );

      await _saveChat();

      ref.read(chatsProvider.notifier).updateChat(updatedChat);
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

  Future<void> setImageOutputEnabled(bool enabled) async {
    state = state.copyWith(
      imageOutputEnabled: enabled,
      chat: state.chat.copyWith(imageOutputEnabled: enabled),
    );
    await _saveChat();
  }

  Future<void> setImageModalities(ImageModalities modalities) async {
    state = state.copyWith(
      imageModalities: modalities,
      chat: state.chat.copyWith(imageModalities: modalities),
    );
    await _saveChat();
  }

  Future<void> setImageAspectRatio(ImageAspectRatio aspectRatio) async {
    state = state.copyWith(
      imageAspectRatio: aspectRatio,
      chat: state.chat.copyWith(imageAspectRatio: aspectRatio),
    );
    await _saveChat();
  }

  Future<void> setImageSize(ImageSize imageSize) async {
    state = state.copyWith(
      imageSize: imageSize,
      chat: state.chat.copyWith(imageSize: imageSize),
    );
    await _saveChat();
  }

  Future<void> setToolsEnabled(bool enabled) async {
    state = state.copyWith(
      toolsEnabled: enabled,
      chat: state.chat.copyWith(toolsEnabled: enabled),
    );
    await _saveChat();
  }

  List<OpenRouterMessage> _buildOpenRouterMessages({
    required List<Message> sourceMessages,
    required _ProjectContextPayload projectContext,
    required String currentUserMessageId,
  }) {
    final openRouterMessages = sourceMessages.map((msg) {
      final isCurrentUserMessage =
          msg.id == currentUserMessageId &&
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

      if (msg.role == MessageRole.assistant && msg.toolCallsJson != null) {
        return OpenRouterMessage(
          role: msg.role.value,
          content: msg.content.isEmpty ? null : msg.content,
          toolCalls: _decodeToolCalls(msg.toolCallsJson!),
        );
      }

      if (msg.role == MessageRole.tool) {
        return OpenRouterMessage(
          role: msg.role.value,
          content: msg.content,
          toolCallId: msg.toolCallId,
          name: msg.toolName,
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

    return openRouterMessages;
  }

  Future<Chat> _sendMessageStreaming({
    required List<OpenRouterMessage> initialMessages,
    required String? modelId,
    OpenRouterImageGenerationOptions? imageGeneration,
  }) async {
    final stream = openRouter.send(
      messages: initialMessages,
      modelId: modelId,
      modalities: imageGeneration?.modalities,
      imageConfig: imageGeneration?.imageConfig,
    );

    String accumulatedResponse = '';
    final accumulatedImages = <AssistantImage>[];

    await for (final chunk in stream) {
      if (chunk.content != null) {
        accumulatedResponse += chunk.content!;
        state = state.copyWith(
          accumulatedResponse: Nullable(accumulatedResponse),
        );
      }
      if (chunk.imageDeltas != null && chunk.imageDeltas!.isNotEmpty) {
        accumulatedImages.addAll(chunk.imageDeltas!);
      }
    }

    final finalMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: accumulatedResponse,
      timestamp: DateTime.now().toString(),
      role: MessageRole.assistant,
      images: accumulatedImages.isNotEmpty ? accumulatedImages : null,
      model: modelId,
    );

    return state.chat.copyWith(
      messages: [...state.chat.messages, finalMessage],
    );
  }

  Future<Chat> _sendMessageWithTools({
    required List<OpenRouterMessage> initialMessages,
    required OpenRouterToolRegistry registry,
    required String? modelId,
    required OpenRouterState settings,
    OpenRouterImageGenerationOptions? imageGeneration,
  }) async {
    final completion = await openRouter.sendCompletionNonStreaming(
      messages: initialMessages,
      modelId: modelId,
      tools: registry.definitions,
      toolChoice: const OpenRouterToolChoice.auto(),
      parallelToolCalls: false,
      modalities: imageGeneration?.modalities,
      imageConfig: imageGeneration?.imageConfig,
    );

    final choice = completion.choices.firstOrNull;
    if (choice == null) {
      throw Exception('OpenRouter returned no choices');
    }

    final assistantMessage = choice.message;
    final toolCalls = assistantMessage.toolCalls ?? const [];
    final hasToolCalls =
        toolCalls.isNotEmpty || choice.finishReason == 'tool_calls';

    if (!hasToolCalls) {
      final content = assistantMessage.content?.trim() ?? '';
      final finalMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        timestamp: DateTime.now().toString(),
        role: MessageRole.assistant,
        images: assistantMessage.images,
        model: completion.model,
      );
      _appendLocalMessage(finalMessage);
      return state.chat;
    }

    final toolCallRecord = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: assistantMessage.content ?? '',
      timestamp: DateTime.now().toString(),
      role: MessageRole.assistant,
      toolCallsJson: jsonEncode(
        toolCalls.map((tool) => tool.toJson()).toList(),
      ),
      images: assistantMessage.images,
      model: completion.model,
    );
    _appendLocalMessage(toolCallRecord);
    return state.chat;
  }

  Future<void> approveToolCallsAndContinue(String assistantMessageId) async {
    await _resolveToolCallsAndContinue(
      assistantMessageId: assistantMessageId,
      approved: true,
    );
  }

  Future<void> denyToolCallsAndContinue(String assistantMessageId) async {
    await _resolveToolCallsAndContinue(
      assistantMessageId: assistantMessageId,
      approved: false,
    );
  }

  Future<void> _resolveToolCallsAndContinue({
    required String assistantMessageId,
    required bool approved,
  }) async {
    state = state.copyWith(loading: true);

    try {
      final assistantMessage = state.chat.messages.firstWhereOrNull(
        (message) =>
            message.id == assistantMessageId && message.toolCallsJson != null,
      );
      if (assistantMessage == null) {
        throw Exception('Tool call request not found');
      }

      final processedMessage = assistantMessage.copyWith(
        toolCallsProcessed: true,
      );
      final updatedMessages = state.chat.messages.map((m) {
        return m.id == assistantMessageId ? processedMessage : m;
      }).toList();
      state = state.copyWith(
        chat: state.chat.copyWith(messages: updatedMessages),
      );

      final toolCalls = _decodeToolCalls(assistantMessage.toolCallsJson!);
      if (toolCalls.isEmpty) {
        throw Exception('No tool calls found in request');
      }

      final project = ref
          .read(projectsProvider)
          .projects
          .firstWhereOrNull((item) => item.id == state.chat.projectId);
      final projectContext = project == null
          ? const _ProjectContextPayload.empty()
          : await _buildProjectContext(project);
      final registry = buildGlobalToolRegistry(
        project: project,
        projectsDatabase: projectsDatabase,
      );

      for (final toolCall in toolCalls) {
        final alreadyResolved = state.chat.messages.any(
          (message) =>
              message.role == MessageRole.tool &&
              message.toolCallId == toolCall.id,
        );
        if (alreadyResolved) {
          continue;
        }

        final toolName = toolCall.function.name;
        OpenRouterToolExecutionResult result;

        if (!approved) {
          result = OpenRouterToolExecutionResult(
            content: jsonEncode({'error': 'Tool call denied by user'}),
            isError: true,
          );
        } else {
          final resolvedTool = registry[toolName];
          if (resolvedTool == null) {
            result = OpenRouterToolExecutionResult(
              content: jsonEncode({'error': 'Unknown tool: $toolName'}),
              isError: true,
            );
          } else {
            try {
              final rawArgs = jsonDecode(toolCall.function.arguments);
              final args = rawArgs is Map<String, dynamic>
                  ? rawArgs
                  : rawArgs is Map
                  ? Map<String, dynamic>.from(rawArgs)
                  : <String, dynamic>{};
              result = await resolvedTool.execute(args);
            } catch (error) {
              result = OpenRouterToolExecutionResult(
                content: jsonEncode({'error': 'Tool execution failed: $error'}),
                isError: true,
              );
            }
          }
        }

        final toolResultMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: result.content,
          timestamp: DateTime.now().toString(),
          role: MessageRole.tool,
          toolCallId: toolCall.id,
          toolName: toolName,
          toolError: result.isError,
        );
        _appendLocalMessage(toolResultMessage);
      }

      final completionMessages = _buildOpenRouterMessages(
        sourceMessages: state.chat.messages,
        projectContext: projectContext,
        currentUserMessageId: '',
      );

      final updatedChat = await _sendMessageWithTools(
        initialMessages: completionMessages,
        registry: registry,
        modelId: state.selectedModelId,
        settings: ref.read(openRouterProvider),
      );

      state = state.copyWith(chat: updatedChat, loading: false);
      await _saveChat();
      ref.read(chatsProvider.notifier).updateChat(updatedChat);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  List<OpenRouterToolCall> _decodeToolCalls(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) =>
                OpenRouterToolCall.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _appendLocalMessage(Message message) {
    state = state.copyWith(
      chat: state.chat.copyWith(messages: [...state.chat.messages, message]),
    );
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
