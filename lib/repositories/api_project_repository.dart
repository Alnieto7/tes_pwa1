import '../models/project.dart';
import '../services/api_service.dart';
import 'project_repository.dart';

class ApiProjectRepository implements ProjectRepository {
  ApiProjectRepository(this._apiService);

  final ApiService _apiService;
  static const _endpoint = 'projects';

  @override
  Future<List<Project>> getProjects() async {
    final response = await _apiService.get(_endpoint);
    final data = response is Map<String, dynamic> ? response['data'] : response;
    if (data is! List) {
      throw const FormatException(
        'Invalid projects response: expected a JSON array or data array.',
      );
    }
    return data
        .map((item) => Project.fromJson(_asProjectJson(item)))
        .toList(growable: false);
  }

  @override
  Future<Project> getProjectById(String id) async {
    final response = await _apiService.get(
      '$_endpoint/${Uri.encodeComponent(id)}',
    );
    return Project.fromJson(_asProjectJson(response));
  }

  @override
  Future<Project> createProject(Project project) async {
    final response = await _apiService.post(_endpoint, data: project.toJson());
    return Project.fromJson(_asProjectJson(response));
  }

  @override
  Future<Project> updateProject(Project project) async {
    final id = project.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError.value(id, 'project.id', 'An ID is required to update.');
    }
    final response = await _apiService.put(
      '$_endpoint/${Uri.encodeComponent(id)}',
      data: project.toJson(),
    );
    if (response == null || response is Map && response.isEmpty) return project;
    return Project.fromJson(_asProjectJson(response));
  }

  @override
  Future<void> deleteProject(String id) async {
    await _apiService.delete('$_endpoint/${Uri.encodeComponent(id)}');
  }

  Map<String, dynamic> _asProjectJson(Object? response) {
    final data = response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! Map) {
      throw const FormatException('Invalid project response: expected an object.');
    }
    return Map<String, dynamic>.from(data);
  }
}
