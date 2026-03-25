import 'package:contextchat/github_sync/models/github_sync_manifest.dart';
import 'package:equatable/equatable.dart';

class GithubPullOperationResult extends Equatable {
  final int downloaded;
  final int skipped;
  final int deleted;
  final int conflicts;
  final List<String> conflictedFiles;
  final String? commitSha;
  final DateTime? syncedAt;
  final GithubSyncManifest? manifest;

  const GithubPullOperationResult({
    required this.downloaded,
    required this.skipped,
    required this.deleted,
    required this.conflicts,
    required this.conflictedFiles,
    this.commitSha,
    this.syncedAt,
    this.manifest,
  });

  @override
  List<Object?> get props => [
    downloaded,
    skipped,
    deleted,
    conflicts,
    conflictedFiles,
    commitSha,
    syncedAt,
    manifest,
  ];
}

class PushOperationResult extends Equatable {
  final int uploaded;
  final int skipped;
  final int deleted;
  final int conflicts;
  final List<String> conflictedFiles;
  final String? commitSha;
  final DateTime? syncedAt;
  final GithubSyncManifest? manifest;

  const PushOperationResult({
    required this.uploaded,
    required this.skipped,
    required this.deleted,
    required this.conflicts,
    required this.conflictedFiles,
    this.commitSha,
    this.syncedAt,
    this.manifest,
  });

  @override
  List<Object?> get props => [
    uploaded,
    skipped,
    deleted,
    conflicts,
    conflictedFiles,
    commitSha,
    syncedAt,
    manifest,
  ];
}
