import 'dart:io';

import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/projects/projects.model.dart';
import 'package:contextchat/projects/projects.state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _currentProjectIdKey = 'current_project_id';

final projectsProvider = NotifierProvider<ProjectsNotifier, ProjectsState>(
  () => ProjectsNotifier(),
);

class ProjectsNotifier extends Notifier<ProjectsState> {
  ProjectDatabaseService get databaseService =>
      ref.watch(projectDatabaseProvider);

  FileStorage get _fileStorage => ref.watch(fileStorageProvider);

  @override
  ProjectsState build() {
    return ProjectsState(projects: []);
  }

  Future<void> initialize() async {
    final projects = await databaseService.getAllProjects();
    final savedProjectId = _fileStorage.getString(_currentProjectIdKey);

    String? currentProjectId;

    if (savedProjectId != null && projects.any((p) => p.id == savedProjectId)) {
      currentProjectId = savedProjectId;
    } else if (projects.isNotEmpty) {
      currentProjectId = projects.first.id;
    }

    state = ProjectsState(
      projects: projects,
      currentProjectId: currentProjectId,
    );
  }

  Future<void> createProject(String name, String baseContext) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final project = Project(id: id, name: name, baseContext: baseContext);
    state = state.copyWith(projects: [...state.projects, project]);
    await databaseService.saveProject(project);
  }

  Future<Project> createProjectWithFiles({
    required String id,
    required String name,
    required String baseContext,
    List<ProjectFile> files = const [],
  }) async {
    final project = Project(
      id: id,
      name: name,
      baseContext: baseContext,
      files: _sortFiles(files),
    );
    state = state.copyWith(projects: [...state.projects, project]);
    await databaseService.saveProject(project);
    return project;
  }

  Future<void> deleteProject(String id) async {
    await ref.read(chatsProvider.notifier).deleteChatsForProject(id);

    state = state.copyWith(
      projects: state.projects.where((p) => p.id != id).toList(),
      currentProjectId: state.currentProjectId == id
          ? null
          : state.currentProjectId,
    );

    await databaseService.deleteProject(id);
  }

  Future<void> editProject(
    String id, {
    String? name,
    String? baseContext,
    List<ProjectFile>? files,
  }) async {
    Project? updatedProject;

    final updatedProjects = state.projects.map((p) {
      if (p.id == id) {
        final updated = p.copyWith(
          name: name,
          baseContext: baseContext,
          files: files != null ? _sortFiles(files) : null,
        );
        updatedProject = updated;
        return updated;
      }
      return p;
    }).toList();

    state = state.copyWith(projects: updatedProjects);

    if (updatedProject != null) {
      await databaseService.saveProject(updatedProject!);
    }
  }

  Future<List<ProjectFile>> importProjectFiles(
    String projectId,
    List<File> files, {
    List<String>? displayNames,
    bool updateState = true,
  }) async {
    final addedFiles = <ProjectFile>[];

    for (var index = 0; index < files.length; index++) {
      final displayName = displayNames != null && index < displayNames.length
          ? displayNames[index]
          : null;
      final imported = await databaseService.importProjectFile(
        projectId,
        files[index],
        displayName: displayName,
      );
      addedFiles.add(imported);
    }

    if (updateState) {
      final project = state.projects.firstWhere((p) => p.id == projectId);
      final updated = project.copyWith(
        files: _sortFiles([...project.files, ...addedFiles]),
      );
      state = state.copyWith(
        projects: [
          for (final p in state.projects) p.id == projectId ? updated : p,
        ],
      );
      await databaseService.saveProject(updated);
    }

    return addedFiles;
  }

  Future<void> removeProjectFile(String projectId, ProjectFile file) async {
    await databaseService.deleteProjectFile(projectId, file);
    final project = state.projects.firstWhere((p) => p.id == projectId);
    final updated = project.copyWith(
      files: _sortFiles(
        project.files.where((item) => item.id != file.id).toList(),
      ),
    );
    state = state.copyWith(
      projects: [
        for (final p in state.projects) p.id == projectId ? updated : p,
      ],
    );
    await databaseService.saveProject(updated);
  }

  Future<void> selectProject(String id) async {
    state = state.copyWith(currentProjectId: id);
    await _fileStorage.setString(_currentProjectIdKey, id);
  }

  Future<void> setProjectDefaultModel(String projectId, String? modelId) async {
    Project? updatedProject;

    final updatedProjects = state.projects.map((p) {
      if (p.id == projectId) {
        final updated = p.copyWith(defaultModelId: modelId);
        updatedProject = updated;
        return updated;
      }
      return p;
    }).toList();

    state = state.copyWith(projects: updatedProjects);

    if (updatedProject != null) {
      await databaseService.saveProject(updatedProject!);
    }
  }

  List<ProjectFile> _sortFiles(List<ProjectFile> files) {
    final sorted = [...files];
    sorted.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sorted;
  }
}
