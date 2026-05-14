import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/profile_service.dart';
import '../../../tracker/data/models/amal_task.dart';
import '../../../tracker/data/services/task_service.dart';
import '../../../tracker/providers/tasks_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/admin_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userSearchQuery = "";
  String _selectedDept = "All";
  bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _authenticate();
  }

  Future<void> _authenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool authenticated = false;
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        // Fallback: If device doesn't support secure auth, grant access (or handle via PIN)
        authenticated = true;
      } else {
        authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to access Foundation Admin',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }
    } on PlatformException catch (_) {
      debugPrint('Auth error occurred');
      authenticated = false;
    }

    if (mounted) {
      if (authenticated) {
        setState(() {
          _isAuthenticating = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: 'Institutional Tasks'),
            Tab(text: 'Employees'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TASKS TAB ──────────────────────────────────────────────
          _buildTasksTab(context, tasksAsync),

          // ─── EMPLOYEES TAB ──────────────────────────────────────────
          _buildEmployeesTab(context),

          // ─── REPORTS TAB ────────────────────────────────────────────
          _buildReportsTab(context),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
        ? FloatingActionButton.extended(
            onPressed: () => _showTaskDialog(context),
            backgroundColor: context.timeTint,
            label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          )
        : null,
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
    return FutureBuilder<List<EmployeeProfile>>(
      future: ProfileService.instance.getAllEmployees(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('Error loading employees: ${snapshot.error}'));
        
        final all = snapshot.data ?? [];
        final filtered = all.where((e) {
          final matchesSearch = e.fullName.toLowerCase().contains(_userSearchQuery.toLowerCase()) || 
                               e.email.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
                               e.employeeId.contains(_userSearchQuery);
          final matchesDept = _selectedDept == "All" || e.department == _selectedDept;
          return matchesSearch && matchesDept;
        }).toList();

        final depts = ["All", ...all.map((e) => e.department).toSet()];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _userSearchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Email or ID...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: context.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: depts.map((d) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(d),
                          selected: _selectedDept == d,
                          onSelected: (val) => setState(() => _selectedDept = d),
                          selectedColor: context.timeTint.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: _selectedDept == d ? context.timeTint : context.textMuted),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _EmployeeTile(profile: filtered[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDialog(BuildContext context, [AmalTask? task]) {
    // Reusing previous logic but adapted to stateful widget
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?.title);
    final categoryController = TextEditingController(text: task?.category ?? 'habits');
    final pointsController = TextEditingController(text: (task?.points ?? 1).toString());
    TaskInputType selectedType = task?.inputType ?? TaskInputType.checkbox;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 32, top: 32, left: 24, right: 24),
        decoration: BoxDecoration(color: context.surfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Task' : 'New Task', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildField(context, 'Title', titleController, Icons.title_rounded),
            const SizedBox(height: 16),
            _buildField(context, 'Category', categoryController, Icons.category_rounded),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final newTask = AmalTask(
                    id: isEdit ? task.id : const Uuid().v4(),
                    title: titleController.text.trim(),
                    category: categoryController.text.trim(),
                    points: int.tryParse(pointsController.text) ?? 1,
                    inputType: selectedType,
                  );
                  if (isEdit) {
                    await TaskService.instance.updateTask(newTask);
                  } else {
                    await TaskService.instance.addTask(newTask);
                  }
                  ref.invalidate(tasksProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: context.timeTint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(isEdit ? 'Update' : 'Create', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: context.timeTint),
          filled: true,
          fillColor: context.surfaceOverlay,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ]);
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
}

class _TaskAdminTile extends ConsumerWidget {
  final AmalTask task;
  const _TaskAdminTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: context.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.glassBorder)),
      child: ListTile(
        leading: Icon(Icons.edit_note_rounded, color: context.timeTint),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${task.category} • ${task.points} pts'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softCoral),
          onPressed: () async {
            await TaskService.instance.softDeleteTask(task.id);
            ref.invalidate(tasksProvider);
          },
        ),
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
      decoration: BoxDecoration(color: context.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.glassBorder)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: context.timeTint.withValues(alpha: 0.1), child: Text(profile.fullName[0], style: TextStyle(color: context.timeTint, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${profile.department} • ID: ${profile.employeeId}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                Text(profile.subInstitute, style: TextStyle(color: context.timeTint.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
    );
  }
}
