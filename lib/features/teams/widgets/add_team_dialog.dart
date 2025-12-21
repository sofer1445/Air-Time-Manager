import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/features/teams/widgets/oxygen_calculator_dialog.dart';
import 'package:flutter/material.dart';

class AddTeamDialog extends StatefulWidget {
  const AddTeamDialog({super.key});

  @override
  State<AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<AddTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minutesController = TextEditingController(text: '60');
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _addTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isAdding = true);

    try {
      final minutes = int.parse(_minutesController.text);
      final initialTimer = Duration(minutes: minutes);

      final repo = AppScope.of(context).repo;
      await repo.addTeam(
        name: _nameController.text.trim(),
        initialTimer: initialTimer,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בהוספת צוות: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הוספת צוות חדש'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'שם הצוות',
                hintText: 'למשל: צוות דלתא',
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'נא להזין שם צוות';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'זמן אוויר (דקות)',
                      prefixIcon: Icon(Icons.timer),
                      helperText: 'זמן בדקות',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num <= 0) {
                        return 'נא להזין מספר חיובי';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _addTeam(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (_) => const OxygenCalculatorDialog(),
                    );
                    if (result != null) {
                      _minutesController.text = result.toString();
                    }
                  },
                  icon: const Icon(Icons.calculate),
                  tooltip: 'מחשבון בלון חמצן',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _isAdding ? null : _addTeam,
          child: _isAdding
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('הוסף'),
        ),
      ],
    );
  }
}
