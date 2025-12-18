import 'package:flutter/material.dart';

class StatusCardsRow extends StatelessWidget {
  final String remainingTime;
  final String requiredExitTime;
  final int alertsCount;

  const StatusCardsRow({
    super.key,
    required this.remainingTime,
    required this.requiredExitTime,
    required this.alertsCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final children = [
          _StatusCard(
            title: 'זמן נותר',
            value: remainingTime,
            icon: Icons.hourglass_bottom,
          ),
          _StatusCard(
            title: 'שעת יציאה נדרשת',
            value: requiredExitTime,
            icon: Icons.directions_run,
          ),
          _StatusCard(
            title: 'התראות',
            value: alertsCount.toString(),
            icon: Icons.warning_amber,
          ),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final child in children)
                SizedBox(width: constraints.maxWidth, child: child),
            ],
          );
        }

        return Row(
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
}
