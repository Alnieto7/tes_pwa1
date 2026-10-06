import 'package:flutter/material.dart';

import '../models/project.dart';
import '../repositories/mock_project_repository.dart';
import '../repositories/project_repository.dart';

enum ProjectControllerState { loading, success, empty, error }

class ProjectController extends ChangeNotifier {
  ProjectController({ProjectRepository? repository})
    : _repository = repository ?? MockProjectRepository();

  final ProjectRepository _repository;
  List<Project> _projects = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProjectControllerState get state {
    if (_isLoading) return ProjectControllerState.loading;
    if (_errorMessage != null) return ProjectControllerState.error;
    return _projects.isEmpty
        ? ProjectControllerState.empty
        : ProjectControllerState.success;
  }

  List<Project> get activeProjects =>
      _projects.where((project) => project.status == 'Active').toList();

  int get totalProjectCount => _projects.length;
  int get activeProjectCount => activeProjects.length;
  int get completedProjectCount =>
      _projects.where((project) => project.status == 'Completed').length;

  double get averageProgress {
    if (_projects.isEmpty) return 0;

    final totalProgress = _projects.fold<double>(
      0,
      (total, project) => total + project.progress,
    );
    return totalProgress / _projects.length;
  }

  Future<void> refresh() async {
    _beginRequest();
    try {
      _projects = await _repository.getProjects();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _finishRequest();
    }
  }

  Future<bool> addProject(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return false;

    _beginRequest();
    try {
      final project = await _repository.createProject(
        Project(
          name: normalizedName,
          client: '',
          status: 'Planning',
          progress: 0,
          color: const Color(0xFF3157D5),
        ),
      );
      _projects = [project, ..._projects];
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> updateProject(Project project) async {
    _beginRequest();
    try {
      final updatedProject = await _repository.updateProject(project);
      _projects = [
        for (final current in _projects)
          if (current.id == updatedProject.id) updatedProject else current,
      ];
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> deleteProject(String id) async {
    _beginRequest();
    try {
      await _repository.deleteProject(id);
      _projects = _projects.where((project) => project.id != id).toList();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishRequest();
    }
  }

  void _beginRequest() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    notifyListeners();
  }
}
