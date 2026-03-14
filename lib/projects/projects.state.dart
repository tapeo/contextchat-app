import 'package:contextchat/projects/projects.model.dart';
import 'package:equatable/equatable.dart';

const _currentProjectIdUnset = Object();

class ProjectsState extends Equatable {
  final List<Project> projects;
  final String? currentProjectId;

  const ProjectsState({required this.projects, this.currentProjectId});

  ProjectsState copyWith({
    List<Project>? projects,
    Object? currentProjectId = _currentProjectIdUnset,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      currentProjectId: identical(currentProjectId, _currentProjectIdUnset)
          ? this.currentProjectId
          : currentProjectId as String?,
    );
  }

  @override
  List<Object?> get props => [projects, currentProjectId];
}
