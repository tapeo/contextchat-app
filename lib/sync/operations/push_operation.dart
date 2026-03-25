import 'package:contextchat/sync/models/operation_results.dart';
import 'package:contextchat/sync/models/sync_config.dart';
import 'package:contextchat/sync/models/sync_manifest.dart';
import 'package:contextchat/sync/sync_index_builder.dart';
import 'package:contextchat/sync/sync_manifest_manager.dart';
import 'package:contextchat/sync/sync_repository.dart';
import 'package:contextchat/sync/sync_service.dart';

class PushOperation {
  final SyncService _syncService;
  final SyncRepository _repository;
  final SyncManifestManager _manifestManager;

  PushOperation({
    required SyncService syncService,
    required SyncRepository repository,
    required SyncManifestManager manifestManager,
  }) : _syncService = syncService,
       _repository = repository,
       _manifestManager = manifestManager;

  Future<PushOperationResult> execute({
    required SyncConfig config,
    required String token,
    required String? lastSyncedCommitSha,
    required void Function(String message, int current, int total) onProgress,
    required void Function(String error) onDivergence,
  }) async {
    final branch = await _syncService.getOrCreateBranch(
      config.owner,
      config.repo,
      config.branch,
      token: token,
    );

    if (lastSyncedCommitSha != null &&
        lastSyncedCommitSha != branch.commitSha) {
      try {
        final compareResult = await _syncService.compareCommits(
          config.owner,
          config.repo,
          lastSyncedCommitSha,
          branch.commitSha,
          token: token,
        );

        if (compareResult.aheadBy > 0) {
          onDivergence(
            'Remote has ${compareResult.aheadBy} new commit(s). Please pull first.',
          );
          throw Exception('Divergence detected');
        }
      } catch (e) {
        if (e.toString().contains('Divergence detected')) {
          rethrow;
        }
        onDivergence('Remote has changed. Please pull first.');
        throw Exception('Divergence detected');
      }
    }

    onProgress('Scanning local files...', 0, 0);

    final localFiles = await _repository.buildManifest();
    final prefix = config.subdirectory != null ? '${config.subdirectory}/' : '';

    final lastManifest = _manifestManager.loadManifest();
    final lastIndex = lastManifest != null
        ? _manifestManager.buildManifestIndex(lastManifest)
        : <String, SyncFileEntry>{};

    final remoteTree = await _syncService.getTree(
      config.owner,
      config.repo,
      branch.treeSha,
      token: token,
    );
    final remoteIndex = SyncIndexBuilder.buildRemoteIndex(
      remoteTree.entries,
      prefix,
    );

    final filesToUpload = <SyncFileEntry>[];
    final filesToSkip = <SyncFileEntry>[];
    final filesToDelete = <String>[];
    final conflicts = <String>[];

    for (final localEntry in localFiles) {
      final lastEntry = lastIndex[localEntry.path];
      final remoteEntry = remoteIndex[localEntry.path];

      if (remoteEntry != null) {
        final localChanged =
            lastEntry == null ||
            lastEntry.sha256 != localEntry.sha256 ||
            lastEntry.modifiedAt != localEntry.modifiedAt;

        if (localChanged) {
          filesToUpload.add(localEntry);
        } else {
          filesToSkip.add(localEntry.copyWith(remoteBlobSha: remoteEntry.sha));
        }
      } else {
        filesToUpload.add(localEntry);
      }
    }

    for (final lastPath in lastIndex.keys) {
      final currentLocal = localFiles.any((f) => f.path == lastPath);
      if (!currentLocal && remoteIndex.containsKey(lastPath)) {
        filesToDelete.add(lastPath);
      }
    }

    onProgress(
      'Uploading ${filesToUpload.length} files (${filesToSkip.length} skipped)...',
      0,
      filesToUpload.length,
    );

    final treeEntries = <Map<String, dynamic>>[];
    final uploadedEntries = <SyncFileEntry>[];

    for (var i = 0; i < filesToUpload.length; i++) {
      final entry = filesToUpload[i];
      final content = await _repository.readFile(entry.path);
      if (content == null) continue;

      onProgress('Uploading ${entry.path}', i + 1, filesToUpload.length);

      final blobSha = await _syncService.createBlob(
        config.owner,
        config.repo,
        content,
        token: token,
      );

      treeEntries.add({
        'path': '$prefix${entry.path}',
        'mode': '100644',
        'type': 'blob',
        'sha': blobSha,
      });

      uploadedEntries.add(entry.copyWith(remoteBlobSha: blobSha));
    }

    onProgress('Creating commit...', 0, 1);

    final treeSha = treeEntries.isEmpty
        ? branch.treeSha
        : await _syncService.createTree(
            config.owner,
            config.repo,
            branch.treeSha,
            treeEntries,
            token: token,
          );

    final String commitSha;
    if (treeEntries.isEmpty) {
      commitSha = branch.commitSha;
    } else {
      commitSha = await _syncService.createCommit(
        config.owner,
        config.repo,
        'Sync from ContextChat',
        treeSha,
        [branch.commitSha],
        token: token,
      );

      onProgress('Updating remote...', 0, 1);

      await _syncService.updateRef(
        config.owner,
        config.repo,
        'heads/${config.branch}',
        commitSha,
        token: token,
      );
    }

    final newManifestFiles = [...uploadedEntries, ...filesToSkip];
    final newManifest = SyncManifest(
      version: '1.0',
      generatedAt: DateTime.now(),
      files: newManifestFiles,
      syncedSettings: {
        'commitSha': commitSha,
        'uploaded': uploadedEntries.length,
        'skipped': filesToSkip.length,
        'deleted': filesToDelete.length,
        'conflicts': conflicts.length,
      },
    );
    await _manifestManager.saveManifest(newManifest);

    return PushOperationResult(
      uploaded: uploadedEntries.length,
      skipped: filesToSkip.length,
      deleted: filesToDelete.length,
      conflicts: conflicts.length,
      conflictedFiles: conflicts,
      commitSha: commitSha,
      syncedAt: DateTime.now(),
      manifest: newManifest,
    );
  }
}
