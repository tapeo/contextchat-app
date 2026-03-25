import 'dart:convert';

import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/sync/models/enums.dart';
import 'package:contextchat/sync/models/exceptions.dart';
import 'package:contextchat/sync/models/sync_config.dart';
import 'package:contextchat/sync/models/sync_progress.dart';
import 'package:contextchat/sync/operations/pull_operation.dart';
import 'package:contextchat/sync/operations/push_operation.dart';
import 'package:contextchat/sync/sync_credential.provider.dart';
import 'package:contextchat/sync/sync_service.dart';
import 'package:contextchat/sync/sync_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_conflict_resolver.dart';
import 'sync_manifest_manager.dart';
import 'sync_repository.dart';

const _syncConfigKey = 'sync_config';
const _syncLastAtKey = 'sync_last_at';
const _syncLastShaKey = 'sync_last_sha';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return SyncRepository(basePath: database.memoryPath);
});

final syncManifestManagerProvider = Provider<SyncManifestManager>((ref) {
  final fileStorage = ref.watch(fileStorageProvider);
  return SyncManifestManager(fileStorage: fileStorage);
});

final syncConflictResolverProvider = Provider<SyncConflictResolver>((ref) {
  return SyncConflictResolver();
});

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  () => SyncNotifier(),
);

class SyncNotifier extends Notifier<SyncState> {
  FileStorage get _fileStorage => ref.watch(fileStorageProvider);
  GitHubCredentialsService get _credentials =>
      ref.watch(githubCredentialsProvider);
  SyncService get _syncService => ref.watch(syncServiceProvider);
  SyncRepository get _repository => ref.watch(syncRepositoryProvider);
  SyncManifestManager get _manifestManager =>
      ref.watch(syncManifestManagerProvider);
  SyncConflictResolver get _conflictResolver =>
      ref.watch(syncConflictResolverProvider);

  PullOperation get _pullOperation => PullOperation(
    syncService: _syncService,
    repository: _repository,
    manifestManager: _manifestManager,
    conflictResolver: _conflictResolver,
  );

  PushOperation get _pushOperation => PushOperation(
    syncService: _syncService,
    repository: _repository,
    manifestManager: _manifestManager,
  );

  @override
  SyncState build() {
    final configJson = _fileStorage.getString(_syncConfigKey);
    final config = configJson != null
        ? SyncConfig.fromJson(jsonDecode(configJson) as Map<String, dynamic>)
        : null;

    final lastSyncedAtStr = _fileStorage.getString(_syncLastAtKey);
    final lastSyncedAt = lastSyncedAtStr != null
        ? DateTime.tryParse(lastSyncedAtStr)
        : null;

    return SyncState(
      status: SyncStatus.idle,
      config: config,
      lastSyncedAt: lastSyncedAt,
      lastSyncedCommitSha: _fileStorage.getString(_syncLastShaKey),
    );
  }

  Future<void> configure(SyncConfig config) async {
    await _fileStorage.setString(_syncConfigKey, jsonEncode(config.toJson()));
    state = state.copyWith(config: config);
  }

  Future<void> clearConfig() async {
    await _fileStorage.remove(_syncConfigKey);
    await _fileStorage.remove(_syncLastAtKey);
    await _fileStorage.remove(_syncLastShaKey);
    await _fileStorage.remove('sync_manifest');
    await _credentials.deleteToken();
    state = SyncState(status: SyncStatus.idle);
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

    final token = await _credentials.getToken();
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
      progress: const SyncProgress(message: 'Connecting to GitHub...'),
    );

    try {
      final result = await _pullOperation.execute(
        config: config,
        token: token,
        lastSyncedCommitSha: state.lastSyncedCommitSha,
        onProgress: (message, current, total) {
          state = state.copyWith(
            progress: SyncProgress(
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

    final token = await _credentials.getToken();
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
      progress: const SyncProgress(message: 'Connecting to GitHub...'),
    );

    try {
      final result = await _pushOperation.execute(
        config: config,
        token: token,
        lastSyncedCommitSha: state.lastSyncedCommitSha,
        onProgress: (message, current, total) {
          state = state.copyWith(
            progress: SyncProgress(
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
