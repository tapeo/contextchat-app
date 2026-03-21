import 'dart:convert';
import 'dart:io';

import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:path/path.dart';

import 'database_filesystem.dart';

class ChatDatabaseService {
  ChatDatabaseService(this._filesystem);

  static const _chatMessageStart = '<!-- CHAT_MESSAGE_START';
  static const _chatMessageEnd = '<!-- CHAT_MESSAGE_END -->';

  final DatabaseFilesystem _filesystem;

  File getChatFile(String chatId) => _filesystem.chatFile(chatId);

  Future<List<Chat>> getAllChats() async {
    final chats = <Chat>[];
    if (!await _filesystem.chatsDirectory.exists()) {
      return chats;
    }

    final files = await _filesystem.chatsDirectory
        .list()
        .where(
          (entity) =>
              entity is File && extension(entity.path).toLowerCase() == '.md',
        )
        .cast<File>()
        .toList();
    files.sort(
      (left, right) => basename(left.path).compareTo(basename(right.path)),
    );

    for (final file in files) {
      final chat = await _readChat(file);
      if (chat != null) {
        chats.add(chat);
      }
    }

    chats.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime(1970);
      final bTime = b.updatedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return chats;
  }

  Future<void> saveChat(Chat chat) async {
    final file = _filesystem.chatFile(chat.id);
    final existingMetadata = await _readChatMetadata(file);
    final createdAt =
        (existingMetadata['createdAt'] as String?) ??
        _inferCreatedAt(chat).toIso8601String();
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    final title = chat.title ?? _deriveChatTitle(chat);

    await _filesystem.writeStringAtomic(
      file,
      _encodeChatMarkdown(
        chat,
        createdAt: createdAt,
        updatedAt: updatedAt,
        title: title,
      ),
    );
  }

  Future<void> deleteChat(String id) async {
    final file = _filesystem.chatFile(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteChatsForProject(String projectId) async {
    if (!await _filesystem.chatsDirectory.exists()) {
      return;
    }

    final files = await _filesystem.chatsDirectory
        .list()
        .where(
          (entity) =>
              entity is File && extension(entity.path).toLowerCase() == '.md',
        )
        .cast<File>()
        .toList();

    for (final file in files) {
      final metadata = await _readChatMetadata(file);
      if (metadata['projectId'] == projectId && await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<Chat?> _readChat(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final contents = await file.readAsString();
    final frontmatter = _parseFrontmatter(contents);
    final messagePattern = RegExp(
      '${RegExp.escape(_chatMessageStart)} (.+?) -->\\s*\\n([\\s\\S]*?)\\n${RegExp.escape(_chatMessageEnd)}',
      multiLine: true,
    );
    final matches = messagePattern.allMatches(contents);
    final messages = <Message>[];

    for (final match in matches) {
      final metadata = json.decode(match.group(1)!);
      if (metadata is! Map<String, dynamic>) {
        throw const FormatException('Invalid chat message metadata');
      }

      messages.add(
        Message(
          id: metadata['id'] as String,
          timestamp: metadata['timestamp'] as String,
          content: match.group(2) ?? '',
          role: MessageRole.values.firstWhere(
            (role) => role.value == metadata['role'],
          ),
          toolCallId: metadata['toolCallId'] as String?,
          toolName: metadata['toolName'] as String?,
          toolCallsJson: metadata['toolCallsJson'] as String?,
          toolError: (metadata['toolError'] as bool?) ?? false,
          toolCallsProcessed:
              (metadata['toolCallsProcessed'] as bool?) ?? false,
          images: metadata['images'] != null
              ? (metadata['images'] as List)
                    .map(
                      (image) => AssistantImage.fromJson(
                        Map<String, dynamic>.from(image as Map),
                      ),
                    )
                    .toList()
              : null,
        ),
      );
    }

    return Chat(
      id: (frontmatter['id'] as String?) ?? basenameWithoutExtension(file.path),
      projectId: frontmatter['projectId'] as String?,
      title: frontmatter['title'] as String?,
      messages: messages,
      updatedAt: frontmatter['updatedAt'] != null
          ? DateTime.tryParse(frontmatter['updatedAt'] as String)
          : null,
    );
  }

  Future<Map<String, dynamic>> _readChatMetadata(File file) async {
    if (!await file.exists()) {
      return {};
    }

    return _parseFrontmatter(await file.readAsString());
  }

  String _encodeChatMarkdown(
    Chat chat, {
    required String createdAt,
    required String updatedAt,
    required String title,
  }) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${json.encode(chat.id)}')
      ..writeln('projectId: ${json.encode(chat.projectId)}')
      ..writeln('createdAt: ${json.encode(createdAt)}')
      ..writeln('updatedAt: ${json.encode(updatedAt)}')
      ..writeln('title: ${json.encode(title)}')
      ..writeln('---')
      ..writeln('# Chat Transcript');

    for (final message in chat.messages) {
      buffer
        ..writeln()
        ..writeln(
          '$_chatMessageStart ${json.encode({'id': message.id, 'role': message.role.value, 'timestamp': message.timestamp, 'toolCallId': message.toolCallId, 'toolName': message.toolName, 'toolCallsJson': message.toolCallsJson, 'toolError': message.toolError, 'toolCallsProcessed': message.toolCallsProcessed, 'images': message.images?.map((i) => i.toJson()).toList()})} -->',
        )
        ..writeln(message.content)
        ..writeln(_chatMessageEnd);
    }

    return '${buffer.toString().trimRight()}\n';
  }

  Map<String, dynamic> _parseFrontmatter(String contents) {
    if (!contents.startsWith('---\n')) {
      return {};
    }

    final closingIndex = contents.indexOf('\n---\n', 4);
    if (closingIndex == -1) {
      return {};
    }

    final frontmatter = contents.substring(4, closingIndex);
    final metadata = <String, dynamic>{};

    for (final line in frontmatter.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }

      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      final rawValue = line.substring(separatorIndex + 1).trim();
      metadata[key] = rawValue.isEmpty ? null : json.decode(rawValue);
    }

    return metadata;
  }

  DateTime _inferCreatedAt(Chat chat) {
    if (chat.messages.isEmpty) {
      return DateTime.now().toUtc();
    }

    return DateTime.tryParse(chat.messages.first.timestamp)?.toUtc() ??
        DateTime.now().toUtc();
  }

  String _deriveChatTitle(Chat chat) {
    for (final message in chat.messages) {
      if (message.role != MessageRole.user) {
        continue;
      }

      final normalized = message.content.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (normalized.isEmpty) {
        continue;
      }

      return normalized.length > 80
          ? '${normalized.substring(0, 77)}...'
          : normalized;
    }

    return 'Chat ${chat.id}';
  }
}
