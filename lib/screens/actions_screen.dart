import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/action_item.dart';
import '../providers/user_score_provider.dart';
import '../utils/utils.dart';
import '../widgets/action_form.dart';
import '../services/animation_service.dart';
import '../services/sound_service.dart';
import '../main.dart' show soundService;

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          // TabBar pour basculer entre les bonnes et mauvaises actions
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bonnes Actions'),
              Tab(text: 'Mauvaises Actions'),
            ],
          ),
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActionsList(ActionType.good),
                _buildActionsList(ActionType.bad),
              ],
            ),
          ),
        ],
      ),
      // Bouton pour ajouter une nouvelle action
      floatingActionButton: AnimationService.bounceAnimation(
        onTap: () {
          soundService.playSound(SoundType.click);
          _showAddActionDialog();
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

  // Construit la liste des actions par type (bonnes ou mauvaises)
  Widget _buildActionsList(ActionType type) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('actions').listenable(),
      builder: (context, box, _) {
        final actionsData = box.values.toList();
        final actions =
            actionsData
                .map((data) {
                  if (data is Map) {
                    return ActionItem.fromJson(Map<String, dynamic>.from(data));
                  }
                  return null;
                })
                .whereType<ActionItem>()
                .where((action) => action.type == type)
                .toList();

        if (actions.isEmpty) {
          return Center(
            child: AnimationService.fadeInAnimation(
              delay: 300,
              child: Text(
                type == ActionType.good
                    ? 'Aucune bonne action. Ajoutez-en une!'
                    : 'Aucune mauvaise action. Tant mieux!',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return AnimationService.fadeInAnimation(
              delay: 100 * index,
              child: _buildActionItem(action),
            );
          },
        );
      },
    );
  }

  // Construit un élément de la liste des actions
  Widget _buildActionItem(ActionItem action) {
    final bool isGood = action.type == ActionType.good;
    final scoreProvider = Provider.of<UserScoreProvider>(
      context,
      listen: false,
    );

    return Slidable(
      // Actions lors du glissement vers la droite
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // Bouton pour enregistrer l'action
          SlidableAction(
            onPressed: (_) {
              soundService.playSound(SoundType.success);
              scoreProvider.recordAction(action);
              Utils.showSnackBar(
                context,
                '${action.title} : ${isGood ? '+' : '-'}${action.points} points',
              );
            },
            backgroundColor: isGood ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
            icon: isGood ? Icons.add_circle : Icons.remove_circle,
            label: isGood ? 'Ajouter' : 'Soustraire',
          ),
        ],
      ),
      // Actions lors du glissement vers la gauche
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // Bouton pour modifier l'action
          SlidableAction(
            onPressed: (_) {
              soundService.playSound(SoundType.click);
              _showEditActionDialog(action);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          // Bouton pour supprimer l'action
          SlidableAction(
            onPressed: (_) {
              soundService.playSound(SoundType.error);
              _deleteAction(action);
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
                backgroundColor: isGood ? Colors.green : Colors.red,
                child: Icon(
                  isGood ? Icons.thumb_up : Icons.thumb_down,
                  color: Colors.white,
                ),
              ),
              title: Text(
                action.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(action.description),
              trailing: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isGood ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isGood ? '+' : '-'}${action.points}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGood ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
              onTap: () {
                soundService.playSound(SoundType.click);
                // Demande confirmation avant d'enregistrer l'action
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(
                          'Confirmer ${isGood ? 'bonne' : 'mauvaise'} action',
                        ),
                        content: Text(
                          'Voulez-vous ${isGood ? 'ajouter' : 'soustraire'} ${action.points} points pour "${action.title}" ?',
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
                              soundService.playSound(SoundType.success);
                              Navigator.pop(context);
                              scoreProvider.recordAction(action);
                              Utils.showSnackBar(
                                context,
                                '${action.title} : ${isGood ? '+' : '-'}${action.points} points',
                              );
                            },
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                );
              },
            ),
            // Boutons d'action explicites
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton d'édition
                  AnimationService.bounceAnimation(
                    onTap: () {
                      soundService.playSound(SoundType.click);
                      _showEditActionDialog(action);
                    },
                    child: TextButton.icon(
                      onPressed: null, // On utilise l'animation à la place
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
                      _deleteAction(action);
                    },
                    child: TextButton.icon(
                      onPressed: null, // On utilise l'animation à la place
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

  // Affiche le formulaire pour ajouter une action
  void _showAddActionDialog() {
    soundService.playSound(SoundType.click);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const ActionForm(),
          ),
    );
  }

  // Affiche le formulaire pour modifier une action
  void _showEditActionDialog(ActionItem action) {
    soundService.playSound(SoundType.click);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ActionForm(actionToEdit: action),
          ),
    );
  }

  // Supprime une action après confirmation
  void _deleteAction(ActionItem action) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text('Voulez-vous vraiment supprimer "${action.title}" ?'),
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
                  final actionsBox = Hive.box('actions');
                  actionsBox.delete(action.id);
                  Utils.showSnackBar(context, 'Action supprimée');
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
