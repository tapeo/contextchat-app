import 'package:equatable/equatable.dart';

class CompareResult extends Equatable {
  final String status;
  final int aheadBy;
  final int behindBy;
  final int totalCommits;
  final List<CommitInfo> commits;
  final List<FileChange> files;

  const CompareResult({
    required this.status,
    required this.aheadBy,
    required this.behindBy,
    required this.totalCommits,
    required this.commits,
    required this.files,
  });

  @override
  List<Object?> get props => [
    status,
    aheadBy,
    behindBy,
    totalCommits,
    commits,
    files,
  ];
}

class CommitInfo extends Equatable {
  final String sha;
  final String message;
  final DateTime? date;
  final String? author;

  const CommitInfo({
    required this.sha,
    required this.message,
    this.date,
    this.author,
  });

  @override
  List<Object?> get props => [sha, message, date, author];
}

class FileChange extends Equatable {
  final String path;
  final String status;
  final int? additions;
  final int? deletions;
  final int? changes;

  const FileChange({
    required this.path,
    required this.status,
    this.additions,
    this.deletions,
    this.changes,
  });

  @override
  List<Object?> get props => [path, status, additions, deletions, changes];
}
