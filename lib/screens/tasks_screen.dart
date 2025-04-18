import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/user_score_provider.dart';
import '../utils/utils.dart';
import '../widgets/task_form.dart';
import '../services/animation_service.dart';
import '../services/sound_service.dart';
import '../main.dart' show soundService;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sélecteur de date
          _buildDateSelector(),

          // TabBar pour basculer entre les tâches actives et complétées
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'À faire'), Tab(text: 'Terminées')],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTasksList(false), _buildTasksList(true)],
            ),
          ),
        ],
      ),
      // Bouton pour ajouter une nouvelle tâche
      floatingActionButton: AnimationService.bounceAnimation(
        onTap: () {
          soundService.playSound(SoundType.click);
          _showAddTaskDialog();
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  // Construit le sélecteur de date
  Widget _buildDateSelector() {
    return AnimationService.fadeInAnimation(
      delay: 100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimationService.bounceAnimation(
              onTap: () {
                soundService.playSound(SoundType.click);
                setState(() {
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  );
                });
              },
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: null, // On utilise l'animation à la place
              ),
            ),
            AnimationService.bounceAnimation(
              onTap: () {
                soundService.playSound(SoundType.click);
                _selectDate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  Utils.formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            AnimationService.bounceAnimation(
              onTap: () {
                soundService.playSound(SoundType.click);
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: null, // On utilise l'animation à la place
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ouvre le sélecteur de date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      soundService.playSound(SoundType.success);
    }
  }

  // Construit la liste des tâches
  Widget _buildTasksList(bool completed) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('tasks').listenable(),
      builder: (context, box, _) {
        final selectedDay = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        final tasksData = box.values.toList();
        final tasks =
            tasksData
                .map((data) {
                  if (data is Map) {
                    return Task.fromJson(Map<String, dynamic>.from(data));
                  }
                  return null;
                })
                .whereType<Task>()
                .where(
                  (task) =>
                      Utils.isSameDay(task.dueDate, selectedDay) &&
                      task.isCompleted == completed,
                )
                .toList();

        if (tasks.isEmpty) {
          return Center(
            child: AnimationService.fadeInAnimation(
              delay: 300,
              child: Text(
                completed
                    ? 'Aucune tâche terminée pour cette journée'
                    : 'Aucune tâche à faire pour cette journée',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AnimationService.fadeInAnimation(
              delay: 100 * index,
              child: _buildTaskItem(task),
            );
          },
        );
      },
    );
  }

  // Construit un élément de la liste des tâches
  Widget _buildTaskItem(Task task) {
    final scoreProvider = Provider.of<UserScoreProvider>(
      context,
      listen: false,
    );
    final isOverdue = task.isOverdue();

    return Slidable(
      // Actions lors du glissement vers la droite
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // Bouton pour marquer comme complétée
          if (!task.isCompleted)
            SlidableAction(
              onPressed: (_) {
                soundService.playSound(SoundType.complete);
                scoreProvider.completeTask(task);
                Utils.showSnackBar(
                  context,
                  'Tâche "${task.title}" complétée: +${task.points} points',
                );
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check_circle,
              label: 'Terminer',
            ),
        ],
      ),
      // Actions lors du glissement vers la gauche
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // Bouton pour modifier la tâche
          SlidableAction(
            onPressed: (_) {
              soundService.playSound(SoundType.click);
              _showEditTaskDialog(task);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          // Bouton pour supprimer la tâche
          SlidableAction(
            onPressed: (_) {
              soundService.playSound(SoundType.error);
              _deleteTask(task);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      // Contenu de l'élément
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    task.isCompleted
                        ? Colors.green
                        : (isOverdue ? Colors.red : Colors.orange),
                child: Icon(
                  task.isCompleted
                      ? Icons.check
                      : (isOverdue ? Icons.warning : Icons.pending),
                  color: Colors.white,
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description),
                  const SizedBox(height: 4.0),
                  Text(
                    'Échéance: ${DateFormat('HH:mm').format(task.dueDate)}',
                    style: TextStyle(
                      color:
                          isOverdue && !task.isCompleted
                              ? Colors.red
                              : Colors.grey,
                      fontWeight:
                          isOverdue && !task.isCompleted
                              ? FontWeight.bold
                              : null,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color:
                      task.isCompleted
                          ? Colors.green.shade100
                          : (isOverdue
                              ? Colors.red.shade100
                              : Colors.orange.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${task.points}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        task.isCompleted
                            ? Colors.green.shade800
                            : (isOverdue
                                ? Colors.red.shade800
                                : Colors.orange.shade800),
                  ),
                ),
              ),
              onTap: () {
                if (!task.isCompleted) {
                  soundService.playSound(SoundType.click);
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Marquer comme terminée?'),
                          content: Text(
                            'La tâche "${task.title}" sera marquée comme terminée et vous gagnerez ${task.points} points.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                soundService.playSound(SoundType.click);
                                Navigator.pop(context);
                              },
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                soundService.playSound(SoundType.complete);
                                Navigator.pop(context);
                                scoreProvider.completeTask(task);
                                Utils.showSnackBar(
                                  context,
                                  'Tâche "${task.title}" complétée: +${task.points} points',
                                );
                              },
                              child: const Text('Confirmer'),
                            ),
                          ],
                        ),
                  );
                }
              },
            ),
            // Boutons d'action explicites
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton pour marquer comme terminée (seulement si non complétée)
                  if (!task.isCompleted)
                    AnimationService.bounceAnimation(
                      onTap: () {
                        soundService.playSound(SoundType.click);
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Marquer comme terminée?'),
                                content: Text(
                                  'La tâche "${task.title}" sera marquée comme terminée et vous gagnerez ${task.points} points.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      soundService.playSound(SoundType.click);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      soundService.playSound(
                                        SoundType.complete,
                                      );
                                      Navigator.pop(context);
                                      scoreProvider.completeTask(task);
                                      Utils.showSnackBar(
                                        context,
                                        'Tâche "${task.title}" complétée: +${task.points} points',
                                      );
                                    },
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: TextButton.icon(
                        onPressed: null,
                        icon: const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green,
                        ),
                        label: const Text('Terminer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                  if (!task.isCompleted) const SizedBox(width: 8),
                  // Bouton d'édition
                  AnimationService.bounceAnimation(
                    onTap: () {
                      soundService.playSound(SoundType.click);
                      _showEditTaskDialog(task);
                    },
                    child: TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton de suppression
                  AnimationService.bounceAnimation(
                    onTap: () {
                      soundService.playSound(SoundType.error);
                      _deleteTask(task);
                    },
                    child: TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Affiche le formulaire pour ajouter une tâche
  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: TaskForm(initialDate: _selectedDate),
          ),
    );
  }

  // Affiche le formulaire pour modifier une tâche
  void _showEditTaskDialog(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: TaskForm(taskToEdit: task),
          ),
    );
  }

  // Supprime une tâche après confirmation
  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text(
              'Voulez-vous vraiment supprimer la tâche "${task.title}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  soundService.playSound(SoundType.click);
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  soundService.playSound(SoundType.error);
                  Navigator.pop(context);
                  final tasksBox = Hive.box('tasks');
                  tasksBox.delete(task.id);
                  Utils.showSnackBar(context, 'Tâche supprimée');
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
