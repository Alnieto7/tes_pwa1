import 'package:flutter_test/flutter_test.dart';
import 'package:tes_pwa1/controllers/project_controller.dart';

void main() {
  late ProjectController controller;

  setUp(() {
    controller = ProjectController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('loads project data and derives dashboard metrics', () async {
    await controller.refresh();

    expect(controller.totalProjectCount, 3);
    expect(controller.activeProjectCount, 2);
    expect(controller.completedProjectCount, 0);
    expect(controller.averageProgress, closeTo(0.4533, 0.0001));
  });

  test('adds a trimmed project and notifies listeners', () async {
    await controller.refresh();
    var notificationCount = 0;
    controller.addListener(() => notificationCount++);

    expect(await controller.addProject('  Project Gamma  '), isTrue);

    expect(controller.projects.first.name, 'Project Gamma');
    expect(controller.totalProjectCount, 4);
    expect(notificationCount, 2);
  });

  test('does not add an empty project name', () async {
    await controller.refresh();
    var notificationCount = 0;
    controller.addListener(() => notificationCount++);

    expect(await controller.addProject('   '), isFalse);

    expect(controller.totalProjectCount, 3);
    expect(notificationCount, 0);
  });

  test('updates and deletes projects through the repository', () async {
    await controller.refresh();
    final original = controller.projects.first;

    expect(
      await controller.updateProject(
        original.copyWith(status: 'Completed', progress: 1),
      ),
      isTrue,
    );
    expect(controller.projects.first.status, 'Completed');

    expect(await controller.deleteProject(original.id!), isTrue);
    expect(controller.projects, hasLength(2));
    expect(
      controller.projects.any((project) => project.id == original.id),
      isFalse,
    );
  });
}
