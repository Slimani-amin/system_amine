import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/action_item.dart';
import '../models/task.dart';

class ScoreRecord {
  final DateTime date;
  final int score;
  final String? action;
  final int pointsChange;

  ScoreRecord({
    required this.date,
    required this.score,
    this.action,
    required this.pointsChange,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'score': score,
      'action': action,
      'pointsChange': pointsChange,
    };
  }

  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    return ScoreRecord(
      date: DateTime.parse(json['date']),
      score: json['score'],
      action: json['action'],
      pointsChange: json['pointsChange'],
    );
  }
}

class UserScoreProvider extends ChangeNotifier {
  late Box _userBox;
  late Box _actionsBox;
  late Box _tasksBox;

  // Score par défaut
  int _score = 0;
  List<ScoreRecord> _history = [];

  UserScoreProvider() {
    _loadData();
  }

  int get score => _score;
  List<ScoreRecord> get history => _history;

  // Charge les données depuis Hive
  Future<void> _loadData() async {
    _userBox = await Hive.openBox('user_data');
    _actionsBox = await Hive.openBox('actions');
    _tasksBox = await Hive.openBox('tasks');

    _score = _userBox.get('user_score', defaultValue: 0);

    final historyData = _userBox.get('score_history', defaultValue: []);
    if (historyData is List) {
      _history =
          historyData
              .map(
                (item) => ScoreRecord.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
    }

    notifyListeners();
  }

  // Sauvegarde les données dans Hive
  Future<void> _saveData() async {
    await _userBox.put('user_score', _score);
    await _userBox.put(
      'score_history',
      _history.map((record) => record.toJson()).toList(),
    );
  }

  // Ajoute des points au score
  Future<void> addPoints(int points, {String? actionName}) async {
    _score += points;

    // Ajoute un enregistrement à l'historique
    _history.add(
      ScoreRecord(
        date: DateTime.now(),
        score: _score,
        action: actionName,
        pointsChange: points,
      ),
    );

    await _saveData();
    notifyListeners();
  }

  // Soustrait des points au score
  Future<void> subtractPoints(int points, {String? actionName}) async {
    _score -= points;

    // Ajoute un enregistrement à l'historique
    _history.add(
      ScoreRecord(
        date: DateTime.now(),
        score: _score,
        action: actionName,
        pointsChange: -points,
      ),
    );

    await _saveData();
    notifyListeners();
  }

  // Enregistre une action effectuée
  Future<void> recordAction(ActionItem action) async {
    if (action.type == ActionType.good) {
      await addPoints(action.points, actionName: action.title);
    } else {
      await subtractPoints(action.points, actionName: action.title);
    }

    // Incrémente le compteur d'utilisation de l'action
    action.usageCount++;
    await _actionsBox.put(action.id, action.toJson());
  }

  // Marque une tâche comme complétée
  Future<void> completeTask(Task task) async {
    task.markAsCompleted();
    await _tasksBox.put(task.id, task.toJson());
    await addPoints(task.points, actionName: "Tâche: ${task.title}");
  }

  // Vérifie les tâches en retard et soustrait des points si nécessaire
  Future<void> checkOverdueTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Récupère toutes les tâches
    final allTasksData = _tasksBox.values.toList();
    final tasks =
        allTasksData
            .map((taskData) {
              if (taskData is Map) {
                return Task.fromJson(Map<String, dynamic>.from(taskData));
              } else {
                return null;
              }
            })
            .whereType<Task>()
            .toList();

    // Filtre les tâches en retard
    final overdueTasks =
        tasks
            .where((task) => !task.isCompleted && task.dueDate.isBefore(today))
            .toList();

    for (var task in overdueTasks) {
      // Ne pénalise que les tâches qui n'ont pas encore été marquées comme en retard
      if (task.dueDate.day == today.day - 1) {
        await subtractPoints(
          task.points,
          actionName: "Tâche en retard: ${task.title}",
        );
      }
    }
  }

  // Obtient les statistiques par période (jour, semaine, mois)
  Map<String, dynamic> getStatsByPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        // Début de la semaine (lundi)
        final weekDay = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - weekDay + 1);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    // Filtrer l'historique pour la période donnée
    final periodRecords =
        _history.where((record) => record.date.isAfter(startDate)).toList();

    // Calculer les statistiques
    int positivePoints = 0;
    int negativePoints = 0;

    for (var record in periodRecords) {
      if (record.pointsChange > 0) {
        positivePoints += record.pointsChange;
      } else {
        negativePoints += record.pointsChange.abs();
      }
    }

    return {
      'positivePoints': positivePoints,
      'negativePoints': negativePoints,
      'netChange': positivePoints - negativePoints,
      'actionsCount': periodRecords.length,
    };
  }

  // Obtient les données pour le graphique
  List<Map<String, dynamic>> getChartData(String period, int limit) {
    final dateFormat = DateFormat('dd/MM');
    final result = <Map<String, dynamic>>[];
    Map<String, int> dataPoints = {};

    switch (period) {
      case 'week':
        // Regrouper par jour
        for (var i = 6; i >= 0; i--) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dateStr = dateFormat.format(date);
          dataPoints[dateStr] = 0;
        }

        // Remplir avec les données réelles
        for (var record in _history) {
          final dateStr = dateFormat.format(record.date);
          if (dataPoints.containsKey(dateStr)) {
            dataPoints[dateStr] = record.score;
          }
        }
        break;

      case 'month':
        // Regrouper par semaine
        for (var i = 0; i < 4; i++) {
          final weekStart = DateTime.now().subtract(
            Duration(days: DateTime.now().weekday - 1 + (7 * i)),
          );
          final dateStr = "S${i + 1}: ${dateFormat.format(weekStart)}";
          dataPoints[dateStr] = 0;
        }

        // Remplir avec les données réelles (dernier score de chaque semaine)
        for (var record in _history) {
          final weekNum = (record.date.day - 1) ~/ 7;
          if (weekNum < 4) {
            final weekStart = DateTime(
              record.date.year,
              record.date.month,
              1 + (weekNum * 7),
            );
            final dateStr = "S${weekNum + 1}: ${dateFormat.format(weekStart)}";
            dataPoints[dateStr] = record.score;
          }
        }
        break;

      default:
        // Par défaut, prendre les X derniers jours
        for (var i = limit - 1; i >= 0; i--) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dateStr = dateFormat.format(date);
          dataPoints[dateStr] = 0;
        }

        // Remplir avec les données réelles
        for (var record in _history) {
          final dateStr = dateFormat.format(record.date);
          if (dataPoints.containsKey(dateStr)) {
            dataPoints[dateStr] = record.score;
          }
        }
    }

    // Convertir en liste pour le graphique
    dataPoints.forEach((date, score) {
      result.add({'date': date, 'score': score});
    });

    return result;
  }

  // Efface l'historique des scores
  Future<void> clearHistory() async {
    _history = [];
    await _saveData();
    notifyListeners();
  }

  // Réinitialise le score à une valeur par défaut
  Future<void> resetScore(int defaultScore) async {
    _score = defaultScore;
    await _saveData();
    notifyListeners();
  }

  // Réinitialise toutes les données
  Future<void> resetAllData() async {
    _score = 0;
    _history = [];

    // Vider les boites de données
    await _tasksBox.clear();
    await _actionsBox.clear();

    await _saveData();
    notifyListeners();
  }
}
