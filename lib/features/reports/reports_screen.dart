import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/common/formatters/duration_format.dart';
import 'package:air_time_manager/data/models/air_log.dart';
import 'package:air_time_manager/data/models/event.dart';
import 'package:air_time_manager/data/models/member.dart';
import 'package:air_time_manager/data/models/step.dart';
import 'package:air_time_manager/data/models/team.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('דוחות וסטטיסטיקות'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'סיכום', icon: Icon(Icons.assessment)),
              Tab(text: 'צוותים', icon: Icon(Icons.groups)),
              Tab(text: 'יומן', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SummaryTab(),
            _TeamsStatsTab(),
            _LogsTab(),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<Event?>(
          stream: repo.watchCurrentEvent(),
          builder: (context, snapshot) {
            final event = snapshot.data;
            if (event == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('אין אירוע פעיל'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פרטי אירוע',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'שם', value: event.name),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'תאריך',
                      value:
                          '${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'שעה',
                      value: TimeOfDay.fromDateTime(event.createdAt)
                          .format(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Team>>(
          stream: repo.watchTeams(),
          builder: (context, teamsSnap) {
            final teams = teamsSnap.data ?? [];
            return StreamBuilder<List<Member>>(
              stream: repo.watchAllMembers(),
              builder: (context, membersSnap) {
                final members = membersSnap.data ?? [];
                
                final totalMembers = members.length;
                final totalTeams = teams.length;
                final totalAirTime = members.fold<Duration>(
                  Duration.zero,
                  (sum, m) => sum + m.totalTime,
                );
                final remainingAirTime = members.fold<Duration>(
                  Duration.zero,
                  (sum, m) => sum + m.remainingTime,
                );
                final usedAirTime = totalAirTime - remainingAirTime;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'סטטיסטיקות כלליות',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'מספר צוותים',
                          value: '$totalTeams',
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'מספר לוחמים',
                          value: '$totalMembers',
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'זמן אוויר כולל',
                          value: formatDurationHms(totalAirTime),
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'זמן אוויר שנוצל',
                          value: formatDurationHms(usedAirTime),
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'זמן אוויר נותר',
                          value: formatDurationHms(remainingAirTime),
                        ),
                        const SizedBox(height: 12),
                        if (totalAirTime > Duration.zero)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                value: usedAirTime.inSeconds /
                                    totalAirTime.inSeconds,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'שימוש: ${(usedAirTime.inSeconds / totalAirTime.inSeconds * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TeamsStatsTab extends StatelessWidget {
  const _TeamsStatsTab();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return StreamBuilder<List<Team>>(
      stream: repo.watchTeams(),
      builder: (context, snapshot) {
        final teams = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'ביצועי צוותים',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final team in teams) ...[
              StreamBuilder<List<Member>>(
                stream: repo.watchMembers(teamId: team.id),
                builder: (context, membersSnap) {
                  final members = membersSnap.data ?? [];
                  final totalTime = members.fold<Duration>(
                    Duration.zero,
                    (sum, m) => sum + m.totalTime,
                  );
                  final remainingTime = members.fold<Duration>(
                    Duration.zero,
                    (sum, m) => sum + m.remainingTime,
                  );
                  final usedTime = totalTime - remainingTime;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'לוחמים',
                            value: '${members.length}',
                          ),
                          const SizedBox(height: 4),
                          _InfoRow(
                            label: 'זמן כולל',
                            value: formatDurationHms(totalTime),
                          ),
                          const SizedBox(height: 4),
                          _InfoRow(
                            label: 'זמן שנוצל',
                            value: formatDurationHms(usedTime),
                          ),
                          const SizedBox(height: 4),
                          _InfoRow(
                            label: 'זמן נותר',
                            value: formatDurationHms(remainingTime),
                          ),
                          if (totalTime > Duration.zero) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: usedTime.inSeconds / totalTime.inSeconds,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(usedTime.inSeconds / totalTime.inSeconds * 100).toStringAsFixed(1)}% שימוש',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return StreamBuilder<Event?>(
      stream: repo.watchCurrentEvent(),
      builder: (context, eventSnap) {
        final event = eventSnap.data;
        if (event == null) {
          return const Center(child: Text('אין אירוע פעיל'));
        }

        return StreamBuilder<List<AirLog>>(
          stream: repo.watchAirLogs(eventId: event.id),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return const Center(
                child: Text('אין רשומות ביומן'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[logs.length - 1 - index]; // הפוך - החדש ביותר למעלה
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(log.note),
                    subtitle: Text(
                      TimeOfDay.fromDateTime(log.createdAt).format(context),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
