import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/user_score_provider.dart';
import '../widgets/score_display.dart';
import 'actions_screen.dart';
import 'tasks_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Liste des écrans disponibles
  final List<Widget> _screens = [
    const ActionsScreen(),
    const TasksScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Vérifie les tâches en retard au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserScoreProvider>(
        context,
        listen: false,
      ).checkOverdueTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Amine'),
        centerTitle: true,
        actions: [
          // Bouton pour changer de thème
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      // Affiche le score en haut de l'écran
      body: Column(
        children: [
          const ScoreDisplay(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      // Barre de navigation avec les différents onglets
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Actions'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
