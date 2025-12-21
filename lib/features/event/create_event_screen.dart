import 'package:air_time_manager/app/app_scope.dart';
import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minWashingMinutesController = TextEditingController(text: '5');
  final _minPressureController = TextEditingController(text: '200');
  final _alertThresholdMinutesController = TextEditingController(text: '10');
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minWashingMinutesController.dispose();
    _minPressureController.dispose();
    _alertThresholdMinutesController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      final repo = AppScope.of(context).repo;
      await repo.createEvent(
        name: _nameController.text.trim(),
        minWashingTime: Duration(
          minutes: int.parse(_minWashingMinutesController.text),
        ),
        minPressureBar: int.parse(_minPressureController.text),
        alertThreshold: Duration(
          minutes: int.parse(_alertThresholdMinutesController.text),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה ביצירת אירוע: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('יצירת אירוע חדש'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'פרטי אירוע',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'שם האירוע',
                        hintText: 'למשל: אימון יום ראשון',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'נא להזין שם אירוע';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'פרמטרים',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minWashingMinutesController,
                      decoration: const InputDecoration(
                        labelText: 'זמן שטיפה מינימלי (דקות)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 1) {
                          return 'נא להזין מספר חיובי';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minPressureController,
                      decoration: const InputDecoration(
                        labelText: 'לחץ מינימלי (bar)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 1) {
                          return 'נא להזין מספר חיובי';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alertThresholdMinutesController,
                      decoration: const InputDecoration(
                        labelText: 'סף התראה (דקות)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notifications_active),
                        helperText: 'התראה תופיע כשנשאר פחות זמן מזה',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 0) {
                          return 'נא להזין מספר חיובי';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _createEvent(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('צור אירוע'),
            ),
          ],
        ),
      ),
    );
  }
}
