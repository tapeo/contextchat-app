import 'package:equatable/equatable.dart';

class GithubSyncProgress extends Equatable {
  final String message;
  final int? current;
  final int? total;
  final Map<String, int>? stats; // e.g., {'downloaded': 5, 'skipped': 10}

  const GithubSyncProgress({
    required this.message,
    this.current,
    this.total,
    this.stats,
  });

  String get displayMessage {
    if (stats != null && stats!.isNotEmpty) {
      final statParts = <String>[];
      if (stats!['downloaded'] != null) {
        statParts.add('${stats!['downloaded']} downloaded');
      }
      if (stats!['skipped'] != null) {
        statParts.add('${stats!['skipped']} skipped');
      }
      if (stats!['deleted'] != null) {
        statParts.add('${stats!['deleted']} deleted');
      }
      if (stats!['uploaded'] != null) {
        statParts.add('${stats!['uploaded']} uploaded');
      }
      if (stats!['conflicts'] != null) {
        statParts.add('${stats!['conflicts']} conflicts');
      }
      if (statParts.isNotEmpty) {
        return '$message (${statParts.join(', ')})';
      }
    }
    if (current != null && total != null) {
      return '$message ($current/$total)';
    }
    return message;
  }

  GithubSyncProgress copyWith({
    String? message,
    int? current,
    int? total,
    Map<String, int>? stats,
  }) {
    return GithubSyncProgress(
      message: message ?? this.message,
      current: current ?? this.current,
      total: total ?? this.total,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [message, current, total, stats];
}
