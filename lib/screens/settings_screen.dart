import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/theme_provider.dart';
import '../providers/user_score_provider.dart';
import '../utils/utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la section
            const Text(
              'Paramètres',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),

            // Section Apparence
            _buildSectionTitle('Apparence'),
            const SizedBox(height: 8.0),
            _buildThemeSelector(context),
            const SizedBox(height: 24.0),

            // Section Données
            _buildSectionTitle('Données'),
            const SizedBox(height: 8.0),
            _buildDataManagementOptions(context),
            const SizedBox(height: 24.0),

            // Section À propos
            _buildSectionTitle('À propos'),
            const SizedBox(height: 8.0),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  // Construit le titre d'une section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
    );
  }

  // Construit le sélecteur de thème
  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thème de l\'application',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Clair'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Sombre'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.smartphone),
                  label: Text('Système'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (newSelection) {
                themeProvider.setThemeMode(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Construit les options de gestion des données
  Widget _buildDataManagementOptions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des données',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),

            // Option pour réinitialiser le score
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Réinitialiser le score'),
              subtitle: const Text(
                'Remet votre score à la valeur par défaut (100)',
              ),
              onTap: () => _resetScore(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              tileColor: Colors.orange.withOpacity(0.1),
            ),
            const SizedBox(height: 8.0),

            // Option pour effacer l'historique
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Effacer l\'historique'),
              subtitle: const Text(
                'Supprime l\'historique des actions tout en conservant votre score actuel',
              ),
              onTap: () => _clearHistory(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              tileColor: Colors.blue.withOpacity(0.1),
            ),
            const SizedBox(height: 8.0),

            // Option pour effacer toutes les données
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Réinitialiser toutes les données'),
              subtitle: const Text(
                'Supprime toutes les actions, tâches et historique',
              ),
              onTap: () => _resetAllData(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              tileColor: Colors.red.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  // Construit la section à propos
  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Amine',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 8.0),
            const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16.0),
            const Text(
              'Une application pour vous aider à suivre et équilibrer vos bonnes et mauvaises actions de manière ludique et motivante.',
            ),
            const SizedBox(height: 16.0),
            const Text(
              '© 2024 - Tous droits réservés',
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  // Réinitialise le score
  void _resetScore(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Réinitialiser le score?'),
            content: const Text(
              'Votre score sera remis à 0. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  // Réinitialiser le score via le provider
                  final scoreProvider = Provider.of<UserScoreProvider>(
                    context,
                    listen: false,
                  );
                  await scoreProvider.resetScore(100);

                  Navigator.pop(context);
                  Utils.showSnackBar(context, 'Score réinitialisé à 100');
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
    );
  }

  // Efface l'historique
  void _clearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Effacer l\'historique?'),
            content: const Text(
              'Tout l\'historique de vos actions sera supprimé, mais votre score actuel sera conservé. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  // Effacer l'historique via le provider
                  final scoreProvider = Provider.of<UserScoreProvider>(
                    context,
                    listen: false,
                  );
                  await scoreProvider.clearHistory();

                  Navigator.pop(context);
                  Utils.showSnackBar(context, 'Historique effacé');
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
    );
  }

  // Réinitialise toutes les données
  void _resetAllData(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Réinitialiser toutes les données?'),
            content: const Text(
              'Toutes vos actions, tâches et historique seront supprimés. Votre score sera remis à 100. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  // Réinitialiser toutes les données via le provider
                  final scoreProvider = Provider.of<UserScoreProvider>(
                    context,
                    listen: false,
                  );
                  await scoreProvider.resetAllData();

                  Navigator.pop(context);
                  Utils.showSnackBar(
                    context,
                    'Toutes les données ont été réinitialisées',
                  );
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
    );
  }
}
