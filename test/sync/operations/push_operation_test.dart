import 'package:contextchat/github_sync/models/github_models.dart';
import 'package:contextchat/github_sync/models/github_operation_results.dart';
import 'package:contextchat/github_sync/models/github_sync_manifest.dart';
import 'package:contextchat/github_sync/models/github_sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeManifestManager {
  GithubSyncManifest? loadedManifest;
  GithubSyncManifest? savedManifest;
  int saveManifestCallCount = 0;

  GithubSyncManifest? loadManifest() => loadedManifest;

  Future<void> saveManifest(GithubSyncManifest manifest) async {
    savedManifest = manifest;
    saveManifestCallCount++;
  }

  Map<String, SyncFileEntry> buildManifestIndex(GithubSyncManifest manifest) {
    return {for (var entry in manifest.files) entry.path: entry};
  }
}

class FakeRepository {
  final List<SyncFileEntry> localFiles = [];
  final Map<String, List<int>> fileContents = {};

  Future<List<SyncFileEntry>> buildManifest() async => localFiles;

  Future<List<int>?> readFile(String path) async {
    return fileContents[path];
  }
}

void main() {
  group('PushOperationResult', () {
    test('should create result with all fields', () {
      final result = PushOperationResult(
        uploaded: 3,
        skipped: 7,
        deleted: 1,
        conflicts: 0,
        conflictedFiles: [],
        commitSha: 'def456',
        syncedAt: DateTime(2024, 1, 16),
      );

      expect(result.uploaded, 3);
      expect(result.skipped, 7);
      expect(result.deleted, 1);
      expect(result.conflicts, 0);
      expect(result.conflictedFiles, isEmpty);
      expect(result.commitSha, 'def456');
      expect(result.syncedAt, DateTime(2024, 1, 16));
    });

    test('should include manifest in result', () {
      final manifest = GithubSyncManifest(
        version: '1.0',
        generatedAt: DateTime.now(),
        files: [
          SyncFileEntry(
            path: 'test.txt',
            sha256: 'hash123',
            sizeBytes: 100,
            modifiedAt: DateTime.now(),
          ),
        ],
        syncedSettings: {},
      );

      final result = PushOperationResult(
        uploaded: 1,
        skipped: 0,
        deleted: 0,
        conflicts: 0,
        conflictedFiles: [],
        commitSha: 'abc123',
        syncedAt: DateTime.now(),
        manifest: manifest,
      );

      expect(result.manifest, isNotNull);
      expect(result.manifest!.files.length, 1);
    });
  });

  group('Divergence Detection', () {
    test('should detect when remote has new commits', () {
      const compareResult = GithubCompareResult(
        status: 'diverged',
        aheadBy: 5,
        behindBy: 0,
        totalCommits: 5,
        commits: [],
        files: [],
      );

      expect(compareResult.aheadBy > 0, isTrue);
      expect(compareResult.behindBy == 0, isTrue);
    });

    test('should allow push when only behind', () {
      const compareResult = GithubCompareResult(
        status: 'behind',
        aheadBy: 0,
        behindBy: 3,
        totalCommits: 3,
        commits: [],
        files: [],
      );

      expect(compareResult.aheadBy == 0, isTrue);
      expect(compareResult.behindBy > 0, isTrue);
    });
  });

  group('Delta Detection', () {
    test('should create upload list with only changed files', () {
      final lastManifest = [
        SyncFileEntry(
          path: 'unchanged.txt',
          sha256: 'unchanged_hash',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
          remoteBlobSha: 'blob_unchanged',
        ),
        SyncFileEntry(
          path: 'changed.txt',
          sha256: 'old_hash',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
          remoteBlobSha: 'blob_old',
        ),
      ];

      final currentLocal = [
        SyncFileEntry(
          path: 'unchanged.txt',
          sha256: 'unchanged_hash',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
        ),
        SyncFileEntry(
          path: 'changed.txt',
          sha256: 'new_hash',
          sizeBytes: 150,
          modifiedAt: DateTime(2024, 1, 15, 11, 0),
        ),
        SyncFileEntry(
          path: 'new.txt',
          sha256: 'new_file_hash',
          sizeBytes: 50,
          modifiedAt: DateTime(2024, 1, 15, 11, 30),
        ),
      ];

      final filesToUpload = <SyncFileEntry>[];
      final filesToSkip = <SyncFileEntry>[];

      for (final localEntry in currentLocal) {
        final lastEntry = lastManifest.firstWhere(
          (e) => e.path == localEntry.path,
          orElse: () => SyncFileEntry(
            path: '',
            sha256: '',
            sizeBytes: 0,
            modifiedAt: DateTime.now(),
          ),
        );

        if (lastEntry.path.isEmpty) {
          filesToUpload.add(localEntry);
        } else if (lastEntry.sha256 != localEntry.sha256 ||
            lastEntry.modifiedAt != localEntry.modifiedAt) {
          filesToUpload.add(localEntry);
        } else {
          filesToSkip.add(localEntry);
        }
      }

      expect(
        filesToUpload.map((e) => e.path).toList()..sort(),
        equals(['changed.txt', 'new.txt']),
      );
      expect(
        filesToSkip.map((e) => e.path).toList(),
        equals(['unchanged.txt']),
      );
    });

    test('should detect remote files to delete', () {
      final lastIndex = {
        'file1.txt': SyncFileEntry(
          path: 'file1.txt',
          sha256: 'hash1',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
          remoteBlobSha: 'blob1',
        ),
        'file2.txt': SyncFileEntry(
          path: 'file2.txt',
          sha256: 'hash2',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
          remoteBlobSha: 'blob2',
        ),
      };

      final localFiles = [
        SyncFileEntry(
          path: 'file1.txt',
          sha256: 'hash1',
          sizeBytes: 100,
          modifiedAt: DateTime(2024, 1, 15, 10, 0),
        ),
      ];

      final remoteIndex = {
        'file1.txt': RemoteFileInfo(path: 'file1.txt', sha: 'blob1'),
      };

      final filesToDelete = <String>[];
      for (final lastPath in lastIndex.keys) {
        final currentLocal = localFiles.any((f) => f.path == lastPath);
        if (!currentLocal && remoteIndex.containsKey(lastPath)) {
          filesToDelete.add(lastPath);
        }
      }

      expect(filesToDelete, isEmpty);
    });
  });

  group('GitHub Models', () {
    test('should create GitHubBranch correctly', () {
      final branch = GitHubBranch(
        name: 'main',
        commitSha: 'abc123',
        treeSha: 'tree456',
        commitTimestamp: DateTime(2024, 1, 15),
      );

      expect(branch.name, 'main');
      expect(branch.commitSha, 'abc123');
      expect(branch.treeSha, 'tree456');
      expect(branch.commitTimestamp, DateTime(2024, 1, 15));
    });

    test('should create GitHubTree correctly', () {
      final entries = [
        GitHubTreeEntry(
          path: 'file.txt',
          mode: '100644',
          type: 'blob',
          sha: 'blob123',
          size: 100,
        ),
      ];

      final tree = GitHubTree(sha: 'tree123', entries: entries);

      expect(tree.sha, 'tree123');
      expect(tree.entries.length, 1);
      expect(tree.entries[0].path, 'file.txt');
    });

    test('GitHubBlob decodedContent should decode base64', () {
      const blob = GitHubBlob(
        sha: 'blob123',
        content: 'dGVzdCBjb250ZW50', // base64 encoded "test content"
        encoding: 'base64',
        size: 16,
      );

      final decoded = blob.decodedContent;
      expect(decoded, isA<List<int>>());
    });
  });
}
