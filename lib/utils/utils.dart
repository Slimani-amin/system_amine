import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// Classe utilitaire pour les fonctions communes
class Utils {
  // Génère un ID unique basé sur l'horodatage et un nombre aléatoire
  static String generateId() {
    final now = DateTime.now();
    final random = Random();
    return '${now.millisecondsSinceEpoch}-${random.nextInt(10000)}';
  }

  // Formatte une date en format lisible
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formatte une date et heure en format lisible
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Formatte l'heure en format lisible
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Vérifie si deux dates sont le même jour
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Génère un gradient de couleur en fonction de la valeur du score
  static LinearGradient getScoreGradient(int score) {
    if (score >= 80) {
      // Score élevé - vert
      return LinearGradient(
        colors: [Colors.green.shade300, Colors.green.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (score >= 50) {
      // Score moyen - jaune/orange
      return LinearGradient(
        colors: [Colors.orange.shade300, Colors.orange.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Score faible - rouge
      return LinearGradient(
        colors: [Colors.red.shade300, Colors.red.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // Obtient une couleur en fonction du type d'action
  static Color getActionTypeColor(bool isGood) {
    return isGood ? Colors.green : Colors.red;
  }

  // Obtient une icône en fonction du type d'action
  static IconData getActionTypeIcon(bool isGood) {
    return isGood ? Icons.thumb_up : Icons.thumb_down;
  }

  // Montre une SnackBar avec un message
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Génère des couleurs pour les graphiques
  static List<Color> getChartColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
  }
}
