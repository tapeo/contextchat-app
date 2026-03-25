import 'package:contextchat/github_sync/models/github_sync_config.dart';
import 'package:equatable/equatable.dart';

import 'models/enums.dart';
import 'models/github_sync_progress.dart';

class GithubSyncState extends Equatable {
  final SyncStatus status;
  final String? error;
  final DateTime? lastSyncedAt;
  final String? lastSyncedCommitSha;
  final GithubSyncConfig? config;
  final GithubSyncProgress? progress;

  const GithubSyncState({
    this.status = SyncStatus.idle,
    this.error,
    this.lastSyncedAt,
    this.lastSyncedCommitSha,
    this.config,
    this.progress,
  });

  GithubSyncState copyWith({
    SyncStatus? status,
    String? error,
    DateTime? lastSyncedAt,
    String? lastSyncedCommitSha,
    GithubSyncConfig? config,
    GithubSyncProgress? progress,
  }) {
    return GithubSyncState(
      status: status ?? this.status,
      error: error ?? this.error,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncedCommitSha: lastSyncedCommitSha ?? this.lastSyncedCommitSha,
      config: config ?? this.config,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'error': error,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'lastSyncedCommitSha': lastSyncedCommitSha,
      'config': config?.toJson(),
    };
  }

  factory GithubSyncState.fromJson(Map<String, dynamic> json) {
    return GithubSyncState(
      status: SyncStatus.values.byName(json['status'] as String),
      error: json['error'] as String?,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      lastSyncedCommitSha: json['lastSyncedCommitSha'] as String?,
      config: json['config'] != null
          ? GithubSyncConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    lastSyncedAt,
    lastSyncedCommitSha,
    config,
    progress,
  ];
}
