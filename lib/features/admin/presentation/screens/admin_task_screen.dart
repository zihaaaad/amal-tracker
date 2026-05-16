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
  String _taskSearchQuery = '';
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
    return Column(
      children: [
        _buildSearchField('Search tasks...', (v) => setState(() => _taskSearchQuery = v)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(tasksProvider.future),
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((t) => t.title.toLowerCase().contains(_taskSearchQuery.toLowerCase())).toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _TaskAdminTile(task: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesTab(BuildContext context) {
    return Column(
      children: [
        _buildSearchField('Search employees...', (v) => setState(() => _userSearchQuery = v)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: FutureBuilder<List<EmployeeProfile>>(
              future: ProfileService.instance.getAllEmployees(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final employees = snapshot.data!
                    .where((e) => e.fullName.toLowerCase().contains(_userSearchQuery.toLowerCase()))
                    .toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: employees.length,
                  itemBuilder: (context, index) => _EmployeeTile(profile: employees[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<GlobalStats>(
        future: AdminService.instance.getGlobalStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final stats = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildNoticesTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<Announcement>>(
        future: AnnouncementService.instance.getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final notices = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notice.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField(String hint, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: context.surfaceCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Task' : 'New Institutional Task', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildDialogField('Title', titleController),
            const SizedBox(height: 16),
            _buildDialogField('Category', categoryController),
            const SizedBox(height: 16),
            _buildDialogField('Points', pointsController, TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ref.invalidate(tasksProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.timeTint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(isEdit ? 'Save Changes' : 'Create Task', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, [TextInputType? type]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.surfaceSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post New Notice', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildDialogField('Notice Title', titleController),
            const SizedBox(height: 16),
            _buildDialogField('Content', contentController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await AnnouncementService.instance.postAnnouncement(
                    titleController.text,
                    contentController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.timeTint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Broadcast Notice', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
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
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Deactivate Task?'),
                  content: const Text('This task will be hidden from all employees.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate', style: TextStyle(color: AppColors.softCoral))),
                  ],
                ),
              );
              if (confirm == true) {
                await TaskService.instance.softDeleteTask(task.id);
                ref.invalidate(tasksProvider);
              }
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
      child: InkWell(
        onTap: () {
          // Future Enhancement: Navigate to Detail Screen
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Drill-down for ${profile.fullName} coming in v1.2')));
        },
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
            const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
