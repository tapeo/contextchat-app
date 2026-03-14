import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

class DatabaseFilesystem {
  late Directory _memoryDirectory;
  late Directory _projectsDirectory;
  late Directory _chatsDirectory;

  String get memoryPath => _memoryDirectory.path;
  Directory get projectsDirectory => _projectsDirectory;
  Directory get chatsDirectory => _chatsDirectory;

  Future<void> initialize(Directory directory) async {
    _memoryDirectory = Directory(join(directory.path, 'memory'));
    _projectsDirectory = Directory(join(_memoryDirectory.path, 'projects'));
    _chatsDirectory = Directory(join(_memoryDirectory.path, 'chats'));

    await _memoryDirectory.create(recursive: true);
    await _projectsDirectory.create(recursive: true);
    await _chatsDirectory.create(recursive: true);
  }

  Future<void> reset() async {
    if (await _memoryDirectory.exists()) {
      await _memoryDirectory.delete(recursive: true);
    }
    await initialize(_memoryDirectory.parent);
  }

  Future<void> clearEntityDirectories() async {
    if (await _projectsDirectory.exists()) {
      await _projectsDirectory.delete(recursive: true);
    }
    if (await _chatsDirectory.exists()) {
      await _chatsDirectory.delete(recursive: true);
    }

    await _projectsDirectory.create(recursive: true);
    await _chatsDirectory.create(recursive: true);
  }

  Directory projectDirectory(String projectId) {
    return Directory(join(_projectsDirectory.path, projectId));
  }

  Directory projectContextDirectory(String projectId) {
    return Directory(join(_projectsDirectory.path, projectId, 'context'));
  }

  File projectMetadataFile(String projectId) {
    return File(join(projectDirectory(projectId).path, 'project.json'));
  }

  File projectMemoryFile(String projectId) {
    return File(join(projectDirectory(projectId).path, 'MEMORY.md'));
  }

  File chatFile(String chatId) {
    return File(join(_chatsDirectory.path, '$chatId.md'));
  }

  Future<void> writeJsonAtomic(File file, Map<String, dynamic> data) async {
    await writeStringAtomic(
      file,
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
    );
  }

  Future<void> writeStringAtomic(File file, String contents) async {
    await file.parent.create(recursive: true);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(contents);
    await tempFile.rename(file.path);
  }
}
