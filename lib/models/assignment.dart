// lib/assignment.dart
class Assignment {
  int? id;
  String title;
  String? description;
  String course; // nama mata kuliah / kategori
  String dueDate; // ISO string
  bool isDone;
  String createdAt;

  Assignment({
    this.id,
    required this.title,
    this.description,
    required this.course,
    required this.dueDate,
    this.isDone = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course': course,
      'dueDate': dueDate,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      course: map['course'] as String? ?? 'Umum',
      dueDate: map['dueDate'] as String? ?? DateTime.now().toIso8601String(),
      isDone: ((map['isDone'] ?? 0) as int) == 1,
      createdAt:
          map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
