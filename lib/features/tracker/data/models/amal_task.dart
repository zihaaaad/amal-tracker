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

enum TaskFrequency { daily, weekly, monthly }

class AmalTask {
  final String id;
  final String category;
  final String title;
  final String? subtitle;
  final TaskInputType inputType;
  final bool isActive;
  final int points;
  
  // Big-Tech Architecture: Explicit Scheduling & UI Metadata
  final TaskFrequency frequency;
  final List<int>? activeDays; // 1 (Mon) to 7 (Sun)
  final String? iconCode;      // Store IconData as point
  final int? colorValue;       // Store Color as ARGB int

  AmalTask({
    required this.id,
    required this.category,
    required this.title,
    this.subtitle,
    required this.inputType,
    this.isActive = true,
    this.points = 1,
    this.frequency = TaskFrequency.daily,
    this.activeDays,
    this.iconCode,
    this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'subtitle': subtitle,
        'input_type': inputType.name,
        'is_active': isActive,
        'points': points,
        'frequency': frequency.name,
        'active_days': activeDays,
        'icon_code': iconCode,
        'color_value': colorValue,
      };

  factory AmalTask.fromJson(Map<String, dynamic> json) => AmalTask(
        id: json['id'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        inputType: TaskInputType.fromString(json['input_type'] as String),
        isActive: json['is_active'] as bool? ?? true,
        points: json['points'] as int? ?? 1,
        frequency: TaskFrequency.values.firstWhere(
          (e) => e.name == (json['frequency'] as String? ?? 'daily'),
          orElse: () => TaskFrequency.daily,
        ),
        activeDays: (json['active_days'] as List<dynamic>?)?.cast<int>(),
        iconCode: json['icon_code'] as String?,
        colorValue: json['color_value'] as int?,
      );
}

