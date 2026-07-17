import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class AddEditMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddEditMedicationScreen({super.key, this.medication});

  @override
  State<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState extends State<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationService _medicationService = MedicationService();
  final NotificationService _notificationService = NotificationService();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  List<TimeOfDay> _selectedTimes = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.medication?.name ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.medication?.dosage ?? '',
    );
    _frequencyController = TextEditingController(
      text: widget.medication?.frequency ?? '',
    );

    if (widget.medication?.reminderTimes != null) {
      _selectedTimes = widget.medication!.reminderTimes.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && !_selectedTimes.contains(picked)) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final List<String> reminderTimesStr = _selectedTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList();

      final medication = Medication(
        id: widget.medication?.id ?? '',
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequencyController.text,
        reminderTimes: reminderTimesStr,
        nextDose: widget.medication?.nextDose,
      );

      String docId = widget.medication?.id ?? '';
      if (widget.medication == null) {
        // We'll need the ID from Firestore to schedule notifications uniquely if we use doc ID hash
        // For simplicity, we'll let Firestore generate the ID then we update it or use a different approach
        // Let's modify MedicationService.addMedication to return the ID or similar
        // Or just use a hash of the name + time for now.
        await _medicationService.addMedication(medication);
      } else {
        await _medicationService.updateMedication(medication);
      }

      // Schedule notifications
      // In a real app, you'd manage IDs carefully. Here we use a simple hash.
      for (int i = 0; i < _selectedTimes.length; i++) {
        await _notificationService.scheduleNotification(
          id: (_nameController.text + reminderTimesStr[i]).hashCode,
          title: 'Medication Reminder',
          body:
              'It\'s time to take ${_dosageController.text} of ${_nameController.text}',
          scheduledTime: _selectedTimes[i],
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null ? 'Add Medication' : 'Edit Medication',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., 500mg)',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter dosage' : null,
              ),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency (e.g., Twice a day)',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter frequency' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Times',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_alarm),
                    onPressed: () => _selectTime(context),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _selectedTimes.map((time) {
                  return Chip(
                    label: Text(time.format(context)),
                    onDeleted: () {
                      setState(() {
                        _selectedTimes.remove(time);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMedication,
                child: Text(widget.medication == null ? 'Add' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
