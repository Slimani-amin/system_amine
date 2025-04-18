import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/action_item.dart';
import '../utils/utils.dart';
import '../services/animation_service.dart';
import '../services/sound_service.dart';
import '../main.dart' show soundService;

class ActionForm extends StatefulWidget {
  final ActionItem? actionToEdit;

  const ActionForm({super.key, this.actionToEdit});

  @override
  State<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  ActionType _selectedType = ActionType.good;

  @override
  void initState() {
    super.initState();

    // Configuration de l'animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Si on modifie une action existante, on pré-remplit le formulaire
    if (widget.actionToEdit != null) {
      _titleController.text = widget.actionToEdit!.title;
      _descriptionController.text = widget.actionToEdit!.description;
      _pointsController.text = widget.actionToEdit!.points.toString();
      _selectedType = widget.actionToEdit!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGood = _selectedType == ActionType.good;
    final primaryColor = isGood ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              Text(
                widget.actionToEdit == null
                    ? 'Ajouter une action'
                    : 'Modifier l\'action',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // Type d'action (bonne ou mauvaise)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: SegmentedButton<ActionType>(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return primaryColor.withOpacity(0.8);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  segments: const [
                    ButtonSegment<ActionType>(
                      value: ActionType.good,
                      icon: Icon(Icons.thumb_up),
                      label: Text('Bonne action'),
                    ),
                    ButtonSegment<ActionType>(
                      value: ActionType.bad,
                      icon: Icon(Icons.thumb_down),
                      label: Text('Mauvaise action'),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                    soundService.playSound(SoundType.click);
                  },
                ),
              ),
              const SizedBox(height: 24.0),

              // Titre de l'action
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Nom de cette action',
                  prefixIcon: Icon(Icons.title, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Description de l'action
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez cette action...',
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Points associés à l'action
              TextFormField(
                controller: _pointsController,
                decoration: InputDecoration(
                  labelText: 'Points',
                  hintText: 'Valeur en points',
                  prefixIcon: Icon(Icons.stars, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nombre de points';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points <= 0) {
                    return 'Le nombre de points doit être positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimationService.bounceAnimation(
                    onTap: () {
                      soundService.playSound(SoundType.click);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.close, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Annuler',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimationService.bounceAnimation(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        soundService.playSound(SoundType.success);
                        _saveAction();
                      } else {
                        soundService.playSound(SoundType.error);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.actionToEdit == null
                                ? Icons.add_circle
                                : Icons.save,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.actionToEdit == null
                                ? 'Ajouter'
                                : 'Enregistrer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sauvegarde l'action
  void _saveAction() {
    if (_formKey.currentState!.validate()) {
      final actionsBox = Hive.box('actions');

      if (widget.actionToEdit == null) {
        // Création d'une nouvelle action
        final newAction = ActionItem(
          id: Utils.generateId(),
          title: _titleController.text,
          description: _descriptionController.text,
          points: int.parse(_pointsController.text),
          type: _selectedType,
          createdAt: DateTime.now(),
        );

        actionsBox.put(newAction.id, newAction.toJson());
        Utils.showSnackBar(context, 'Action ajoutée avec succès');
      } else {
        // Modification d'une action existante
        widget.actionToEdit!.title = _titleController.text;
        widget.actionToEdit!.description = _descriptionController.text;
        widget.actionToEdit!.points = int.parse(_pointsController.text);
        widget.actionToEdit!.type = _selectedType;

        actionsBox.put(widget.actionToEdit!.id, widget.actionToEdit!.toJson());
        Utils.showSnackBar(context, 'Action modifiée avec succès');
      }

      Navigator.pop(context);
    }
  }
}
