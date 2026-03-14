import 'dart:convert';
import 'dart:io';

import 'package:contextchat/projects/projects.model.dart';
import 'package:path/path.dart';

import 'database_filesystem.dart';

class ProjectDatabaseService {
  ProjectDatabaseService(this._filesystem);

  final DatabaseFilesystem _filesystem;

  Future<List<Project>> getAllProjects() async {
    final projects = <Project>[];
    if (!await _filesystem.projectsDirectory.exists()) {
      return projects;
    }

    final directories = await _filesystem.projectsDirectory
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
    directories.sort(
      (left, right) => basename(left.path).compareTo(basename(right.path)),
    );

    for (final directory in directories) {
      final project = await _readProject(directory);
      if (project != null) {
        projects.add(project);
      }
    }

    return projects;
  }

  Future<void> saveProject(Project project) async {
    final directory = _filesystem.projectDirectory(project.id);
    final metadataFile = _filesystem.projectMetadataFile(project.id);
    final memoryFile = _filesystem.projectMemoryFile(project.id);
    final contextDirectory = _filesystem.projectContextDirectory(project.id);

    await directory.create(recursive: true);
    await contextDirectory.create(recursive: true);

    await _filesystem.writeJsonAtomic(metadataFile, project.toMetadataMap());
    await _filesystem.writeStringAtomic(memoryFile, project.baseContext);
  }

  Future<void> deleteProject(String id) async {
    final directory = _filesystem.projectDirectory(id);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> deleteProjectStorage(String id) async {
    await deleteProject(id);
  }

  Future<ProjectFile> importProjectFile(
    String projectId,
    File source, {
    String? displayName,
  }) async {
    final contextDirectory = _filesystem.projectContextDirectory(projectId);
    await contextDirectory.create(recursive: true);

    final rawName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : basename(source.path);
    final sanitizedName = rawName.isEmpty ? 'file' : rawName;
    final uniqueName = await _uniqueFileName(contextDirectory, sanitizedName);
    final destination = File(join(contextDirectory.path, uniqueName));
    await source.copy(destination.path);

    final sizeBytes = await destination.length();

    return ProjectFile(
      id: '${DateTime.now().millisecondsSinceEpoch}-${destination.path.hashCode}',
      name: sanitizedName,
      filename: uniqueName,
      sizeBytes: sizeBytes,
    );
  }

  Future<void> deleteProjectFile(String projectId, ProjectFile file) async {
    final target = File(
      join(_filesystem.projectContextDirectory(projectId).path, file.filename),
    );
    if (await target.exists()) {
      await target.delete();
    }
  }

  Future<String?> readProjectFileContents(
    String projectId,
    ProjectFile file,
  ) async {
    final bytes = await readProjectFileBytes(projectId, file);
    if (bytes == null) {
      return null;
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<List<int>?> readProjectFileBytes(
    String projectId,
    ProjectFile file,
  ) async {
    final target = File(
      join(_filesystem.projectContextDirectory(projectId).path, file.filename),
    );
    if (!await target.exists()) {
      return null;
    }

    return target.readAsBytes();
  }

  Future<Project?> _readProject(Directory directory) async {
    final metadataFile = File(join(directory.path, 'project.json'));
    if (!await metadataFile.exists()) {
      return null;
    }

    final metadata = json.decode(await metadataFile.readAsString());
    if (metadata is! Map<String, dynamic>) {
      throw const FormatException('Invalid project metadata format');
    }

    final memoryFile = File(join(directory.path, 'MEMORY.md'));
    final baseContext = await memoryFile.exists()
        ? await memoryFile.readAsString()
        : '';

    final files = <ProjectFile>[];
    if (metadata['files'] is List) {
      for (final entry in metadata['files'] as List<dynamic>) {
        if (entry is Map) {
          files.add(ProjectFile.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return Project(
      id: metadata['id'] as String,
      name: metadata['name'] as String,
      baseContext: baseContext,
      files: files,
      defaultModelId: metadata['defaultModelId'] as String?,
    );
  }

  Future<String> _uniqueFileName(Directory directory, String name) async {
    final baseName = basenameWithoutExtension(name);
    final extensionName = extension(name);
    var candidate = '$baseName$extensionName';
    var counter = 1;
    while (await File(join(directory.path, candidate)).exists()) {
      candidate = '$baseName-$counter$extensionName';
      counter += 1;
    }
    return candidate;
  }
}
