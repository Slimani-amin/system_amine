import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskService {
  final Box<Task> _taskBox = Hive.box<Task>('tasks');

  // Ajoute une nouvelle tâche
  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);

    // Si la tâche est récurrente, on crée une copie pour le lendemain
    if (task.isRecurring) {
      final nextDayTask = Task(
        id: const Uuid().v4(),
        title: task.title,
        description: task.description,
        points: task.points,
        dueDate: task.dueDate.add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        isRecurring: true,
      );
      await _taskBox.put(nextDayTask.id, nextDayTask);
    }
  }

  // Récupère toutes les tâches
  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  // Récupère les tâches pour une date spécifique
  List<Task> getTasksForDate(DateTime date) {
    return _taskBox.values.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList();
  }

  // Met à jour une tâche
  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  // Supprime une tâche
  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
  }

  // Marque une tâche comme complétée
  Future<void> completeTask(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.markAsCompleted();
      await _taskBox.put(taskId, task);
    }
  }
}
