import 'dart:io';

import 'package:contextchat/github_sync/github_sync_conflict_resolver.dart';
import 'package:contextchat/github_sync/models/github_operation_results.dart';
import 'package:contextchat/github_sync/models/github_sync_manifest.dart';
import 'package:contextchat/github_sync/models/github_sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConflictResolver extends GithubSyncConflictResolver {
  bool resolveCalled = false;

  @override
  bool resolve({
    required DateTime localModified,
    required DateTime? remoteUpdated,
    required String localPath,
    required String remotePath,
  }) {
    resolveCalled = true;
    return localModified.isAfter(remoteUpdated ?? DateTime.now());
  }
}

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
  bool deleteFileCalled = false;
  String? deletedPath;

  Future<List<SyncFileEntry>> buildManifest() async => localFiles;

  Future<void> writeFile(String path, List<int> content) async {
    fileContents[path] = content;
  }

  Future<void> deleteFile(String path) async {
    deleteFileCalled = true;
    deletedPath = path;
  }

  Future<FileStat?> getFileStat(String path) async => null;

  String computeSha256(List<int> content) => 'fake_sha_256';
}

void main() {
  group('PullOperationResult', () {
    test('should create result with all fields', () {
      final result = GithubPullOperationResult(
        downloaded: 5,
        skipped: 10,
        deleted: 2,
        conflicts: 1,
        conflictedFiles: ['file1.txt'],
        commitSha: 'abc123',
        syncedAt: DateTime(2024, 1, 15),
      );

      expect(result.downloaded, 5);
      expect(result.skipped, 10);
      expect(result.deleted, 2);
      expect(result.conflicts, 1);
      expect(result.conflictedFiles, ['file1.txt']);
      expect(result.commitSha, 'abc123');
      expect(result.syncedAt, DateTime(2024, 1, 15));
    });
  });

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
  });

  group('SyncConflictResolver', () {
    late FakeConflictResolver resolver;

    setUp(() {
      resolver = FakeConflictResolver();
    });

    test('should resolve conflict with local wins when local is newer', () {
      final localModified = DateTime(2024, 1, 15, 12, 0);
      final remoteUpdated = DateTime(2024, 1, 15, 10, 0);

      final result = resolver.resolve(
        localModified: localModified,
        remoteUpdated: remoteUpdated,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );

      expect(result, isTrue);
      expect(resolver.resolveCalled, isTrue);
    });

    test('should resolve conflict with remote wins when remote is newer', () {
      final localModified = DateTime(2024, 1, 15, 10, 0);
      final remoteUpdated = DateTime(2024, 1, 15, 12, 0);

      final result = resolver.resolve(
        localModified: localModified,
        remoteUpdated: remoteUpdated,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );

      expect(result, isFalse);
    });
  });

  group('SyncManifest', () {
    test('should serialize and deserialize correctly', () {
      final manifest = GithubSyncManifest(
        version: '1.0',
        generatedAt: DateTime(2024, 1, 15, 10, 30),
        files: [
          SyncFileEntry(
            path: 'test/file1.txt',
            sha256: 'abc123',
            sizeBytes: 100,
            modifiedAt: DateTime(2024, 1, 15, 10, 0),
            remoteBlobSha: 'blob_sha_1',
          ),
        ],
        syncedSettings: {'commitSha': 'abc123def456'},
      );

      final json = manifest.toJson();
      final restored = GithubSyncManifest.fromJson(json);

      expect(restored.version, '1.0');
      expect(restored.files.length, 1);
      expect(restored.files[0].path, 'test/file1.txt');
      expect(restored.files[0].remoteBlobSha, 'blob_sha_1');
    });

    test('should preserve remoteBlobSha via copyWith', () {
      final entry = SyncFileEntry(
        path: 'test.txt',
        sha256: 'local_sha',
        sizeBytes: 100,
        modifiedAt: DateTime(2024, 1, 15, 10, 0),
        remoteBlobSha: 'remote_blob_sha',
      );

      final updated = entry.copyWith(
        sha256: 'new_local_sha',
        modifiedAt: DateTime(2024, 1, 15, 11, 0),
      );

      expect(updated.remoteBlobSha, 'remote_blob_sha');
      expect(updated.sha256, 'new_local_sha');
    });
  });

  group('CompareResult', () {
    test('should store comparison data correctly', () {
      const result = GithubCompareResult(
        status: 'diverged',
        aheadBy: 3,
        behindBy: 2,
        totalCommits: 5,
        commits: [],
        files: [],
      );

      expect(result.status, 'diverged');
      expect(result.aheadBy, 3);
      expect(result.behindBy, 2);
      expect(result.totalCommits, 5);
    });
  });
}
