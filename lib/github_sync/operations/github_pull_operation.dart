import 'package:contextchat/github_sync/github_sync_conflict_resolver.dart';
import 'package:contextchat/github_sync/github_sync_index_builder.dart';
import 'package:contextchat/github_sync/github_sync_manifest_manager.dart';
import 'package:contextchat/github_sync/github_sync_repository.dart';
import 'package:contextchat/github_sync/github_sync_service.dart';
import 'package:contextchat/github_sync/models/github_models.dart';
import 'package:contextchat/github_sync/models/github_operation_results.dart';
import 'package:contextchat/github_sync/models/github_sync_config.dart';
import 'package:contextchat/github_sync/models/github_sync_manifest.dart';

class GithubPullOperation {
  final GithubSyncService _syncService;
  final GithubSyncRepository _repository;
  final GithubSyncManifestManager _manifestManager;
  final GithubSyncConflictResolver _conflictResolver;

  GithubPullOperation({
    required GithubSyncService syncService,
    required GithubSyncRepository repository,
    required GithubSyncManifestManager manifestManager,
    required GithubSyncConflictResolver conflictResolver,
  }) : _syncService = syncService,
       _repository = repository,
       _manifestManager = manifestManager,
       _conflictResolver = conflictResolver;

  Future<GithubPullOperationResult> execute({
    required GithubSyncConfig config,
    required String token,
    required String? lastSyncedCommitSha,
    required void Function(String message, int current, int total) onProgress,
  }) async {
    final branch = await _syncService.getOrCreateBranch(
      config.owner,
      config.repo,
      config.branch,
      token: token,
    );

    onProgress('Fetching file list...', 0, 0);

    final tree = await _syncService.getTree(
      config.owner,
      config.repo,
      branch.treeSha,
      token: token,
    );

    final prefix = config.subdirectory != null ? '${config.subdirectory}/' : '';

    final lastManifest = _manifestManager.loadManifest();
    final lastIndex = lastManifest != null
        ? _manifestManager.buildManifestIndex(lastManifest)
        : <String, SyncFileEntry>{};

    final remoteIndex = GithubSyncIndexBuilder.buildRemoteIndex(
      tree.entries,
      prefix,
    );

    final currentLocalFiles = await _repository.buildManifest();
    final currentLocalIndex = {
      for (var entry in currentLocalFiles) entry.path: entry,
    };

    final filesToDownload = <RemoteFileInfo>[];
    final filesToSkip = <String>[];
    final filesToDelete = <String>[];
    final conflicts = <String>[];

    for (final remoteFile in remoteIndex.values) {
      final lastEntry = lastIndex[remoteFile.path];
      final currentLocalEntry = currentLocalIndex[remoteFile.path];

      if (currentLocalEntry != null) {
        final remoteChanged =
            lastEntry == null ||
            (lastEntry.remoteBlobSha == null
                ? true
                : lastEntry.remoteBlobSha != remoteFile.sha);

        final localChanged =
            lastEntry == null ||
            lastEntry.sha256 != currentLocalEntry.sha256 ||
            lastEntry.modifiedAt != currentLocalEntry.modifiedAt;

        if (remoteChanged && localChanged) {
          final localWins = _conflictResolver.resolve(
            localModified: currentLocalEntry.modifiedAt,
            remoteUpdated: branch.commitTimestamp,
            localPath: remoteFile.path,
            remotePath: remoteFile.path,
          );

          if (localWins) {
            filesToSkip.add(remoteFile.path);
            conflicts.add(remoteFile.path);
          } else {
            filesToDownload.add(remoteFile);
            conflicts.add(remoteFile.path);
          }
        } else if (remoteChanged) {
          filesToDownload.add(remoteFile);
        } else {
          filesToSkip.add(remoteFile.path);
        }
      } else {
        filesToDownload.add(remoteFile);
      }
    }

    for (final localPath in currentLocalIndex.keys) {
      if (!remoteIndex.containsKey(localPath)) {
        final lastEntry = lastIndex[localPath];
        if (lastEntry != null) {
          filesToDelete.add(localPath);
        }
      }
    }

    for (final path in filesToDelete) {
      await _repository.deleteFile(path);
    }

    final downloadedFiles = <SyncFileEntry>[];
    for (var i = 0; i < filesToDownload.length; i++) {
      final remoteFile = filesToDownload[i];

      onProgress(
        'Downloading ${remoteFile.path}',
        i + 1,
        filesToDownload.length,
      );

      final blob = await _syncService.getBlob(
        config.owner,
        config.repo,
        remoteFile.sha,
        token: token,
      );

      await _repository.writeFile(remoteFile.path, blob.decodedContent);

      final stat = await _repository.getFileStat(remoteFile.path);
      final sha256 = _repository.computeSha256(blob.decodedContent);
      downloadedFiles.add(
        SyncFileEntry(
          path: remoteFile.path,
          sha256: sha256,
          sizeBytes: blob.decodedContent.length,
          modifiedAt: stat?.modified ?? DateTime.now(),
          remoteBlobSha: remoteFile.sha,
        ),
      );
    }

    final skippedFiles = <SyncFileEntry>[];
    for (final path in filesToSkip) {
      final lastEntry = lastIndex[path];
      final remoteFile = remoteIndex[path];
      if (lastEntry != null) {
        skippedFiles.add(lastEntry.copyWith(remoteBlobSha: remoteFile?.sha));
      }
    }

    final newManifest = GithubSyncManifest(
      version: '1.0',
      generatedAt: DateTime.now(),
      files: [...downloadedFiles, ...skippedFiles],
      syncedSettings: {
        'commitSha': branch.commitSha,
        'downloaded': filesToDownload.length,
        'skipped': filesToSkip.length,
        'deleted': filesToDelete.length,
        'conflicts': conflicts.length,
      },
    );
    await _manifestManager.saveManifest(newManifest);

    return GithubPullOperationResult(
      downloaded: filesToDownload.length,
      skipped: filesToSkip.length,
      deleted: filesToDelete.length,
      conflicts: conflicts.length,
      conflictedFiles: conflicts,
      commitSha: branch.commitSha,
      syncedAt: DateTime.now(),
      manifest: newManifest,
    );
  }
}
