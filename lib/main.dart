import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/project_controller.dart';
import 'models/project.dart';
import 'repositories/api_project_repository.dart';
import 'repositories/mock_project_repository.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ProjectOwnerApp());
}

enum _ProjectCardAction { edit, delete }

const _brandColor = Color(0xFF3157D5);
const _pageBackground = Color(0xFFF6F7FB);

class ProjectOwnerApp extends StatelessWidget {
  const ProjectOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _brandColor),
        scaffoldBackgroundColor: _pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9EBF2)),
          ),
        ),
      ),
      home: const ProjectOwnerHome(),
    );
  }
}

class ProjectOwnerHome extends StatefulWidget {
  const ProjectOwnerHome({super.key});

  @override
  State<ProjectOwnerHome> createState() => _ProjectOwnerHomeState();
}

class _ProjectOwnerHomeState extends State<ProjectOwnerHome> {
  late final ProjectController _projectController;
  int _selectedDestination = 0;

  @override
  void initState() {
    super.initState();
    final repository = apiBaseUrl.trim().isEmpty
        ? MockProjectRepository()
        : ApiProjectRepository(ApiService.shared);
    _projectController = ProjectController(repository: repository);
    unawaited(_projectController.refresh());
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    final projectName = await showDialog<String>(
      context: context,
      builder: (context) {
        var enteredProjectName = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Create a project'),
            content: TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'e.g. Website refresh',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
              onChanged: (value) =>
                  setDialogState(() => enteredProjectName = value.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(enteredProjectName),
                child: const Text('Create project'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || projectName == null || projectName.isEmpty) return;
    final created = await _projectController.addProject(projectName);
    if (!created && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _projectController.errorMessage ?? 'Unable to create project.',
          ),
        ),
      );
    }
  }

  Future<void> _refreshProjects() => _projectController.refresh();

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
    if (index != 2) _refreshProjects();
  }

  Future<void> _editProject(Project project) async {
    final updatedProject = await showDialog<Project>(
      context: context,
      builder: (context) {
        var name = project.name;
        var status = project.status;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit project'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: project.name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Project name'),
                  onChanged: (value) => name = value.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    if (!['Planning', 'Active', 'Completed'].contains(status))
                      DropdownMenuItem(value: status, child: Text(status)),
                    const DropdownMenuItem(
                      value: 'Planning',
                      child: Text('Planning'),
                    ),
                    const DropdownMenuItem(
                      value: 'Active',
                      child: Text('Active'),
                    ),
                    const DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    Navigator.of(
                      context,
                    ).pop(project.copyWith(name: name, status: status));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || updatedProject == null) return;
    final updated = await _projectController.updateProject(updatedProject);
    if (!updated && mounted) _showProjectError('Unable to update project.');
  }

  Future<void> _deleteProject(Project project) async {
    final id = project.id;
    if (id == null) {
      _showProjectError('This project cannot be deleted because it has no ID.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${project.name}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final deleted = await _projectController.deleteProject(id);
    if (!deleted && mounted) _showProjectError('Unable to delete project.');
  }

  void _showProjectError(String fallbackMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_projectController.errorMessage ?? fallbackMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _projectController,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final page = _buildSelectedPage(isDesktop);
          final errorMessage = _projectController.errorMessage;

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 64,
              titleSpacing: constraints.maxWidth < 600 ? 16 : 28,
              title: const _BrandLockup(compact: true),
              actions: [
                if (isDesktop) ...[
                  _TopNavigation(
                    selectedIndex: _selectedDestination,
                    onSelected: _selectDestination,
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  tooltip: 'Refresh projects',
                  onPressed: _refreshProjects,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: const Color(0xFF555B68),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: const Color(0xFF555B68),
                  ),
                  icon: const Badge(
                    smallSize: 8,
                    child: Icon(Icons.notifications_none_rounded),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: constraints.maxWidth < 600 ? 12 : 24,
                    left: 4,
                  ),
                  child: _UserAvatar(onTap: () => _selectDestination(2)),
                ),
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                page,
                if (_projectController.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (errorMessage != null)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFFF3F0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFF9D2C1D),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _refreshProjects,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: isDesktop
                ? null
                : SafeArea(
                    top: false,
                    child: NavigationBar(
                      height: 64,
                      selectedIndex: _selectedDestination,
                      onDestinationSelected: _selectDestination,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.folder_outlined),
                          selectedIcon: Icon(Icons.folder_rounded),
                          label: 'Projects',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedPage(bool isDesktop) {
    switch (_selectedDestination) {
      case 1:
        return _ProjectsPage(
          projects: _projectController.projects,
          isDesktop: isDesktop,
          onAddProject: _addProject,
          onEditProject: _editProject,
          onDeleteProject: _deleteProject,
        );
      case 2:
        return const _AccountPage();
      default:
        return _DashboardPage(
          projects: _projectController.projects,
          activeProjects: _projectController.activeProjects,
          activeProjectCount: _projectController.activeProjectCount,
          completedProjectCount: _projectController.completedProjectCount,
          averageProgress: _projectController.averageProgress,
          isDesktop: isDesktop,
          onAddProject: _addProject,
          onViewAllProjects: () => _selectDestination(1),
        );
    }
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.projects,
    required this.activeProjects,
    required this.activeProjectCount,
    required this.completedProjectCount,
    required this.averageProgress,
    required this.isDesktop,
    required this.onAddProject,
    required this.onViewAllProjects,
  });

  final List<Project> projects;
  final List<Project> activeProjects;
  final int activeProjectCount;
  final int completedProjectCount;
  final double averageProgress;
  final bool isDesktop;
  final VoidCallback onAddProject;
  final VoidCallback onViewAllProjects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600
            ? 16.0
            : constraints.maxWidth < 1024
            ? 24.0
            : 32.0;
        final content = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            constraints.maxWidth < 600 ? 20 : 28,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeHeader(
                    activeProjectCount: activeProjectCount,
                    isDesktop: isDesktop,
                    onAddProject: onAddProject,
                  ),
                  const SizedBox(height: 24),
                  _StatsGrid(
                    totalProjects: projects.length,
                    activeProjects: activeProjectCount,
                    completedProjects: completedProjectCount,
                  ),
                  const SizedBox(height: 24),
                  _OverallProgressCard(progress: averageProgress),
                  const SizedBox(height: 28),
                  _SectionHeading(
                    title: 'Active projects',
                    actionLabel: 'View all',
                    onAction: onViewAllProjects,
                  ),
                  const SizedBox(height: 14),
                  if (activeProjects.isEmpty)
                    const _EmptyProjectsMessage()
                  else
                    _ProjectList(
                      projects: activeProjects.take(3).toList(),
                      compact: true,
                    ),
                  const SizedBox(height: 28),
                  const _RecentActivitySection(),
                ],
              ),
            ),
          ),
        );

        return ColoredBox(color: _pageBackground, child: content);
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.activeProjectCount,
    required this.isDesktop,
    required this.onAddProject,
  });

  final int activeProjectCount;
  final bool isDesktop;
  final VoidCallback onAddProject;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6C7180),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Budi Santoso',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have $activeProjectCount active ${activeProjectCount == 1 ? 'project' : 'projects'}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6C7180),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isDesktop)
          FilledButton.icon(
            onPressed: onAddProject,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New project'),
          )
        else
          IconButton.filledTonal(
            tooltip: 'New project',
            onPressed: onAddProject,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: _brandColor,
            ),
            icon: const Icon(Icons.add_rounded),
          ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
  });

  final int totalProjects;
  final int activeProjects;
  final int completedProjects;

  @override
  Widget build(BuildContext context) {
    const stats = [
      (
        label: 'Total projects',
        icon: Icons.folder_copy_outlined,
        color: Color(0xFF3157D5),
      ),
      (
        label: 'Active projects',
        icon: Icons.bolt_rounded,
        color: Color(0xFF21A179),
      ),
      (
        label: 'Completed',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF8759C7),
      ),
    ];
    final values = ['$totalProjects', '$activeProjects', '$completedProjects'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : 3;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 14) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(stats.length, (index) {
            final stat = stats[index];
            return SizedBox(
              width: itemWidth,
              child: _StatCard(
                label: stat.label,
                value: values[index],
                icon: stat.icon,
                color: stat.color,
              ),
            );
          }),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6C7180),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Project progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _brandColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFECEEF4),
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Average progress across your projects',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF777C8B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.projects,
    this.compact = false,
    this.onEditProject,
    this.onDeleteProject,
  });

  final List<Project> projects;
  final bool compact;
  final ValueChanged<Project>? onEditProject;
  final ValueChanged<Project>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final project in projects) ...[
          _ProjectCard(
            project: project,
            compact: compact,
            onEditProject: onEditProject,
            onDeleteProject: onDeleteProject,
          ),
          if (project != projects.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    this.compact = false,
    this.onEditProject,
    this.onDeleteProject,
  });

  final Project project;
  final bool compact;
  final ValueChanged<Project>? onEditProject;
  final ValueChanged<Project>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final isActive = project.status == 'Active';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: project.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_open_rounded, color: project.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF777C8B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact &&
                    project.id != null &&
                    onEditProject != null &&
                    onDeleteProject != null)
                  PopupMenuButton<_ProjectCardAction>(
                    tooltip: 'Project actions',
                    onSelected: (action) {
                      if (action == _ProjectCardAction.edit) {
                        onEditProject!(project);
                      } else {
                        onDeleteProject!(project);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ProjectCardAction.edit,
                        child: Text('Edit project'),
                      ),
                      PopupMenuItem(
                        value: _ProjectCardAction.delete,
                        child: Text('Delete project'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatusPill(
                  label: project.status,
                  color: isActive
                      ? const Color(0xFF16845F)
                      : const Color(0xFFAD7615),
                  background: isActive
                      ? const Color(0xFFE6F5EF)
                      : const Color(0xFFFFF3DB),
                ),
                const Spacer(),
                Text(
                  '${(project.progress * 100).round()}% complete',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF777C8B),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFECEEF4),
                  color: project.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyProjectsMessage extends StatelessWidget {
  const _EmptyProjectsMessage();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('No active projects right now.'),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _ActivityRow(
                icon: Icons.bolt_rounded,
                color: const Color(0xFF21A179),
                title: 'Project Alpha · Active',
                detail: 'Acme Studio · 72% complete',
              ),
              const Divider(height: 1, indent: 68),
              _ActivityRow(
                icon: Icons.folder_open_rounded,
                color: _brandColor,
                title: 'Website Redesign · Active',
                detail: 'Northstar Co. · 46% complete',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF777C8B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({
    required this.projects,
    required this.isDesktop,
    required this.onAddProject,
    required this.onEditProject,
    required this.onDeleteProject,
  });

  final List<Project> projects;
  final bool isDesktop;
  final VoidCallback onAddProject;
  final ValueChanged<Project> onEditProject;
  final ValueChanged<Project> onDeleteProject;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Projects',
      subtitle: 'Keep track of your team’s work in one place.',
      trailing: isDesktop
          ? FilledButton.icon(
              onPressed: onAddProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
      child: Column(
        children: [
          if (!isDesktop) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddProject,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New project'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (projects.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: Text('No projects found.'),
                ),
              ),
            )
          else
            _ProjectList(
              projects: projects,
              onEditProject: onEditProject,
              onDeleteProject: onDeleteProject,
            ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Profile',
      subtitle: 'Your account information.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFE8ECFC),
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Budi Santoso',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Project Owner',
                    style: TextStyle(color: Color(0xFF6C7180)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const _ProfileInfoRow(
                    label: 'Owner ID',
                    value: 'OWN-001',
                    icon: Icons.badge_outlined,
                  ),
                  const Divider(height: 1),
                  const _ProfileInfoRow(
                    label: 'Phone',
                    value: '081234567890',
                    icon: Icons.phone_outlined,
                  ),
                  const Divider(height: 1),
                  _ProfileInfoRow(
                    label: 'Status',
                    value: 'Active',
                    icon: Icons.verified_outlined,
                    valueColor: const Color(0xFF16845F),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF777C8B), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF777C8B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600
            ? 16.0
            : constraints.maxWidth < 1024
            ? 24.0
            : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding,
            constraints.maxWidth < 600 ? 20 : 28,
            padding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(color: Color(0xFF6C7180)),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 16),
                        trailing!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Home', icon: Icons.home_outlined),
      (label: 'Projects', icon: Icons.folder_outlined),
      (label: 'Profile', icon: Icons.person_outline_rounded),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: TextButton.icon(
              onPressed: () => onSelected(index),
              icon: Icon(items[index].icon, size: 19),
              label: Text(items[index].label),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: selectedIndex == index
                    ? _brandColor
                    : const Color(0xFF6C7180),
                backgroundColor: selectedIndex == index
                    ? const Color(0xFFEEF1FE)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Flexible(
          child: Text(
            'Project Owner',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open account',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE8ECFC),
              child: Text(
                'B',
                style: TextStyle(
                  color: _brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
