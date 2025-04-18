import 'package:hive/hive.dart';

class Task {
  final String id;
  String title;
  String description;
  int points;
  DateTime dueDate;
  bool isCompleted;
  bool isRecurring;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.dueDate,
    required this.createdAt,
    this.isCompleted = false,
    this.isRecurring = false,
    this.completedAt,
  });

  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  bool isOverdue() {
    final now = DateTime.now();
    return !isCompleted && dueDate.isBefore(now);
  }

  // Convertit un objet Task en Map pour Hive
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isRecurring': isRecurring,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Crée un objet Task à partir d'un Map venant de Hive
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      dueDate: DateTime.parse(json['dueDate']),
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
    );
  }

  // Sauvegarde l'objet dans Hive
  Future<void> save() async {
    final box = Hive.box('tasks');
    await box.put(id, toJson());
  }

  // Supprime l'objet de Hive
  Future<void> delete() async {
    final box = Hive.box('tasks');
    await box.delete(id);
  }
}
