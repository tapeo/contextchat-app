import 'package:contextchat/sync/models/sync_config.dart';
import 'package:equatable/equatable.dart';

import 'models/enums.dart';
import 'models/sync_progress.dart';

class SyncState extends Equatable {
  final SyncStatus status;
  final String? error;
  final DateTime? lastSyncedAt;
  final String? lastSyncedCommitSha;
  final SyncConfig? config;
  final SyncProgress? progress;

  const SyncState({
    this.status = SyncStatus.idle,
    this.error,
    this.lastSyncedAt,
    this.lastSyncedCommitSha,
    this.config,
    this.progress,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? error,
    DateTime? lastSyncedAt,
    String? lastSyncedCommitSha,
    SyncConfig? config,
    SyncProgress? progress,
  }) {
    return SyncState(
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

  factory SyncState.fromJson(Map<String, dynamic> json) {
    return SyncState(
      status: SyncStatus.values.byName(json['status'] as String),
      error: json['error'] as String?,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      lastSyncedCommitSha: json['lastSyncedCommitSha'] as String?,
      config: json['config'] != null
          ? SyncConfig.fromJson(json['config'] as Map<String, dynamic>)
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
