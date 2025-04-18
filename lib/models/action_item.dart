import 'package:hive/hive.dart';

enum ActionType { good, bad }

class ActionItem {
  final String id;
  String title;
  String description;
  int points;
  ActionType type;
  DateTime createdAt;
  int usageCount;

  ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    required this.createdAt,
    this.usageCount = 0,
  });

  // Convertit un objet ActionItem en Map pour Hive
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  // Crée un objet ActionItem à partir d'un Map venant de Hive
  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      type: ActionType.values[json['type']],
      createdAt: DateTime.parse(json['createdAt']),
      usageCount: json['usageCount'],
    );
  }

  // Sauvegarde l'objet dans Hive
  Future<void> save() async {
    final box = Hive.box('actions');
    await box.put(id, toJson());
  }

  // Supprime l'objet de Hive
  Future<void> delete() async {
    final box = Hive.box('actions');
    await box.delete(id);
  }
}
