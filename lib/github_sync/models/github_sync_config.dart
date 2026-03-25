import 'package:equatable/equatable.dart';

class GithubSyncConfig extends Equatable {
  final String owner;
  final String repo;
  final String branch;
  final String? subdirectory;

  const GithubSyncConfig({
    required this.owner,
    required this.repo,
    required this.branch,
    this.subdirectory,
  });

  GithubSyncConfig copyWith({
    String? owner,
    String? repo,
    String? branch,
    String? subdirectory,
  }) {
    return GithubSyncConfig(
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      branch: branch ?? this.branch,
      subdirectory: subdirectory ?? this.subdirectory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': owner,
      'repo': repo,
      'branch': branch,
      'subdirectory': subdirectory,
    };
  }

  factory GithubSyncConfig.fromJson(Map<String, dynamic> json) {
    return GithubSyncConfig(
      owner: json['owner'] as String,
      repo: json['repo'] as String,
      branch: json['branch'] as String,
      subdirectory: json['subdirectory'] as String?,
    );
  }

  @override
  List<Object?> get props => [owner, repo, branch, subdirectory];
}
