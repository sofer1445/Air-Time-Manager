import 'package:air_time_manager/features/event/widgets/status_cards.dart';
import 'package:air_time_manager/features/teams/teams_screen.dart';
import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/common/formatters/duration_format.dart';
import 'package:air_time_manager/data/models/air_log.dart';
import 'package:air_time_manager/data/models/event.dart';
import 'package:air_time_manager/data/models/event_summary.dart';
import 'package:air_time_manager/data/models/step.dart';
import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ניהול זמן אוויר'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'פרטי אירוע'),
              Tab(text: 'צוותים'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: StreamBuilder<EventSummary>(
                  stream: AppScope.of(context).repo.watchEventSummary(),
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    final alertsCount = summary?.alertsCount ?? 0;

                    return Column(
                      children: [
                        if (alertsCount > 0) ...[
                          _AlertsBanner(alertsCount: alertsCount),
                          const SizedBox(height: 12),
                        ],
                        StatusCardsRow(
                          remainingTime: summary == null
                              ? '--:--:--'
                              : formatDurationHms(summary.remainingTime),
                          requiredExitTime: summary == null
                              ? '--:--'
                              : summary.requiredExitTime.format(context),
                          alertsCount: alertsCount,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              const Expanded(
                child: TabBarView(
                  children: [_EventDetailsTab(), TeamsScreen()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailsTab extends StatelessWidget {
  const _EventDetailsTab();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<Event?>(
              stream: repo.watchCurrentEvent(),
              builder: (context, snapshot) {
                final event = snapshot.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'פרטי אירוע',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (event == null) ...[
                      const Text('אין אירוע פעיל כרגע (דמו מקומי).'),
                    ] else ...[
                      Text('שם: ${event.name}'),
                      Text(
                        'נוצר ב־${TimeOfDay.fromDateTime(event.createdAt).format(context)}',
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<EventStep>>(
                        stream: repo.watchSteps(eventId: event.id),
                        builder: (context, stepsSnapshot) {
                          final steps =
                              stepsSnapshot.data ?? const <EventStep>[];
                          final lastStep = _latestStep(steps);
                          final lastStepText = lastStep == null
                              ? '—'
                              : '${_stepTypeLabel(lastStep.type)} (${TimeOfDay.fromDateTime(lastStep.createdAt).format(context)})';

                          return Text(
                            'צעדים: ${steps.length} | אחרון: $lastStepText',
                          );
                        },
                      ),
                      StreamBuilder<List<AirLog>>(
                        stream: repo.watchAirLogs(eventId: event.id),
                        builder: (context, logsSnapshot) {
                          final logs = logsSnapshot.data ?? const <AirLog>[];
                          return Text('יומן: ${logs.length} רשומות');
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertsBanner extends StatelessWidget {
  final int alertsCount;

  const _AlertsBanner({required this.alertsCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.notifications_active, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'התראה: $alertsCount צוותים על סף יציאה!',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

EventStep? _latestStep(List<EventStep> steps) {
  if (steps.isEmpty) return null;
  EventStep latest = steps.first;
  for (final step in steps.skip(1)) {
    if (step.createdAt.isAfter(latest.createdAt)) {
      latest = step;
    }
  }
  return latest;
}

String _stepTypeLabel(EventStepType type) {
  return switch (type) {
    EventStepType.start => 'התחלה',
    EventStepType.arrive => 'הגעה',
    EventStepType.exit => 'יציאה',
    EventStepType.washing => 'שטיפה',
  };
}
