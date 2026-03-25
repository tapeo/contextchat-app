/// Resolves conflicts using last-write-wins strategy
class SyncConflictResolver {
  /// Resolves conflict using last-write-wins strategy
  /// Returns true if local wins, false if remote wins
  bool resolve({
    required DateTime localModified,
    required DateTime? remoteUpdated,
    required String localPath,
    required String remotePath,
  }) {
    // If remote update time is unknown, use current time as fallback
    final effectiveRemoteTime = remoteUpdated ?? DateTime.now();

    // Clock skew safeguard: if times are within 1 second, use deterministic tie-breaker
    final timeDiff = localModified.difference(effectiveRemoteTime).abs();
    if (timeDiff.inSeconds <= 1) {
      // Deterministic tie-breaker: lexicographically smaller path wins
      // This prevents flip-flopping when clocks are synchronized
      return localPath.compareTo(remotePath) <= 0;
    }

    // Last-write-wins: local wins if it's newer
    return localModified.isAfter(effectiveRemoteTime);
  }
}
