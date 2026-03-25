import 'dart:convert';

import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/github_sync/github_sync_service.dart';
import 'package:contextchat/github_sync/github_sync_state.dart';
import 'package:contextchat/github_sync/models/enums.dart';
import 'package:contextchat/github_sync/models/exceptions.dart';
import 'package:contextchat/github_sync/models/github_sync_config.dart';
import 'package:contextchat/github_sync/models/github_sync_progress.dart';
import 'package:contextchat/github_sync/operations/github_pull_operation.dart';
import 'package:contextchat/github_sync/operations/github_push_operation.dart';
import 'package:contextchat/secure_storage/secure_storage.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'github_sync_conflict_resolver.dart';
import 'github_sync_manifest_manager.dart';
import 'github_sync_repository.dart';

const _syncConfigKey = 'sync_config';
const _syncLastAtKey = 'sync_last_at';
const _syncLastShaKey = 'sync_last_sha';

final githubSyncServiceProvider = Provider<GithubSyncService>((ref) {
  return GithubSyncService();
});

final githubSyncRepositoryProvider = Provider<GithubSyncRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return GithubSyncRepository(basePath: database.memoryPath);
});

final githubSyncManifestManagerProvider = Provider<GithubSyncManifestManager>((
  ref,
) {
  final fileStorage = ref.watch(fileStorageProvider);
  return GithubSyncManifestManager(fileStorage: fileStorage);
});

final githubSyncConflictResolverProvider = Provider<GithubSyncConflictResolver>(
  (ref) {
    return GithubSyncConflictResolver();
  },
);

final githubSyncProvider =
    NotifierProvider<GithubSyncNotifier, GithubSyncState>(
      () => GithubSyncNotifier(),
    );

class GithubSyncNotifier extends Notifier<GithubSyncState> {
  FileStorage get _fileStorage => ref.watch(fileStorageProvider);
  GithubSyncService get _syncService => ref.watch(githubSyncServiceProvider);
  GithubSyncRepository get _repository =>
      ref.watch(githubSyncRepositoryProvider);
  GithubSyncManifestManager get _manifestManager =>
      ref.watch(githubSyncManifestManagerProvider);
  GithubSyncConflictResolver get _conflictResolver =>
      ref.watch(githubSyncConflictResolverProvider);

  GithubPullOperation get _pullOperation => GithubPullOperation(
    syncService: _syncService,
    repository: _repository,
    manifestManager: _manifestManager,
    conflictResolver: _conflictResolver,
  );

  GithubPushOperation get _pushOperation => GithubPushOperation(
    syncService: _syncService,
    repository: _repository,
    manifestManager: _manifestManager,
  );

  @override
  GithubSyncState build() {
    final configJson = _fileStorage.getString(_syncConfigKey);
    final config = configJson != null
        ? GithubSyncConfig.fromJson(
            jsonDecode(configJson) as Map<String, dynamic>,
          )
        : null;

    final lastSyncedAtStr = _fileStorage.getString(_syncLastAtKey);
    final lastSyncedAt = lastSyncedAtStr != null
        ? DateTime.tryParse(lastSyncedAtStr)
        : null;

    return GithubSyncState(
      status: SyncStatus.idle,
      config: config,
      lastSyncedAt: lastSyncedAt,
      lastSyncedCommitSha: _fileStorage.getString(_syncLastShaKey),
    );
  }

  Future<void> configure(GithubSyncConfig config) async {
    await _fileStorage.setString(_syncConfigKey, jsonEncode(config.toJson()));
    state = state.copyWith(config: config);
  }

  Future<void> clearConfig() async {
    await _fileStorage.remove(_syncConfigKey);
    await _fileStorage.remove(_syncLastAtKey);
    await _fileStorage.remove(_syncLastShaKey);
    await _fileStorage.remove('sync_manifest');
    await SecureStorageService.deleteGithubToken();
    state = GithubSyncState(status: SyncStatus.idle);
  }

  Future<void> pull() async {
    final config = state.config;
    if (config == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: 'No sync configuration',
      );
      return;
    }

    final token = await SecureStorageService.getGithubToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: 'No GitHub token',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.pulling,
      error: null,
      progress: const GithubSyncProgress(message: 'Connecting to GitHub...'),
    );

    try {
      final result = await _pullOperation.execute(
        config: config,
        token: token,
        lastSyncedCommitSha: state.lastSyncedCommitSha,
        onProgress: (message, current, total) {
          state = state.copyWith(
            progress: GithubSyncProgress(
              message: message,
              current: current,
              total: total,
            ),
          );
        },
      );

      await _fileStorage.setString(
        _syncLastAtKey,
        result.syncedAt!.toIso8601String(),
      );
      await _fileStorage.setString(_syncLastShaKey, result.commitSha!);

      state = state.copyWith(
        status: SyncStatus.idle,
        lastSyncedAt: result.syncedAt,
        lastSyncedCommitSha: result.commitSha,
        error: null,
        progress: null,
      );
    } catch (e) {
      String errorMsg;
      if (e is EmptyRepositoryException) {
        errorMsg = e.toString();
      } else if (e is BranchNotFoundException) {
        errorMsg = e.toString();
      } else {
        errorMsg = 'Pull failed: $e';
      }
      state = state.copyWith(
        status: SyncStatus.error,
        error: errorMsg,
        progress: null,
      );
    }
  }

  Future<void> push() async {
    final config = state.config;
    if (config == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: 'No sync configuration',
      );
      return;
    }

    final token = await SecureStorageService.getGithubToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: 'No GitHub token',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.pushing,
      error: null,
      progress: const GithubSyncProgress(message: 'Connecting to GitHub...'),
    );

    try {
      final result = await _pushOperation.execute(
        config: config,
        token: token,
        lastSyncedCommitSha: state.lastSyncedCommitSha,
        onProgress: (message, current, total) {
          state = state.copyWith(
            progress: GithubSyncProgress(
              message: message,
              current: current,
              total: total,
            ),
          );
        },
        onDivergence: (error) {
          state = state.copyWith(
            status: SyncStatus.divergence,
            error: error,
            progress: null,
          );
        },
      );

      await _fileStorage.setString(
        _syncLastAtKey,
        result.syncedAt!.toIso8601String(),
      );
      await _fileStorage.setString(_syncLastShaKey, result.commitSha!);

      state = state.copyWith(
        status: SyncStatus.idle,
        lastSyncedAt: result.syncedAt,
        lastSyncedCommitSha: result.commitSha,
        error: null,
        progress: null,
      );
    } catch (e) {
      if (e.toString().contains('Divergence detected')) {
        return;
      }
      String errorMsg;
      if (e is EmptyRepositoryException) {
        errorMsg = e.toString();
      } else if (e is BranchNotFoundException) {
        errorMsg = e.toString();
      } else {
        errorMsg = 'Push failed: $e';
      }
      state = state.copyWith(
        status: SyncStatus.error,
        error: errorMsg,
        progress: null,
      );
    }
  }
}
