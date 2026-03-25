import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'models/sync_manifest.dart';

class SyncRepository {
  final String basePath;

  SyncRepository({required this.basePath});

  Future<void> writeFile(String relativePath, Uint8List content) async {
    final baseDir = Directory(basePath);
    final file = File('${baseDir.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);
  }

  Future<Uint8List?> readFile(String relativePath) async {
    final baseDir = Directory(basePath);
    final file = File('${baseDir.path}/$relativePath');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> deleteFile(String relativePath) async {
    final baseDir = Directory(basePath);
    final file = File('${baseDir.path}/$relativePath');
    if (await file.exists()) {
      await file.delete();

      // Clean up empty parent directories
      var dir = file.parent;
      while (dir.path != baseDir.path) {
        if (await dir.exists()) {
          final isEmpty = await dir.list().isEmpty;
          if (isEmpty) {
            await dir.delete();
          } else {
            break;
          }
        }
        dir = dir.parent;
      }
    }
  }

  Future<FileStat?> getFileStat(String relativePath) async {
    final baseDir = Directory(basePath);
    final file = File('${baseDir.path}/$relativePath');
    if (await file.exists()) {
      return await file.stat();
    }
    return null;
  }

  String computeSha256(Uint8List content) {
    final digest = sha256.convert(content);
    return digest.toString();
  }

  /// Build a manifest of all local files
  Future<List<SyncFileEntry>> buildManifest() async {
    final entries = <SyncFileEntry>[];
    final baseDir = Directory(basePath);

    if (!await baseDir.exists()) return entries;

    await for (final entity in baseDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(baseDir.path.length + 1);

        // Skip local-only files (hidden files and directories)
        if (relativePath.startsWith('.')) {
          continue;
        }
        if (relativePath.contains('/.')) {
          continue; // Skip files in hidden directories
        }

        final stat = await entity.stat();
        final content = await entity.readAsBytes();
        final sha256 = computeSha256(content);

        entries.add(
          SyncFileEntry(
            path: relativePath,
            sha256: sha256,
            sizeBytes: content.length,
            modifiedAt: stat.modified,
          ),
        );
      }
    }

    return entries;
  }
}
