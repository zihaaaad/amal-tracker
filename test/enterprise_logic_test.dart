import 'package:flutter_test/flutter_test.dart';
import 'package:amal_tracker/core/database/database_service.dart';
import 'package:amal_tracker/features/tracker/data/models/amal_task.dart';

void main() {
  group('Enterprise Logic Tests - As-Sunnah Foundation', () {
    test('DailyLog Point Calculation Logic', () {
      final tasks = [
        AmalTask(id: 't1', title: 'Task 1', category: 'salah', points: 5, inputType: TaskInputType.checkbox),
        AmalTask(id: 't2', title: 'Task 2', category: 'zikr', points: 10, inputType: TaskInputType.counter),
      ];

      final log = DailyLog(date: '2024-05-13', values: {
        't1': true,  // Should earn 5 points
        't2': 3,     // Should earn 0 points (below threshold of 5)
      });

      expect(log.getEarnedPoints(tasks), 5);

      final completedLog = DailyLog(date: '2024-05-13', values: {
        't1': true,  // 5 points
        't2': 5,     // 10 points (hits threshold)
      });

      expect(completedLog.getEarnedPoints(tasks), 15);
    });

    test('Streak Completion Threshold (50% Rule)', () {
      final tasks = [
        AmalTask(id: 't1', title: 'T1', category: 'c', points: 10, inputType: TaskInputType.checkbox),
        AmalTask(id: 't2', title: 'T2', category: 'c', points: 10, inputType: TaskInputType.checkbox),
      ];

      final failingLog = DailyLog(date: '2024-05-13', values: {'t1': true}); // 10/20 = 50%
      expect(failingLog.calculateCompletion(tasks), 0.5);

      final passingLog = DailyLog(date: '2024-05-13', values: {'t1': true, 't2': true}); // 100%
      expect(passingLog.calculateCompletion(tasks), 1.0);
    });

    test('DailyLog JSON Serialization Stability', () {
      final original = DailyLog(date: '2024-05-13', values: {'salah': true, 'zikr': 10});
      final json = original.toJson();
      final reconstructed = DailyLog.fromJson(json);

      expect(reconstructed.date, original.date);
      expect(reconstructed.getBool('salah'), true);
      expect(reconstructed.getCounter('zikr'), 10);
    });
  });
}
