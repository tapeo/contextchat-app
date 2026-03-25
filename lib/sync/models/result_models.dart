import 'package:equatable/equatable.dart';

class SyncPullResult extends Equatable {
  final int downloaded;
  final int skipped;
  final int deleted;
  final int conflicts;
  final List<String> conflictedFiles;

  const SyncPullResult({
    required this.downloaded,
    required this.skipped,
    required this.deleted,
    required this.conflicts,
    required this.conflictedFiles,
  });

  @override
  List<Object?> get props => [
    downloaded,
    skipped,
    deleted,
    conflicts,
    conflictedFiles,
  ];
}

class SyncPushResult extends Equatable {
  final int uploaded;
  final int skipped;
  final int deleted;
  final int conflicts;
  final List<String> conflictedFiles;

  const SyncPushResult({
    required this.uploaded,
    required this.skipped,
    required this.deleted,
    required this.conflicts,
    required this.conflictedFiles,
  });

  @override
  List<Object?> get props => [
    uploaded,
    skipped,
    deleted,
    conflicts,
    conflictedFiles,
  ];
}

class RemoteFileInfo extends Equatable {
  final String path;
  final String sha;
  final int? size;

  const RemoteFileInfo({required this.path, required this.sha, this.size});

  @override
  List<Object?> get props => [path, sha, size];
}
