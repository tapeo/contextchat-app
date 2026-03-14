import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/projects/projects.model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_database.service.dart';
import 'database_filesystem.dart';
import 'project_database.service.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseProvider');
});

final projectDatabaseProvider = Provider<ProjectDatabaseService>((ref) {
  return ref.watch(databaseProvider).projects;
});

final chatDatabaseProvider = Provider<ChatDatabaseService>((ref) {
  return ref.watch(databaseProvider).chats;
});

class DatabaseService {
  DatabaseService({DatabaseFilesystem? filesystem})
    : _filesystem = filesystem ?? DatabaseFilesystem() {
    projects = ProjectDatabaseService(_filesystem);
    chats = ChatDatabaseService(_filesystem);
  }

  final DatabaseFilesystem _filesystem;
  late final ProjectDatabaseService projects;
  late final ChatDatabaseService chats;

  String get memoryPath => _filesystem.memoryPath;

  Future<void> initialize(Directory directory) async {
    await _filesystem.initialize(directory);
  }

  Future<bool> clear() async {
    await _filesystem.reset();
    return true;
  }

  Future<bool> remove(String key) async {
    throw UnsupportedError(
      'Arbitrary key removal is not supported by file storage',
    );
  }

  Future<List<int>> exportBytes() async {
    final data = <String, dynamic>{
      'projects': (await projects.getAllProjects())
          .map((project) => project.toJson())
          .toList(),
      'chats': (await chats.getAllChats())
          .map((chat) => chat.toJson())
          .toList(),
    };
    return utf8.encode(json.encode(data));
  }

  Future<void> importBytes(List<int> bytes, {DateTime? remoteTimestamp}) async {
    if (bytes.isEmpty) {
      await _clearAll();
      return;
    }
    final contents = utf8.decode(bytes);
    if (contents.trim().isEmpty) {
      await _clearAll();
      return;
    }
    final decoded = json.decode(contents);
    if (decoded is Map<String, dynamic>) {
      await _clearAll();

      if (decoded['projects'] is List) {
        for (final projectJson in decoded['projects'] as List<dynamic>) {
          final project = Project.fromJson(
            Map<String, dynamic>.from(projectJson as Map<dynamic, dynamic>),
          );
          await projects.saveProject(project);
        }
      }

      if (decoded['chats'] is List) {
        for (final chatJson in decoded['chats'] as List<dynamic>) {
          final chat = Chat.fromJson(
            Map<String, dynamic>.from(chatJson as Map<dynamic, dynamic>),
          );
          await chats.saveChat(chat);
        }
      }
    } else {
      throw const FormatException('Invalid database format');
    }
  }

  Future<void> _clearAll() async {
    await _filesystem.clearEntityDirectories();
  }
}
