import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tes_pwa1/main.dart';

void main() {
  testWidgets('shows the Project Owner dashboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProjectOwnerApp());
    await tester.pumpAndSettle();

    expect(find.text('Project Owner'), findsOneWidget);
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Total projects'), findsOneWidget);
    expect(find.text('Project progress'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Project Alpha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation opens the projects and account pages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProjectOwnerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    expect(find.text('Keep track of your team’s work in one place.'), findsOne);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a project from the mobile dashboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProjectOwnerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Project Gamma');
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    expect(find.text('Project Gamma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits and deletes projects from the projects page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProjectOwnerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Project actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit project').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Edited Alpha');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edited Alpha'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.byTooltip('Project actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete project').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Edited Alpha'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360, 375, 390, 412, 430, 768, 1024, 1440]) {
    testWidgets('renders without overflow at $width px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width.toDouble(), 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ProjectOwnerApp());
      await tester.pumpAndSettle();
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Keep track of your team’s work in one place.'),
        findsOne,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Owner ID'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
