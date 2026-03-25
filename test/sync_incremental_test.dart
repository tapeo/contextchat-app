import 'dart:convert';
import 'dart:typed_data';

import 'package:contextchat/sync/models/sync_manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncManifest', () {
    test('should serialize and deserialize correctly', () {
      final manifest = SyncManifest(
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
          SyncFileEntry(
            path: 'test/file2.txt',
            sha256: 'def456',
            sizeBytes: 200,
            modifiedAt: DateTime(2024, 1, 15, 10, 15),
          ),
        ],
        syncedSettings: {'commitSha': 'abc123def456'},
      );

      final json = manifest.toJson();
      final restored = SyncFileEntry.fromJson(
        json['files'][0] as Map<String, dynamic>,
      );

      expect(restored.path, 'test/file1.txt');
      expect(restored.sha256, 'abc123');
      expect(restored.remoteBlobSha, 'blob_sha_1');
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

      // copyWith should preserve remoteBlobSha by default
      expect(updated.remoteBlobSha, 'remote_blob_sha');
      expect(updated.sha256, 'new_local_sha');
    });
  });

  group('SHA256 Hashing', () {
    test('should compute SHA256 correctly', () {
      final content = Uint8List.fromList(utf8.encode('Hello, World!'));
      final digest = sha256.convert(content);
      final hash = digest.toString();

      expect(hash.length, 64);
      expect(hash, isNotEmpty);
    });

    test('should produce different hashes for different content', () {
      final content1 = Uint8List.fromList(utf8.encode('Content A'));
      final content2 = Uint8List.fromList(utf8.encode('Content B'));

      final hash1 = sha256.convert(content1).toString();
      final hash2 = sha256.convert(content2).toString();

      expect(hash1, isNot(equals(hash2)));
    });

    test('should produce same hash for same content', () {
      final content = Uint8List.fromList(utf8.encode('Same Content'));

      final hash1 = sha256.convert(content).toString();
      final hash2 = sha256.convert(content).toString();

      expect(hash1, equals(hash2));
    });
  });

  group('Conflict Resolution - Last-Write-Wins', () {
    bool resolveConflict({
      required DateTime localModified,
      required DateTime? remoteUpdated,
      required String localPath,
      required String remotePath,
    }) {
      final effectiveRemoteTime = remoteUpdated ?? DateTime.now();
      final timeDiff = localModified.difference(effectiveRemoteTime).abs();

      if (timeDiff.inSeconds <= 1) {
        return localPath.compareTo(remotePath) <= 0;
      }

      return localModified.isAfter(effectiveRemoteTime);
    }

    test('local wins when local is newer', () {
      final localModified = DateTime(2024, 1, 15, 12, 0);
      final remoteUpdated = DateTime(2024, 1, 15, 10, 0);

      final result = resolveConflict(
        localModified: localModified,
        remoteUpdated: remoteUpdated,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );

      expect(result, isTrue);
    });

    test('remote wins when remote is newer', () {
      final localModified = DateTime(2024, 1, 15, 10, 0);
      final remoteUpdated = DateTime(2024, 1, 15, 12, 0);

      final result = resolveConflict(
        localModified: localModified,
        remoteUpdated: remoteUpdated,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );

      expect(result, isFalse);
    });

    test('deterministic tie-breaker for simultaneous changes', () {
      final time = DateTime(2024, 1, 15, 12, 0, 0);

      final result1 = resolveConflict(
        localModified: time,
        remoteUpdated: time,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );
      final result2 = resolveConflict(
        localModified: time,
        remoteUpdated: time,
        localPath: 'file.txt',
        remotePath: 'file.txt',
      );

      expect(result1, equals(result2));
    });

    test('clock skew safeguard - 1 second threshold', () {
      final baseTime = DateTime(2024, 1, 15, 12, 0, 0);

      final resultClose = resolveConflict(
        localModified: baseTime,
        remoteUpdated: baseTime.add(const Duration(milliseconds: 500)),
        localPath: 'a.txt',
        remotePath: 'b.txt',
      );
      expect(resultClose, isTrue);

      final resultFar = resolveConflict(
        localModified: baseTime,
        remoteUpdated: baseTime.add(const Duration(seconds: 2)),
        localPath: 'a.txt',
        remotePath: 'b.txt',
      );
      expect(resultFar, isFalse);
    });
  });

  group('Change Detection', () {
    test('should detect unchanged file using remoteBlobSha', () {
      final lastEntry = SyncFileEntry(
        path: 'test.txt',
        sha256: 'local_hash_abc',
        sizeBytes: 100,
        modifiedAt: DateTime(2024, 1, 15, 10, 0),
        remoteBlobSha: 'remote_blob_sha_123',
      );

      final remoteBlobSha = 'remote_blob_sha_123'; // Same as stored

      // Check remote change using remoteBlobSha
      final remoteChanged = lastEntry.remoteBlobSha != remoteBlobSha;

      expect(remoteChanged, isFalse);
    });

    test('should detect remote change when blob SHA differs', () {
      final lastEntry = SyncFileEntry(
        path: 'test.txt',
        sha256: 'local_hash_abc',
        sizeBytes: 100,
        modifiedAt: DateTime(2024, 1, 15, 10, 0),
        remoteBlobSha: 'old_remote_blob',
      );

      final remoteBlobSha = 'new_remote_blob'; // Changed

      final remoteChanged = lastEntry.remoteBlobSha != remoteBlobSha;

      expect(remoteChanged, isTrue);
    });

    test('should treat missing remoteBlobSha as changed (legacy manifest)', () {
      final lastEntry = SyncFileEntry(
        path: 'test.txt',
        sha256: 'local_hash',
        sizeBytes: 100,
        modifiedAt: DateTime(2024, 1, 15, 10, 0),
        // remoteBlobSha is null
      );

      final remoteBlobSha = 'some_remote_blob';

      // If remoteBlobSha is null, assume changed for safety
      final remoteChanged = lastEntry.remoteBlobSha == null
          ? true
          : lastEntry.remoteBlobSha != remoteBlobSha;

      expect(remoteChanged, isTrue);
    });
  });

  group('Deletion Detection', () {
    test('should detect remotely deleted file', () {
      final lastFiles = ['file1.txt', 'file2.txt'];
      final currentRemoteFiles = ['file1.txt'];
      final currentLocalFiles = ['file1.txt', 'file2.txt'];

      final filesToDelete = <String>[];
      for (final localPath in currentLocalFiles) {
        if (!currentRemoteFiles.contains(localPath)) {
          if (lastFiles.contains(localPath)) {
            filesToDelete.add(localPath);
          }
        }
      }

      expect(filesToDelete, equals(['file2.txt']));
    });

    test('should keep new local file not in remote', () {
      final lastFiles = ['file1.txt'];
      final currentRemoteFiles = ['file1.txt'];
      final currentLocalFiles = ['file1.txt', 'file2.txt'];

      final filesToDelete = <String>[];
      for (final localPath in currentLocalFiles) {
        if (!currentRemoteFiles.contains(localPath)) {
          if (lastFiles.contains(localPath)) {
            filesToDelete.add(localPath);
          }
        }
      }

      expect(filesToDelete, isEmpty);
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
  });
}
