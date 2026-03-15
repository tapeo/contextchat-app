import 'dart:convert';
import 'dart:io';

import 'package:contextchat/prompts/prompt.model.dart';
import 'package:path/path.dart';

import 'database_filesystem.dart';

class PromptDatabaseService {
  PromptDatabaseService(this._filesystem);

  final DatabaseFilesystem _filesystem;

  Future<List<Prompt>> getAllPrompts() async {
    final prompts = <Prompt>[];
    if (!await _filesystem.promptsDirectory.exists()) {
      return prompts;
    }

    final files = await _filesystem.promptsDirectory
        .list()
        .where(
          (entity) =>
              entity is File && extension(entity.path).toLowerCase() == '.json',
        )
        .cast<File>()
        .toList();
    files.sort(
      (left, right) => basename(left.path).compareTo(basename(right.path)),
    );

    for (final file in files) {
      final prompt = await _readPrompt(file);
      if (prompt != null) {
        prompts.add(prompt);
      }
    }

    return prompts;
  }

  Future<void> savePrompt(Prompt prompt) async {
    final file = _filesystem.promptFile(prompt.id);
    await _filesystem.writeJsonAtomic(file, prompt.toJson());
  }

  Future<void> deletePrompt(String id) async {
    final file = _filesystem.promptFile(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Prompt?> _readPrompt(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final decoded = json.decode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid prompt format');
    }

    return Prompt.fromJson(decoded);
  }
}

