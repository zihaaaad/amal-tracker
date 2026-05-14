import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class GlobalStats {
  final int totalEmployees;
  final int activeToday;
  final double averagePoints;
  final List<Map<String, dynamic>> topPerformers;

  GlobalStats({
    required this.totalEmployees,
    required this.activeToday,
    required this.averagePoints,
    required this.topPerformers,
  });
}

class AdminService {
  AdminService._();
  static final instance = AdminService._();
  final _supabase = Supabase.instance.client;

  Future<GlobalStats> getGlobalStats() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // 1. Get total employee count
      final employeesResponse = await _supabase.from('profiles').select('id');
      final totalEmployees = employeesResponse.length;

      // 2. Get active employees today
      final logsToday = await _supabase.from('daily_logs').select('user_id').eq('date', today);
      final activeToday = logsToday.map((e) => e['user_id']).toSet().length;

      // 3. Get top performers (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
      final recentLogs = await _supabase
          .from('daily_logs')
          .select('user_id, completion_data, profiles(full_name)')
          .gte('date', sevenDaysAgo);

      Map<String, int> userPoints = {};
      Map<String, String> userNames = {};

      for (var log in recentLogs) {
        final userId = log['user_id'] as String;
        final name = log['profiles']['full_name'] as String;
        final data = log['completion_data'] as Map<String, dynamic>;
        
        int points = 0;
        data.forEach((_, value) {
          if (value is bool && value) points += 1;
          if (value is int) points += value;
        });

        userPoints[userId] = (userPoints[userId] ?? 0) + points;
        userNames[userId] = name;
      }

      final topPerformers = userPoints.entries.map((e) => {
        'name': userNames[e.key],
        'points': e.value,
      }).toList();
      topPerformers.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      return GlobalStats(
        totalEmployees: totalEmployees,
        activeToday: activeToday,
        averagePoints: totalEmployees > 0 ? (userPoints.values.fold(0, (a, b) => a + b) / totalEmployees) : 0,
        topPerformers: topPerformers.take(5).toList(),
      );
    } catch (e) {
      debugPrint('Global Stats Error: $e');
      return GlobalStats(totalEmployees: 0, activeToday: 0, averagePoints: 0, topPerformers: []);
    }
  }
}
