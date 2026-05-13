import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

@collection
class DailyLogEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String date; // yyyy-MM-dd

  late String valuesJson; // Store values map as JSON for simplicity in Isar

  @Index()
  late DateTime createdAt;
  
  @Index()
  late DateTime updatedAt;
}

@collection
class TaskEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String taskId;

  late String category;
  late String title;
  late String inputType; // enum as string
  late int points;
  late bool isActive;
}
