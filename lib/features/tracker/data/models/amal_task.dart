enum TaskInputType {
  checkbox,
  counter,
  numberInput;

  static TaskInputType fromString(String value) {
    return TaskInputType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskInputType.checkbox,
    );
  }
}

class AmalTask {
  final String id;
  final String category;
  final String title;
  final TaskInputType inputType;
  final bool isActive;
  final int points;

  AmalTask({
    required this.id,
    required this.category,
    required this.title,
    required this.inputType,
    this.isActive = true,
    this.points = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'input_type': inputType.name,
        'is_active': isActive,
        'points': points,
      };

  factory AmalTask.fromJson(Map<String, dynamic> json) => AmalTask(
        id: json['id'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        inputType: TaskInputType.fromString(json['input_type'] as String),
        isActive: json['is_active'] as bool? ?? true,
        points: json['points'] as int? ?? 1,
      );
}

