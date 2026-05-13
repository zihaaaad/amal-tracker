import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/amal_task.dart';
import '../../../../core/constants/salah_data.dart';

class TaskService {
  TaskService._();
  static final instance = TaskService._();

  final _supabase = Supabase.instance.client;
  static const _tasksKey = 'cached_amal_tasks';

  /// Fetches tasks with a "Stale-While-Revalidate" approach.
  /// Returns cached tasks immediately if available, then updates from network.
  Stream<List<AmalTask>> getTasksStream() async* {
    // 1. Yield cached tasks immediately for instant UI (seeds from local if empty)
    final cached = await getCachedTasks();
    yield cached;

    // 2. Fetch fresh data from Supabase in the background
    try {
      final response = await _supabase
          .from('amal_tasks')
          .select()
          .eq('is_active', true)
          .order('category', ascending: true);

      final freshTasks = (response as List).map((json) => AmalTask.fromJson(json)).toList();
      
      // 3. Update cache and yield fresh data only if different
      if (freshTasks.isNotEmpty) {
        await _cacheTasks(freshTasks);
        yield freshTasks;
      }
    } catch (e) {
      debugPrint('Network fetch failed: $e. Using cache/seed.');
      // Already yielded above — no need to yield again
    }
  }

  /// Legacy fetch for one-time loads (optimized)
  Future<List<AmalTask>> fetchTasks() async {
    final cached = await getCachedTasks();
    
    // Background refresh
    _refreshCache(); 

    return cached.isNotEmpty ? cached : await _fetchFromNetwork();
  }

  Future<List<AmalTask>> _fetchFromNetwork() async {
    try {
      final response = await _supabase
          .from('amal_tasks')
          .select()
          .eq('is_active', true)
          .order('category', ascending: true);

      final tasks = (response as List).map((json) => AmalTask.fromJson(json)).toList();
      await _cacheTasks(tasks);
      return tasks;
    } catch (e) {
      return getCachedTasks();
    }
  }

  void _refreshCache() async {
    try {
      final response = await _supabase
          .from('amal_tasks')
          .select()
          .eq('is_active', true);
      final tasks = (response as List).map((json) => AmalTask.fromJson(json)).toList();
      await _cacheTasks(tasks);
    } catch (_) {}
  }

  Future<void> _cacheTasks(List<AmalTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, json.encode(jsonList));
  }

  Future<List<AmalTask>> getCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tasksKey);
    
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        return jsonList.map((j) => AmalTask.fromJson(j)).toList();
      } catch (_) {
        return _seedFromLocal();
      }
    }
    
    // Seed from local if no cache exists (First launch / Offline)
    return _seedFromLocal();
  }

  Future<List<AmalTask>> _seedFromLocal() async {
    try {
      final localItems = SalahData.allItems.map((item) => AmalTask(
        id: item.id,
        category: item.category.name,
        title: item.title,
        inputType: item.isCounter ? TaskInputType.counter : TaskInputType.checkbox,
        points: (item.id == 'fajr' || item.id == 'dhuhr' || item.id == 'asr' || item.id == 'maghrib' || item.id == 'isha') ? 5 : 1,
      )).toList();
      
      await _cacheTasks(localItems);
      return localItems;
    } catch (e) {
      debugPrint('Seeding failed: $e');
      return [];
    }
  }


  // ─── Internal Management Methods ──────────────────
  
  Future<void> addTask(AmalTask task) async {
    await _supabase.from('amal_tasks').insert(task.toJson());
  }

  Future<void> updateTask(AmalTask task) async {
    await _supabase.from('amal_tasks').update(task.toJson()).eq('id', task.id);
  }

  Future<void> softDeleteTask(String taskId) async {
    await _supabase.from('amal_tasks').update({'is_active': false}).eq('id', taskId);
  }
}

