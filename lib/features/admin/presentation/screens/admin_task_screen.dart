import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tracker/data/models/amal_task.dart';
import '../../../tracker/data/services/task_service.dart';
import '../../../tracker/providers/tasks_provider.dart';

class AdminTaskScreen extends ConsumerWidget {
  const AdminTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: tasksAsync.when(
        data: (tasks) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _TaskAdminTile(task: task);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context, ref),
        backgroundColor: context.timeTint,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, [AmalTask? task]) {
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          top: 32,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Institutional Task' : 'New Institutional Task',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            _buildField(context, 'Task Title', titleController, Icons.title_rounded),
            const SizedBox(height: 16),
            _buildField(context, 'Category (salah, zikr, habits)', categoryController, Icons.category_rounded),
            const SizedBox(height: 16),
            _buildField(context, 'Points', pointsController, Icons.stars_rounded, true),
            const SizedBox(height: 24),
            const Text('Input Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Checkbox',
                  isSelected: selectedType == TaskInputType.checkbox,
                  onTap: () => selectedType = TaskInputType.checkbox,
                ),
                const SizedBox(width: 12),
                _TypeChip(
                  label: 'Counter',
                  isSelected: selectedType == TaskInputType.counter,
                  onTap: () => selectedType = TaskInputType.counter,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final newTask = AmalTask(
                    id: isEdit ? task.id : DateTime.now().millisecondsSinceEpoch.toString(),
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
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.timeTint,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEdit ? 'Update Task' : 'Create Task', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller, IconData icon, [bool isNum = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: context.timeTint),
            filled: true,
            fillColor: context.surfaceOverlay,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.timeTint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_note_rounded, color: context.timeTint),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${task.category} • ${task.points} pts', 
                  style: TextStyle(color: context.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await TaskService.instance.softDeleteTask(task.id);
              ref.invalidate(tasksProvider);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softCoral),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.timeTint : context.surfaceOverlay,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
