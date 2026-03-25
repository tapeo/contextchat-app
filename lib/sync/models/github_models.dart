import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class GitHubBranch extends Equatable {
  final String name;
  final String commitSha;
  final String treeSha;
  final DateTime? commitTimestamp;

  const GitHubBranch({
    required this.name,
    required this.commitSha,
    required this.treeSha,
    this.commitTimestamp,
  });

  @override
  List<Object?> get props => [name, commitSha, treeSha, commitTimestamp];
}

class GitHubTree extends Equatable {
  final String sha;
  final List<GitHubTreeEntry> entries;

  const GitHubTree({required this.sha, required this.entries});

  @override
  List<Object?> get props => [sha, entries];
}

class GitHubTreeEntry extends Equatable {
  final String path;
  final String mode;
  final String type;
  final String? sha;
  final int? size;

  const GitHubTreeEntry({
    required this.path,
    required this.mode,
    required this.type,
    this.sha,
    this.size,
  });

  @override
  List<Object?> get props => [path, mode, type, sha, size];
}

class GitHubBlob extends Equatable {
  final String sha;
  final String content;
  final String encoding;
  final int size;

  const GitHubBlob({
    required this.sha,
    required this.content,
    required this.encoding,
    required this.size,
  });

  Uint8List get decodedContent {
    if (encoding == 'base64') {
      return base64Decode(content.replaceAll('\n', ''));
    }
    return Uint8List.fromList(utf8.encode(content));
  }

  @override
  List<Object?> get props => [sha, content, encoding, size];
}
