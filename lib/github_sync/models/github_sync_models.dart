import 'package:equatable/equatable.dart';

class GithubCompareResult extends Equatable {
  final String status;
  final int aheadBy;
  final int behindBy;
  final int totalCommits;
  final List<GithubCommitInfo> commits;
  final List<GithubFileChange> files;

  const GithubCompareResult({
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

class GithubCommitInfo extends Equatable {
  final String sha;
  final String message;
  final DateTime? date;
  final String? author;

  const GithubCommitInfo({
    required this.sha,
    required this.message,
    this.date,
    this.author,
  });

  @override
  List<Object?> get props => [sha, message, date, author];
}

class GithubFileChange extends Equatable {
  final String path;
  final String status;
  final int? additions;
  final int? deletions;
  final int? changes;

  const GithubFileChange({
    required this.path,
    required this.status,
    this.additions,
    this.deletions,
    this.changes,
  });

  @override
  List<Object?> get props => [path, status, additions, deletions, changes];
}
