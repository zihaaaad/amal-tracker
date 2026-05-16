import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/admin_service.dart';
import '../../../../core/services/announcement_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../tracker/data/models/amal_task.dart';
import '../../../tracker/data/services/task_service.dart';
import '../../../tracker/providers/tasks_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  String _userSearchQuery = '';
  String _selectedDept = 'All';
  bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _authenticate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isAuthenticating) {
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() => _isAuthenticating = false);
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the Foundation Dashboard',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );

      if (didAuthenticate) {
        setState(() => _isAuthenticating = false);
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Auth error: $e');
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return Scaffold(
        backgroundColor: context.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: context.timeTint),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text('Foundation Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.timeTint,
          labelColor: context.timeTint,
          unselectedLabelColor: context.textMuted,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Employees'),
            Tab(text: 'Reports'),
            Tab(text: 'Notices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(context, tasksAsync),
          _buildEmployeesTab(context),
          _buildReportsTab(context),
          _buildNoticesTab(context),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
        ? FloatingActionButton.extended(
            onPressed: () => _showTaskDialog(context),
            backgroundColor: context.timeTint,
            label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          )
        : (_tabController.index == 3 
            ? FloatingActionButton.extended(
                onPressed: () => _showAnnouncementDialog(context),
                backgroundColor: context.timeTint,
                label: const Text('Post Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.campaign_rounded, color: Colors.white),
              )
            : null),
    );
  }

  Widget _buildTasksTab(BuildContext context, AsyncValue<List<AmalTask>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _TaskAdminTile(task: tasks[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmployeesTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            onChanged: (v) => setState(() => _userSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search employees...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: context.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<EmployeeProfile>>(
            future: ProfileService.instance.getAllEmployees(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final employees = snapshot.data!
                  .where((e) => e.fullName.toLowerCase().contains(_userSearchQuery.toLowerCase()))
                  .toList();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: employees.length,
                itemBuilder: (context, index) => _EmployeeTile(profile: employees[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return FutureBuilder<GlobalStats>(
      future: AdminService.instance.getGlobalStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        final stats = snapshot.data!;
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Daily Foundation Pulse', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Total Staff', stats.totalEmployees.toString(), Icons.people_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, 'Logged Today', stats.activeToday.toString(), Icons.check_circle_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Weekly Top Performers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...stats.topPerformers.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.glassBorder)),
              child: Row(
                children: [
                  Text('${stats.topPerformers.indexOf(e) + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: context.timeTint, fontSize: 18)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(e['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('${e['points']} pts', style: TextStyle(color: context.timeTint, fontWeight: FontWeight.w800)),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildNoticesTab(BuildContext context) {
    return FutureBuilder<List<Announcement>>(
      future: AnnouncementService.instance.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final notices = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notice.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: context.glassBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.timeTint),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, [AmalTask? task]) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?.title);
    final categoryController = TextEditingController(text: task?.category ?? 'spiritual');
    final pointsController = TextEditingController(text: task?.points.toString() ?? '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'Edit Task' : 'New Institutional Task', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task Title')),
            const SizedBox(height: 12),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'Points'), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final newTask = AmalTask(
                    id: isEdit ? task.id : const Uuid().v4(),
                    title: titleController.text,
                    category: categoryController.text,
                    points: int.tryParse(pointsController.text) ?? 1,
                    inputType: task?.inputType ?? TaskInputType.checkbox,
                  );
                  if (isEdit) {
                    await TaskService.instance.updateTask(newTask);
                  } else {
                    await TaskService.instance.addTask(newTask);
                  }
                  if (mounted) Navigator.pop(context);
                  ref.invalidate(tasksProvider);
                },
                child: Text(isEdit ? 'Save Changes' : 'Create Task'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Post New Notice', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Notice Title')),
            const SizedBox(height: 12),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await AnnouncementService.instance.postAnnouncement(
                    titleController.text,
                    contentController.text,
                  );
                  if (mounted) Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Broadcast Notice'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TaskAdminTile extends ConsumerWidget {
  final AmalTask task;
  const _TaskAdminTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${task.category.toUpperCase()} • ${task.points} Points', 
                    style: TextStyle(color: context.timeTint.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softCoral), 
            onPressed: () async {
              await TaskService.instance.softDeleteTask(task.id);
              ref.invalidate(tasksProvider);
            }),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final EmployeeProfile profile;
  const _EmployeeTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.timeTint.withValues(alpha: 0.1),
            child: Text(profile.fullName[0], style: TextStyle(color: context.timeTint, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${profile.department} • ${profile.subInstitute}', style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
