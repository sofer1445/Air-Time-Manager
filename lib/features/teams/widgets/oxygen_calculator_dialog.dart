import 'package:flutter/material.dart';

/// מחשבון זמן בלון חמצן
/// נוסחה: זמן (דקות) = (לחץ בבלון × נפח הבלון) / קצב צריכה
class OxygenCalculatorDialog extends StatefulWidget {
  const OxygenCalculatorDialog({super.key});

  @override
  State<OxygenCalculatorDialog> createState() => _OxygenCalculatorDialogState();
}

class _OxygenCalculatorDialogState extends State<OxygenCalculatorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pressureController = TextEditingController(text: '200');
  final _volumeController = TextEditingController(text: '7');
  final _consumptionController = TextEditingController(text: '40');
  
  int? _calculatedMinutes;

  @override
  void dispose() {
    _pressureController.dispose();
    _volumeController.dispose();
    _consumptionController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pressure = double.parse(_pressureController.text);
    final volume = double.parse(_volumeController.text);
    final consumption = double.parse(_consumptionController.text);

    // נוסחה: זמן = (לחץ × נפח) / קצב צריכה
    final minutes = (pressure * volume) / consumption;

    setState(() {
      _calculatedMinutes = minutes.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calculate),
          SizedBox(width: 8),
          Text('מחשבון בלון חמצן'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'חישוב זמן אוויר לפי פרמטרי הבלון',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pressureController,
                decoration: const InputDecoration(
                  labelText: 'לחץ בבלון (bar)',
                  prefixIcon: Icon(Icons.speed),
                  helperText: 'לחץ נוכחי בבר',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'נא להזין מספר חיובי';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _calculatedMinutes = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volumeController,
                decoration: const InputDecoration(
                  labelText: 'נפח הבלון (ליטר)',
                  prefixIcon: Icon(Icons.air),
                  helperText: 'נפח הבלון בליטרים',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'נא להזין מספר חיובי';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _calculatedMinutes = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _consumptionController,
                decoration: const InputDecoration(
                  labelText: 'קצב צריכה (ליטר/דקה)',
                  prefixIcon: Icon(Icons.opacity),
                  helperText: 'קצב צריכת האוויר',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'נא להזין מספר חיובי';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _calculatedMinutes = null),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('חשב זמן אוויר'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_calculatedMinutes != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 48,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'זמן אוויר משוער',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_calculatedMinutes דקות',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(${(_calculatedMinutes! / 60).toStringAsFixed(1)} שעות)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('סגור'),
        ),
        if (_calculatedMinutes != null)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_calculatedMinutes),
            child: const Text('השתמש בזמן זה'),
          ),
      ],
    );
  }
}
