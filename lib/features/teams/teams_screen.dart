import 'package:air_time_manager/features/teams/widgets/team_card.dart';
import 'package:air_time_manager/features/teams/widgets/add_team_dialog.dart';
import 'package:air_time_manager/features/teams/widgets/add_member_dialog.dart';
import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/common/formatters/duration_format.dart';
import 'package:air_time_manager/data/models/member.dart';
import 'package:air_time_manager/data/models/team.dart';
import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:air_time_manager/services/step_fsm.dart';
import 'package:flutter/material.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return StreamBuilder<List<Team>>(
      stream: repo.watchTeams(),
      builder: (context, snapshot) {
        final teams = snapshot.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'פיקוח צוותים באירוע',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const AddTeamDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף צוות'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final team in teams) ...[
              StreamBuilder<List<Member>>(
                stream: repo.watchMembers(teamId: team.id),
                builder: (context, membersSnapshot) {
                  final count = membersSnapshot.data?.length;
                  final membersText = count == null ? null : 'לוחמים: $count';

                  final primaryActionText = StepFsm.buttonLabel(team.currentStep);
                  final canUndo = StepFsm.canUndo(team.currentStep);
                  
                  // קביעת סטטוס וצבע לפי שלב נוכחי
                  String? statusText;
                  Color? statusColor;
                  String? icon;
                  
                  if (team.currentStep != null) {
                    statusText = StepFsm.statusLabelForStep(team.currentStep!);
                    icon = StepFsm.iconForStep(team.currentStep!);
                    statusColor = team.isRunning
                        ? Colors.green
                        : Colors.orange;
                  }

                  return TeamCard(
                    model: TeamCardModel(
                      name: team.name,
                      timerText: formatDurationHms(team.timer),
                      membersText: membersText,
                      primaryActionText: primaryActionText,
                      statusText: statusText,
                      statusColor: statusColor,
                      icon: icon,
                      canUndo: canUndo,
                      onPrimaryAction: () {
                        repo.advanceTeamStep(teamId: team.id);
                      },
                      onUndo: () => repo.undoTeamStep(teamId: team.id),
                      onAddMember: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => AddMemberDialog(
                            teamId: team.id,
                            teamName: team.name,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            _MembersTimeTable(repo: repo, teams: teams),
          ],
        );
      },
    );
  }
}

class _MembersTimeTable extends StatelessWidget {
  final AirTimeRepository repo;
  final List<Team> teams;

  const _MembersTimeTable({required this.repo, required this.teams});

  @override
  Widget build(BuildContext context) {
    final teamNameById = {for (final t in teams) t.id: t.name};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Member>>(
          stream: repo.watchAllMembers(),
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <Member>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ניהול זמן אוויר',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'כאן רואים את זמן האוויר של הלוחמים במשימה (דמו מקומי).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  const Text('אין לוחמים כרגע')
                else
                  for (final m in members) ...[
                    _MemberRow(
                      name: m.name,
                      teamName: teamNameById[m.teamId] ?? m.teamId,
                      remainingText: formatDurationHms(m.remainingTime),
                      progress: _progress(m),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  double _progress(Member m) {
    final total = m.totalTime.inSeconds;
    if (total <= 0) return 0;
    final value = m.remainingTime.inSeconds / total;
    if (value.isNaN) return 0;
    return value.clamp(0, 1);
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String teamName;
  final String remainingText;
  final double progress;

  const _MemberRow({
    required this.name,
    required this.teamName,
    required this.remainingText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final progressBar = LinearProgressIndicator(value: progress);

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    remainingText,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(teamName, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              progressBar,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Expanded(
              flex: 2,
              child: Text(
                teamName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(flex: 3, child: progressBar),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(
                remainingText,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}
