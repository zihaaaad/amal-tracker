import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/amal_task.dart';
import '../data/services/task_service.dart';

/// StreamProvider allows us to yield cached data instantly, then fresh data.
final tasksProvider = StreamProvider<List<AmalTask>>((ref) {
  return TaskService.instance.getTasksStream();
});

/// Returns tasks grouped by category
final groupedTasksProvider = Provider<AsyncValue<Map<String, List<AmalTask>>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  
  return tasksAsync.whenData((tasks) {
    final grouped = <String, List<AmalTask>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.category, () => []).add(task);
    }
    return grouped;
  });
});

