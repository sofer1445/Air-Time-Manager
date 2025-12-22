import 'dart:async';

import 'package:air_time_manager/data/models/air_log.dart';
import 'package:air_time_manager/data/models/event.dart';
import 'package:air_time_manager/data/models/event_summary.dart';
import 'package:air_time_manager/data/models/member.dart';
import 'package:air_time_manager/data/models/parameters.dart';
import 'package:air_time_manager/data/models/step.dart';
import 'package:air_time_manager/data/models/step_type.dart';
import 'package:air_time_manager/data/models/team.dart';
import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:air_time_manager/services/step_fsm.dart';
import 'package:flutter/material.dart';

/// Local-only repository for Phase 1/early Phase 2.
///
/// Exposes Streams that behave like realtime listeners.
/// This makes it easy to swap the implementation to Firestore later
/// without changing the UI structure.
class InMemoryAirTimeRepository implements AirTimeRepository {
  final _eventsController = StreamController<List<Event>>.broadcast();
  final _currentEventController = StreamController<Event?>.broadcast();
  final _membersController = StreamController<List<Member>>.broadcast();
  final _stepsController = StreamController<List<EventStep>>.broadcast();
  final _airLogsController = StreamController<List<AirLog>>.broadcast();
  final _parametersController = StreamController<Parameters>.broadcast();

  final _eventSummaryController = StreamController<EventSummary>.broadcast();
  final _teamsController = StreamController<List<Team>>.broadcast();

  final List<Event> _events = [
    Event(
      id: 'event_1',
      name: 'אירוע דמו',
      createdAt: DateTime(2025, 12, 18, 10, 0),
    ),
  ];

  final Event _currentEvent = Event(
    id: 'event_1',
    name: 'אירוע דמו',
    createdAt: DateTime(2025, 12, 18, 10, 0),
  );

  late EventSummary _eventSummary;

  final List<Team> _teams = [];

  final Map<String, Duration> _undoSnapshotByTeamId = {};
  final Map<String, Map<String, Duration>> _undoMembersSnapshotByTeamId = {};
  final Map<String, _TeamStepSnapshot> _undoStepSnapshotByTeamId = {};
  int _airLogSeq = 2;
  int _stepSeq = 2;
  Timer? _ticker;

  final List<Member> _members = [];

  final List<EventStep> _steps = [
    EventStep(
      id: 's1',
      eventId: 'event_1',
      teamId: null,
      type: EventStepType.start,
      createdAt: DateTime(2025, 12, 18, 10, 0),
    ),
  ];

  final List<AirLog> _airLogs = [
    AirLog(
      id: 'log1',
      eventId: 'event_1',
      teamId: 'alpha',
      memberId: 'm1',
      note: 'התחלת אירוע',
      createdAt: DateTime(2025, 12, 18, 10, 0),
    ),
  ];

  final Parameters _parameters = const Parameters(
    minWashingTime: Duration(minutes: 5),
    minPressureBar: 200,
    maxPressureBar: 300,
  );

  InMemoryAirTimeRepository() {
    _seedMembers();
    _seedTeams();
    _eventSummary = _computeEventSummary();

    // Seed initial values.
    _eventsController.add(List.unmodifiable(_events));
    _currentEventController.add(_currentEvent);
    _membersController.add(List.unmodifiable(_members));
    _stepsController.add(List.unmodifiable(_steps));
    _airLogsController.add(List.unmodifiable(_airLogs));
    _parametersController.add(_parameters);

    _eventSummaryController.add(_eventSummary);
    _teamsController.add(List.unmodifiable(_teams));

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _seedMembers() {
    const seeds = [
      ('m1', 'alpha', 'לוחם 1', Duration(minutes: 75)),
      ('m2', 'alpha', 'לוחם 2', Duration(minutes: 63)),
      ('m3', 'bravo', 'לוחם 3', Duration(minutes: 60)),
      ('m4', 'charlie', 'לוחם 4', Duration(minutes: 58)),
    ];

    for (final (id, teamId, name, total) in seeds) {
      _members.add(
        Member(
          id: id,
          teamId: teamId,
          name: name,
          remainingTime: total,
          totalTime: total,
        ),
      );
    }
  }

  void _seedTeams() {
    // Seed team timers based on the minimum member remaining time per team.
    const teams = [
      ('alpha', 'צוות אלפא'),
      ('bravo', 'צוות בראבו'),
      ('charlie', 'צוות צ׳רלי'),
    ];

    for (final (id, name) in teams) {
      final durations = _members
          .where((m) => m.teamId == id)
          .map((m) => m.remainingTime)
          .toList(growable: false);
      final timer = _minDurationOrZero(durations);
      _teams.add(Team(id: id, name: name, timer: timer, currentStep: null));
    }
  }

  Duration _minDurationOrZero(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    var min = durations.first;
    for (final d in durations.skip(1)) {
      if (d < min) min = d;
    }
    return min;
  }

  void _onTick() {
    var changed = false;
    var membersChanged = false;

    for (var i = 0; i < _teams.length; i++) {
      final team = _teams[i];
      if (!team.isRunning) continue;

      final affectedMemberIndexes = <int>[];
      for (var mi = 0; mi < _members.length; mi++) {
        if (_members[mi].teamId == team.id) affectedMemberIndexes.add(mi);
      }

      if (team.timer <= Duration.zero) {
        _teams[i] = Team(
          id: team.id,
          name: team.name,
          timer: Duration.zero,
          isRunning: false,
          currentStep: team.currentStep,
        );
        _undoSnapshotByTeamId.remove(team.id);
        _undoMembersSnapshotByTeamId.remove(team.id);
        for (final mi in affectedMemberIndexes) {
          final m = _members[mi];
          if (m.remainingTime != Duration.zero) {
            _members[mi] = Member(
              id: m.id,
              teamId: m.teamId,
              name: m.name,
              remainingTime: Duration.zero,
              totalTime: m.totalTime,
            );
            membersChanged = true;
          }
        }
        changed = true;
        continue;
      }

      final newTimer = team.timer - const Duration(seconds: 1);
      _teams[i] = Team(
        id: team.id,
        name: team.name,
        timer: newTimer < Duration.zero ? Duration.zero : newTimer,
        isRunning: true,
        currentStep: team.currentStep,
      );

      for (final mi in affectedMemberIndexes) {
        final m = _members[mi];
        if (m.remainingTime <= Duration.zero) continue;
        final next = m.remainingTime - const Duration(seconds: 1);
        _members[mi] = Member(
          id: m.id,
          teamId: m.teamId,
          name: m.name,
          remainingTime: next < Duration.zero ? Duration.zero : next,
          totalTime: m.totalTime,
        );
        membersChanged = true;
      }

      changed = true;
    }

    if (!changed && !membersChanged) return;
    _emitTeams();
    if (membersChanged) {
      _membersController.add(List.unmodifiable(_members));
    }
    _emitEventSummaryIfChanged();
  }

  void _emitTeams() {
    _teamsController.add(List.unmodifiable(_teams));
  }

  EventSummary _computeEventSummary() {
    final remainingTime = _teams.isEmpty
        ? Duration.zero
        : _minDurationOrZero(
            _teams.map((t) => t.timer).toList(growable: false),
          );
    final requiredExitTime = TimeOfDay.fromDateTime(
      DateTime.now().add(remainingTime),
    );
    final alertsCount = _teams
        .where((t) => t.timer <= _parameters.alertThreshold)
        .length;

    return EventSummary(
      remainingTime: remainingTime,
      requiredExitTime: requiredExitTime,
      alertsCount: alertsCount,
      alertThreshold: _parameters.alertThreshold,
    );
  }

  void _emitEventSummaryIfChanged() {
    final next = _computeEventSummary();
    if (next.remainingTime == _eventSummary.remainingTime &&
        next.requiredExitTime == _eventSummary.requiredExitTime &&
        next.alertsCount == _eventSummary.alertsCount) {
      return;
    }
    _eventSummary = next;
    _eventSummaryController.add(_eventSummary);
  }

  void _appendAirLog({required String teamId, required String note}) {
    final log = AirLog(
      id: 'log$_airLogSeq',
      eventId: _currentEvent.id,
      teamId: teamId,
      memberId: null,
      note: note,
      createdAt: DateTime.now(),
    );
    _airLogSeq++;
    _airLogs.add(log);
    _airLogsController.add(List.unmodifiable(_airLogs));
  }

  @override
  Stream<EventSummary> watchEventSummary() {
    return Stream<EventSummary>.multi((controller) {
      controller.add(_eventSummary);
      final sub = _eventSummaryController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<Team>> watchTeams() {
    return Stream<List<Team>>.multi((controller) {
      controller.add(List.unmodifiable(_teams));
      final sub = _teamsController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<Event>> watchEvents() {
    return Stream<List<Event>>.multi((controller) {
      controller.add(List.unmodifiable(_events));
      final sub = _eventsController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<Event?> watchCurrentEvent() {
    return Stream<Event?>.multi((controller) {
      controller.add(_currentEvent);
      final sub = _currentEventController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<Member>> watchMembers({required String teamId}) {
    return Stream<List<Member>>.multi((controller) {
      controller.add(
        List.unmodifiable(_members.where((m) => m.teamId == teamId)),
      );
      final sub = _membersController.stream.listen(
        (all) => controller.add(
          List.unmodifiable(all.where((m) => m.teamId == teamId)),
        ),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<Member>> watchAllMembers() {
    return Stream<List<Member>>.multi((controller) {
      controller.add(List.unmodifiable(_members));
      final sub = _membersController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<EventStep>> watchSteps({required String eventId}) {
    return Stream<List<EventStep>>.multi((controller) {
      controller.add(
        List.unmodifiable(_steps.where((s) => s.eventId == eventId)),
      );
      final sub = _stepsController.stream.listen(
        (all) => controller.add(
          List.unmodifiable(all.where((s) => s.eventId == eventId)),
        ),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<AirLog>> watchAirLogs({required String eventId}) {
    return Stream<List<AirLog>>.multi((controller) {
      controller.add(
        List.unmodifiable(_airLogs.where((l) => l.eventId == eventId)),
      );
      final sub = _airLogsController.stream.listen(
        (all) => controller.add(
          List.unmodifiable(all.where((l) => l.eventId == eventId)),
        ),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<Parameters> watchParameters() {
    return Stream<Parameters>.multi((controller) {
      controller.add(_parameters);
      final sub = _parametersController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> toggleTeamTimer({required String teamId}) async {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) return;

    final team = _teams[index];
    if (team.isRunning) {
      // Stop.
      _teams[index] = Team(
        id: team.id,
        name: team.name,
        timer: team.timer,
        isRunning: false,
        currentStep: team.currentStep,
      );
      _undoSnapshotByTeamId.remove(team.id);
      _undoMembersSnapshotByTeamId.remove(team.id);
      _appendAirLog(teamId: team.id, note: 'עצירת טיימר (דמו)');
    } else {
      // Start.
      _undoSnapshotByTeamId[team.id] = team.timer;
      _undoMembersSnapshotByTeamId[team.id] = {
        for (final m in _members.where((m) => m.teamId == team.id))
          m.id: m.remainingTime,
      };
      _teams[index] = Team(
        id: team.id,
        name: team.name,
        timer: team.timer,
        isRunning: true,
        currentStep: team.currentStep,
      );
      _appendAirLog(teamId: team.id, note: 'התחלת טיימר (דמו)');
    }

    _emitTeams();
    _membersController.add(List.unmodifiable(_members));
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> undoTeamTimer({required String teamId}) async {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) return;

    final snapshot = _undoSnapshotByTeamId[teamId];
    if (snapshot == null) return;

    final membersSnapshot = _undoMembersSnapshotByTeamId[teamId];

    final team = _teams[index];
    _teams[index] = Team(
      id: team.id,
      name: team.name,
      timer: snapshot,
      isRunning: false,
      currentStep: team.currentStep,
    );
    _undoSnapshotByTeamId.remove(teamId);
    _undoMembersSnapshotByTeamId.remove(teamId);

    if (membersSnapshot != null) {
      for (var mi = 0; mi < _members.length; mi++) {
        final m = _members[mi];
        if (m.teamId != teamId) continue;
        final restored = membersSnapshot[m.id];
        if (restored == null) continue;
        _members[mi] = Member(
          id: m.id,
          teamId: m.teamId,
          name: m.name,
          remainingTime: restored,
          totalTime: m.totalTime,
        );
      }
      _membersController.add(List.unmodifiable(_members));
    }

    _appendAirLog(teamId: team.id, note: 'ביטול הפעלה (דמו)');
    _emitTeams();
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    await _eventsController.close();
    await _currentEventController.close();
    await _membersController.close();
    await _stepsController.close();
    await _airLogsController.close();
    await _parametersController.close();
    await _eventSummaryController.close();
    await _teamsController.close();
  }

  @override
  Future<void> advanceTeamStep({required String teamId}) async {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) return;

    final team = _teams[index];
    final snapshot = _TeamStepSnapshot(
      teamTimer: team.timer,
      isRunning: team.isRunning,
      currentStep: team.currentStep,
      memberRemainingById: {
        for (final m in _members.where((m) => m.teamId == teamId))
          m.id: m.remainingTime,
      },
    );
    _undoStepSnapshotByTeamId[teamId] = snapshot;

    final StepType nextStep = StepFsm.nextStep(team.currentStep)!;
    final shouldRun = StepFsm.shouldRunTimerForStep(nextStep);

    _teams[index] = Team(
      id: team.id,
      name: team.name,
      timer: team.timer,
      isRunning: shouldRun,
      currentStep: nextStep,
    );

    EventStepType legacyTypeForStep(StepType step) {
      return switch (step) {
        StepType.entry => EventStepType.start,
        StepType.arrival => EventStepType.arrive,
        StepType.exit => EventStepType.exit,
        StepType.washStart || StepType.washEnd => EventStepType.washing,
      };
    }

    _steps.add(
      EventStep(
        id: 's$_stepSeq',
        eventId: _currentEvent.id,
        teamId: teamId,
        type: legacyTypeForStep(nextStep),
        createdAt: DateTime.now(),
      ),
    );
    _stepSeq++;

    _appendAirLog(teamId: teamId, note: 'צעד: ${nextStep.displayName}');

    _emitTeams();
    _membersController.add(List.unmodifiable(_members));
    _stepsController.add(List.unmodifiable(_steps));
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> undoTeamStep({required String teamId}) async {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) return;

    final snapshot = _undoStepSnapshotByTeamId[teamId];
    if (snapshot == null) return;

    final team = _teams[index];
    _teams[index] = Team(
      id: team.id,
      name: team.name,
      timer: snapshot.teamTimer,
      isRunning: snapshot.isRunning,
      currentStep: snapshot.currentStep,
    );
    _undoStepSnapshotByTeamId.remove(teamId);

    for (var mi = 0; mi < _members.length; mi++) {
      final m = _members[mi];
      if (m.teamId != teamId) continue;
      final restored = snapshot.memberRemainingById[m.id];
      if (restored == null) continue;
      _members[mi] = Member(
        id: m.id,
        teamId: m.teamId,
        name: m.name,
        remainingTime: restored,
        totalTime: m.totalTime,
      );
    }
    _membersController.add(List.unmodifiable(_members));
    _appendAirLog(teamId: teamId, note: 'בטל צעד (דמו)');
    _emitTeams();
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> createEvent({
    required String name,
    required Duration minWashingTime,
    required int minPressureBar,
    required Duration alertThreshold,
  }) async {
    final now = DateTime.now();
    final newEvent = Event(
      id: 'event_${now.millisecondsSinceEpoch}',
      name: name,
      createdAt: now,
    );
    _events.add(newEvent);
    _eventsController.add(List.unmodifiable(_events));

    // Update current event
    _currentEventController.add(newEvent);

    // Update parameters
    final newParams = Parameters(
      minWashingTime: minWashingTime,
      minPressureBar: minPressureBar,
      maxPressureBar: 300,
      alertThreshold: alertThreshold,
    );
    _parametersController.add(newParams);

    // Reset teams and members for new event
    _teams.clear();
    _members.clear();
    _steps.clear();
    _airLogs.clear();

    // Add initial step
    _steps.add(EventStep(
      id: 's_${_stepSeq++}',
      eventId: newEvent.id,
      teamId: null,
      type: EventStepType.start,
      createdAt: now,
    ));

    _teamsController.add(List.unmodifiable(_teams));
    _membersController.add(List.unmodifiable(_members));
    _stepsController.add(List.unmodifiable(_steps));
    _airLogsController.add(List.unmodifiable(_airLogs));
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> setCurrentEvent({required String eventId}) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    _currentEventController.add(event);
  }

  @override
  Future<void> addTeam({
    required String name,
    Duration? initialTimer,
  }) async {
    final teamId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    final team = Team(
      id: teamId,
      name: name,
      timer: initialTimer ?? Duration.zero,
      currentStep: null,
    );
    _teams.add(team);
    _teamsController.add(List.unmodifiable(_teams));
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> removeTeam({required String teamId}) async {
    _teams.removeWhere((t) => t.id == teamId);
    _members.removeWhere((m) => m.teamId == teamId);
    _teamsController.add(List.unmodifiable(_teams));
    _membersController.add(List.unmodifiable(_members));
    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> addMember({
    required String teamId,
    required String name,
    required Duration totalTime,
  }) async {
    final memberId = 'm_${DateTime.now().millisecondsSinceEpoch}';
    final member = Member(
      id: memberId,
      teamId: teamId,
      name: name,
      remainingTime: totalTime,
      totalTime: totalTime,
    );
    _members.add(member);
    _membersController.add(List.unmodifiable(_members));

    // Update team timer to be minimum of all members
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final teamMembers = _members.where((m) => m.teamId == teamId);
      final minTime = _minDurationOrZero(
        teamMembers.map((m) => m.remainingTime).toList(),
      );
      final team = _teams[teamIndex];
      _teams[teamIndex] = Team(
        id: team.id,
        name: team.name,
        timer: minTime,
        isRunning: team.isRunning,
        currentStep: team.currentStep,
      );
      _teamsController.add(List.unmodifiable(_teams));
    }

    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> removeMember({required String memberId}) async {
    final member = _members.firstWhere((m) => m.id == memberId);
    final teamId = member.teamId;

    _members.removeWhere((m) => m.id == memberId);
    _membersController.add(List.unmodifiable(_members));

    // Update team timer
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final teamMembers = _members.where((m) => m.teamId == teamId);
      final minTime = _minDurationOrZero(
        teamMembers.map((m) => m.remainingTime).toList(),
      );
      final team = _teams[teamIndex];
      _teams[teamIndex] = Team(
        id: team.id,
        name: team.name,
        timer: minTime,
        isRunning: team.isRunning,
        currentStep: team.currentStep,
      );
      _teamsController.add(List.unmodifiable(_teams));
    }

    _emitEventSummaryIfChanged();
  }

  @override
  Future<void> updateMemberTime({
    required String memberId,
    required Duration newTotalTime,
  }) async {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index < 0) return;

    final member = _members[index];
    _members[index] = Member(
      id: member.id,
      teamId: member.teamId,
      name: member.name,
      remainingTime: newTotalTime,
      totalTime: newTotalTime,
    );
    _membersController.add(List.unmodifiable(_members));

    // Update team timer
    final teamId = member.teamId;
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final teamMembers = _members.where((m) => m.teamId == teamId);
      final minTime = _minDurationOrZero(
        teamMembers.map((m) => m.remainingTime).toList(),
      );
      final team = _teams[teamIndex];
      _teams[teamIndex] = Team(
        id: team.id,
        name: team.name,
        timer: minTime,
        isRunning: team.isRunning,
        currentStep: team.currentStep,
      );
      _teamsController.add(List.unmodifiable(_teams));
    }

    _emitEventSummaryIfChanged();
  }
}

class _TeamStepSnapshot {
  final Duration teamTimer;
  final bool isRunning;
  final StepType? currentStep;
  final Map<String, Duration> memberRemainingById;

  const _TeamStepSnapshot({
    required this.teamTimer,
    required this.isRunning,
    required this.currentStep,
    required this.memberRemainingById,
  });
}
