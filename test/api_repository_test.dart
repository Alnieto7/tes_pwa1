import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tes_pwa1/models/project.dart';
import 'package:tes_pwa1/repositories/api_project_repository.dart';
import 'package:tes_pwa1/repositories/auth_repository.dart';
import 'package:tes_pwa1/services/api_service.dart';

void main() {
  test('uses the shared API for auth and project CRUD', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final responseData =
              switch ('${options.method} ${options.uri.path}') {
                'POST /api/login' => {
                  'token': 'test-token',
                  'owner': {'id': 7, 'name': 'Budi Santoso'},
                },
                'GET /api/projects' => {
                  'data': [
                    {
                      'id': 1,
                      'name': 'Project Alpha',
                      'client': 'Acme Studio',
                      'status': 'Active',
                      'progress': 72,
                    },
                  ],
                },
                'GET /api/projects/1' => {
                  'data': {
                    'id': 1,
                    'name': 'Project Alpha',
                    'client': 'Acme Studio',
                    'status': 'Active',
                    'progress': 0.72,
                  },
                },
                'POST /api/projects' => {
                  'data': {
                    'id': 2,
                    'name': 'Project Beta',
                    'client': 'Northstar',
                    'status': 'Planning',
                    'progress': 0,
                  },
                },
                'PUT /api/projects/2' => {
                  'data': {
                    'id': 2,
                    'name': 'Project Beta',
                    'client': 'Northstar',
                    'status': 'Completed',
                    'progress': 1,
                  },
                },
                _ => null,
              };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: responseData,
              statusCode: 200,
            ),
          );
        },
      ),
    );
    final apiService = ApiService(dio: dio);

    final session = await AuthRepository(
      apiService: apiService,
    ).login(email: 'budi@example.test', password: 'secret');
    expect(session.owner.name, 'Budi Santoso');

    final repository = ApiProjectRepository(apiService);
    final projects = await repository.getProjects();
    expect(projects.single.progress, 0.72);
    expect((await repository.getProjectById('1')).id, '1');

    final created = await repository.createProject(
      const Project(
        name: 'Project Beta',
        client: 'Northstar',
        status: 'Planning',
        progress: 0,
        color: Color(0xFF3157D5),
      ),
    );
    final updated = await repository.updateProject(
      created.copyWith(status: 'Completed', progress: 1),
    );
    await repository.deleteProject(updated.id!);

    expect(requests.map((request) => '${request.method} ${request.uri.path}'), [
      'POST /api/login',
      'GET /api/projects',
      'GET /api/projects/1',
      'POST /api/projects',
      'PUT /api/projects/2',
      'DELETE /api/projects/2',
    ]);
    expect(requests.first.headers['Authorization'], isNull);
    for (final request in requests.skip(1)) {
      expect(request.headers['Authorization'], 'Bearer test-token');
    }
  });
}
