import 'dart:convert';

import '../file_storage/file_storage.provider.dart';
import 'models/sync_manifest.dart';

class SyncManifestManager {
  static const _syncManifestKey = 'sync_manifest';

  final FileStorage _fileStorage;

  SyncManifestManager({required FileStorage fileStorage})
    : _fileStorage = fileStorage;

  SyncManifest? loadManifest() {
    final manifestJson = _fileStorage.getString(_syncManifestKey);
    if (manifestJson == null) return null;
    try {
      return SyncManifest.fromJson(
        jsonDecode(manifestJson) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveManifest(SyncManifest manifest) async {
    await _fileStorage.setString(
      _syncManifestKey,
      jsonEncode(manifest.toJson()),
    );
  }

  Map<String, SyncFileEntry> buildManifestIndex(SyncManifest manifest) {
    return {for (var entry in manifest.files) entry.path: entry};
  }
}
