import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/data/models/event.dart';
import 'package:air_time_manager/features/event/create_event_screen.dart';
import 'package:air_time_manager/features/event/event_screen.dart';
import 'package:flutter/material.dart';

/// מסך בחירה - האם להמשיך אירוע קיים או ליצור חדש
class EventSelectionScreen extends StatelessWidget {
  const EventSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('בחירת אירוע'),
      ),
      body: StreamBuilder<List<Event>>(
        stream: repo.watchEvents(),
        builder: (context, snapshot) {
          final events = snapshot.data ?? const <Event>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: InkWell(
                  onTap: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateEventScreen(),
                      ),
                    );
                    if (created == true && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const EventScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'צור אירוע חדש',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'התחל אימון או משימה חדשה',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'אירועים קיימים',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final event in events) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.name),
                      subtitle: Text(
                        'נוצר ב־${TimeOfDay.fromDateTime(event.createdAt).format(context)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await repo.setCurrentEvent(eventId: event.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const EventScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
