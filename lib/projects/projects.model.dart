import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final String baseContext;
  final List<ProjectFile> files;
  final String? defaultModelId;

  const Project({
    required this.id,
    required this.name,
    required this.baseContext,
    this.files = const [],
    this.defaultModelId,
  });

  Project copyWith({
    String? id,
    String? name,
    String? baseContext,
    List<ProjectFile>? files,
    String? defaultModelId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      baseContext: baseContext ?? this.baseContext,
      files: files ?? this.files,
      defaultModelId: defaultModelId ?? this.defaultModelId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseContext': baseContext,
      'files': files.map((file) => file.toJson()).toList(),
      'defaultModelId': defaultModelId,
    };
  }

  Map<String, dynamic> toMetadataMap() {
    return {
      'id': id,
      'name': name,
      'files': files.map((file) => file.toJson()).toList(),
      'defaultModelId': defaultModelId,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final files = <ProjectFile>[];
    if (json['files'] is List) {
      for (final entry in json['files'] as List<dynamic>) {
        if (entry is Map) {
          files.add(ProjectFile.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return Project(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Untitled Project',
      baseContext: (json['baseContext'] as String?) ?? '',
      files: files,
      defaultModelId: json['defaultModelId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, baseContext, files, defaultModelId];
}

class ProjectFile extends Equatable {
  final String id;
  final String name;
  final String filename;
  final int sizeBytes;

  const ProjectFile({
    required this.id,
    required this.name,
    required this.filename,
    required this.sizeBytes,
  });

  ProjectFile copyWith({
    String? id,
    String? name,
    String? filename,
    int? sizeBytes,
  }) {
    return ProjectFile(
      id: id ?? this.id,
      name: name ?? this.name,
      filename: filename ?? this.filename,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filename': filename,
      'sizeBytes': sizeBytes,
    };
  }

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      filename: (json['filename'] as String?) ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, filename, sizeBytes];
}
