import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/action_item.dart';
import '../models/task.dart';
import '../utils/utils.dart';

class TaskForm extends StatefulWidget {
  final Task? taskToEdit;
  final DateTime? initialDate;

  const TaskForm({super.key, this.taskToEdit, this.initialDate});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  bool _isExistingAction = false;
  ActionItem? _selectedAction;
  List<ActionItem> _goodActions = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dueDate = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _dueTime = TimeOfDay(hour: 23, minute: 59);
    _pointsController.text = '10';

    _loadGoodActions();
  }

  Future<void> _loadGoodActions() async {
    final actionsBox = Hive.box('actions');
    final actionsData = actionsBox.values.toList();
    setState(() {
      _goodActions =
          actionsData
              .map((data) {
                if (data is Map) {
                  final action = ActionItem.fromJson(
                    Map<String, dynamic>.from(data),
                  );
                  return action.type == ActionType.good ? action : null;
                }
                return null;
              })
              .whereType<ActionItem>()
              .toList();
    });
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
              widget.taskToEdit == null
                  ? 'Ajouter une tâche'
                  : 'Modifier la tâche',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Sélecteur de type de tâche
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.list),
                  label: Text('Action existante'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.add),
                  label: Text('Nouvelle tâche'),
                ),
              ],
              selected: {_isExistingAction},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _isExistingAction = newSelection.first;
                  if (!_isExistingAction) {
                    _selectedAction = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),

            if (_isExistingAction) ...[
              // Sélecteur d'actions existantes
              DropdownButtonFormField<ActionItem>(
                value: _selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner une action',
                  border: OutlineInputBorder(),
                ),
                items:
                    _goodActions.map((action) {
                      return DropdownMenuItem<ActionItem>(
                        value: action,
                        child: Text(action.title),
                      );
                    }).toList(),
                onChanged: (action) {
                  setState(() {
                    _selectedAction = action;
                    if (action != null) {
                      _titleController.text = action.title;
                      _descriptionController.text = action.description;
                      _pointsController.text = action.points.toString();
                    }
                  });
                },
                validator: (value) {
                  if (_isExistingAction && value == null) {
                    return 'Veuillez sélectionner une action';
                  }
                  return null;
                },
              ),
            ] else ...[
              // Titre de la tâche
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

              // Description de la tâche
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
            ],
            const SizedBox(height: 16.0),

            // Date d'échéance
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(Utils.formatDate(_dueDate)),
              ),
            ),
            const SizedBox(height: 16.0),

            // Heure d'échéance
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Heure',
                  border: OutlineInputBorder(),
                ),
                child: Text(_dueTime.format(context)),
              ),
            ),
            const SizedBox(height: 16.0),

            // Points associés à la tâche
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
                  onPressed: _saveTask,
                  child: Text(
                    widget.taskToEdit == null ? 'Ajouter' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ouvre le sélecteur de date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // Ouvre le sélecteur d'heure
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  // Sauvegarde la tâche
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final tasksBox = Hive.box('tasks');

      // Combine la date et l'heure
      final dueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      if (widget.taskToEdit == null) {
        // Création d'une nouvelle tâche
        final newTask = Task(
          id: Utils.generateId(),
          title: _titleController.text,
          description: _descriptionController.text,
          points: int.parse(_pointsController.text),
          dueDate: dueDateTime,
          createdAt: DateTime.now(),
          isRecurring: _isExistingAction,
        );

        tasksBox.put(newTask.id, newTask.toJson());
        Utils.showSnackBar(context, 'Tâche ajoutée avec succès');
      } else {
        // Modification d'une tâche existante
        widget.taskToEdit!.title = _titleController.text;
        widget.taskToEdit!.description = _descriptionController.text;
        widget.taskToEdit!.points = int.parse(_pointsController.text);
        widget.taskToEdit!.dueDate = dueDateTime;
        widget.taskToEdit!.isRecurring = _isExistingAction;

        tasksBox.put(widget.taskToEdit!.id, widget.taskToEdit!.toJson());
        Utils.showSnackBar(context, 'Tâche modifiée avec succès');
      }

      Navigator.pop(context);
    }
  }
}
