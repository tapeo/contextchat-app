import 'dart:convert';

import '../file_storage/file_storage.provider.dart';
import 'models/github_sync_manifest.dart';

class GithubSyncManifestManager {
  static const _syncManifestKey = 'sync_manifest';

  final FileStorage _fileStorage;

  GithubSyncManifestManager({required FileStorage fileStorage})
    : _fileStorage = fileStorage;

  GithubSyncManifest? loadManifest() {
    final manifestJson = _fileStorage.getString(_syncManifestKey);
    if (manifestJson == null) return null;
    try {
      return GithubSyncManifest.fromJson(
        jsonDecode(manifestJson) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveManifest(GithubSyncManifest manifest) async {
    await _fileStorage.setString(
      _syncManifestKey,
      jsonEncode(manifest.toJson()),
    );
  }

  Map<String, SyncFileEntry> buildManifestIndex(GithubSyncManifest manifest) {
    return {for (var entry in manifest.files) entry.path: entry};
  }
}
