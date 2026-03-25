import 'package:contextchat/github_sync/models/github_models.dart';

/// Builds indexes for remote files
class GithubSyncIndexBuilder {
  /// Build remote file index from tree entries
  static Map<String, RemoteFileInfo> buildRemoteIndex(
    List<GitHubTreeEntry> entries,
    String prefix,
  ) {
    final index = <String, RemoteFileInfo>{};
    for (final entry in entries) {
      if (entry.type == 'blob' && entry.path.startsWith(prefix)) {
        final relativePath = entry.path.substring(prefix.length);
        if (relativePath.isNotEmpty && entry.sha != null) {
          index[relativePath] = RemoteFileInfo(
            path: relativePath,
            sha: entry.sha!,
            size: entry.size,
          );
        }
      }
    }
    return index;
  }
}
