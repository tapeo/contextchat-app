import 'package:equatable/equatable.dart';

class GithubSyncManifest extends Equatable {
  final String version;
  final DateTime generatedAt;
  final List<SyncFileEntry> files;
  final Map<String, dynamic> syncedSettings;

  const GithubSyncManifest({
    required this.version,
    required this.generatedAt,
    required this.files,
    required this.syncedSettings,
  });

  GithubSyncManifest copyWith({
    String? version,
    DateTime? generatedAt,
    List<SyncFileEntry>? files,
    Map<String, dynamic>? syncedSettings,
  }) {
    return GithubSyncManifest(
      version: version ?? this.version,
      generatedAt: generatedAt ?? this.generatedAt,
      files: files ?? this.files,
      syncedSettings: syncedSettings ?? this.syncedSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generatedAt': generatedAt.toIso8601String(),
      'files': files.map((f) => f.toJson()).toList(),
      'syncedSettings': syncedSettings,
    };
  }

  factory GithubSyncManifest.fromJson(Map<String, dynamic> json) {
    return GithubSyncManifest(
      version: json['version'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      files: (json['files'] as List)
          .map((f) => SyncFileEntry.fromJson(f as Map<String, dynamic>))
          .toList(),
      syncedSettings: json['syncedSettings'] as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [version, generatedAt, files, syncedSettings];
}

class SyncFileEntry extends Equatable {
  final String path;
  final String sha256;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String? remoteBlobSha; // GitHub blob SHA for remote tracking

  const SyncFileEntry({
    required this.path,
    required this.sha256,
    required this.sizeBytes,
    required this.modifiedAt,
    this.remoteBlobSha,
  });

  SyncFileEntry copyWith({
    String? path,
    String? sha256,
    int? sizeBytes,
    DateTime? modifiedAt,
    String? remoteBlobSha,
  }) {
    return SyncFileEntry(
      path: path ?? this.path,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      remoteBlobSha: remoteBlobSha ?? this.remoteBlobSha,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'sha256': sha256,
      'sizeBytes': sizeBytes,
      'modifiedAt': modifiedAt.toIso8601String(),
      if (remoteBlobSha != null) 'remoteBlobSha': remoteBlobSha,
    };
  }

  factory SyncFileEntry.fromJson(Map<String, dynamic> json) {
    return SyncFileEntry(
      path: json['path'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: json['sizeBytes'] as int,
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      remoteBlobSha: json['remoteBlobSha'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    path,
    sha256,
    sizeBytes,
    modifiedAt,
    remoteBlobSha,
  ];
}
