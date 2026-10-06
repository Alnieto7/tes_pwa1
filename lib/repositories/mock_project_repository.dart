import 'package:flutter/material.dart';

import '../models/project.dart';
import 'project_repository.dart';

class MockProjectRepository implements ProjectRepository {
  final List<Project> _projects = [
    const Project(
      id: '1',
      name: 'Project Alpha',
      client: 'Acme Studio',
      status: 'Active',
      progress: 0.72,
      color: Color(0xFF3157D5),
    ),
    const Project(
      id: '2',
      name: 'Website Redesign',
      client: 'Northstar Co.',
      status: 'Active',
      progress: 0.46,
      color: Color(0xFF21A179),
    ),
    const Project(
      id: '3',
      name: 'Mobile App Launch',
      client: 'Bright Labs',
      status: 'Planning',
      progress: 0.18,
      color: Color(0xFFDE9B2D),
    ),
  ];
  var _nextId = 4;

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(_projects);

  @override
  Future<Project> getProjectById(String id) async =>
      _projects.firstWhere((project) => project.id == id);

  @override
  Future<Project> createProject(Project project) async {
    final created = project.copyWith(
      id: (_nextId++).toString(),
      client: project.client.isEmpty ? 'New client' : project.client,
    );
    _projects.insert(0, created);
    return created;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index < 0) {
      throw StateError('Project ${project.id} was not found.');
    }
    _projects[index] = project;
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index < 0) {
      throw StateError('Project $id was not found.');
    }
    _projects.removeAt(index);
  }
}
