import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/action_item.dart';
import '../utils/utils.dart';

class ActionForm extends StatefulWidget {
  final ActionItem? actionToEdit;

  const ActionForm({super.key, this.actionToEdit});

  @override
  State<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  ActionType _selectedType = ActionType.good;

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.actionToEdit == null
                  ? 'Ajouter une action'
                  : 'Modifier l\'action',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Type d'action (bonne ou mauvaise)
            SegmentedButton<ActionType>(
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
              },
            ),
            const SizedBox(height: 16.0),

            // Titre de l'action
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Description de l'action
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Points associés à l'action
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 24.0),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: _saveAction,
                  child: Text(
                    widget.actionToEdit == null ? 'Ajouter' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ],
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
