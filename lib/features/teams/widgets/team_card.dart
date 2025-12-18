import 'package:flutter/material.dart';

class TeamCardModel {
  final String name;
  final String timerText;
  final String? membersText;
  final String primaryActionText;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onUndo;

  const TeamCardModel({
    required this.name,
    required this.timerText,
    this.membersText,
    required this.primaryActionText,
    required this.onPrimaryAction,
    required this.onUndo,
  });
}

class TeamCard extends StatelessWidget {
  final TeamCardModel model;

  const TeamCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(model.name, style: Theme.of(context).textTheme.titleLarge),
            if (model.membersText != null) ...[
              const SizedBox(height: 4),
              Text(
                model.membersText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: Text(
                model.timerText,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: model.onPrimaryAction,
                    child: Text(model.primaryActionText),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: model.onUndo,
                  icon: const Icon(Icons.undo),
                  label: const Text('בטל'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
