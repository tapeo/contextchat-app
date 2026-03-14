import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileStorageProvider = Provider<FileStorage>((ref) {
  throw UnimplementedError('fileStorageProvider');
});

class FileStorage {
  late File _file;
  late Directory _directory;

  Map<String, dynamic> _data = {};

  final Queue<Completer<void>> _writeQueue = Queue<Completer<void>>();
  bool _isProcessingQueue = false;

  Future<void> initialize(Directory directory) async {
    _directory = directory;
    _file = File('${directory.path}/shared_preferences.json');

    await _directory.create(recursive: true);
    await _cleanupTempFiles();

    await _loadData();
  }

  Future<void> _cleanupTempFiles() async {
    final tempFile = File('${_directory.path}/shared_preferences.json.tmp');
    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }
  }

  Future<void> _loadData() async {
    if (await _file.exists()) {
      final contents = await _file.readAsString();
      if (contents.isNotEmpty) {
        _data = json.decode(contents) as Map<String, dynamic>;
        return;
      }
    }
  }

  Future<void> _saveData() async {
    final completer = Completer<void>();
    _writeQueue.add(completer);

    if (!_isProcessingQueue) {
      _processWriteQueue();
    }

    return completer.future;
  }

  Future<void> _processWriteQueue() async {
    if (_isProcessingQueue) return;

    _isProcessingQueue = true;

    try {
      while (_writeQueue.isNotEmpty) {
        final completer = _writeQueue.removeFirst();

        try {
          await _performWrite();
          completer.complete();
        } catch (error) {
          completer.completeError(error);
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _performWrite() async {
    final jsonString = json.encode(_data);

    await _directory.create(recursive: true);

    final tempFile = File('${_directory.path}/shared_preferences.json.tmp');
    final backupFile = File(
      '${_directory.path}/shared_preferences.json.backup',
    );

    if (await _file.exists()) {
      await _file.copy(backupFile.path);
    }

    await tempFile.writeAsString(jsonString);

    final writtenContent = await tempFile.readAsString();
    json.decode(writtenContent);

    await tempFile.rename(_file.path);
  }

  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    await _saveData();
    return true;
  }

  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    await _saveData();
    return true;
  }

  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    await _saveData();
    return true;
  }

  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    await _saveData();
    return true;
  }

  int? getInt(String key) {
    final value = _data[key];
    return value is int ? value : null;
  }

  bool? getBool(String key) {
    final value = _data[key];
    return value is bool ? value : null;
  }

  double? getDouble(String key) {
    final value = _data[key];
    return value is double ? value : null;
  }

  String? getString(String key) {
    final value = _data[key];
    return value is String ? value : null;
  }

  Future<bool> clear() async {
    _data.clear();
    await _saveData();
    return true;
  }

  Future<bool> remove(String key) async {
    _data.remove(key);
    await _saveData();
    return true;
  }

  Future<List<int>> exportBytes() async {
    await _saveData();

    if (await _file.exists()) {
      return _file.readAsBytes();
    }

    final jsonString = json.encode(_data);
    return utf8.encode(jsonString);
  }

  Future<void> importBytes(List<int> bytes, {DateTime? remoteTimestamp}) async {
    if (bytes.isEmpty) {
      _data = {};
    } else {
      final contents = utf8.decode(bytes);

      if (contents.trim().isEmpty) {
        _data = {};
      } else {
        final decoded = json.decode(contents);
        if (decoded is Map<String, dynamic>) {
          _data = decoded;
        } else if (decoded is Map) {
          _data = decoded.map((key, value) => MapEntry(key.toString(), value));
        } else {
          throw const FormatException('Invalid preferences format');
        }
      }
    }

    await _saveData();
  }
}
