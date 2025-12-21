import 'package:air_time_manager/data/models/air_log.dart';
import 'package:air_time_manager/data/models/event.dart';
import 'package:air_time_manager/data/models/event_summary.dart';
import 'package:air_time_manager/data/models/member.dart';
import 'package:air_time_manager/data/models/parameters.dart';
import 'package:air_time_manager/data/models/step.dart';
import 'package:air_time_manager/data/models/team.dart';

abstract class AirTimeRepository {
  Stream<EventSummary> watchEventSummary();

  Stream<List<Team>> watchTeams();

  // Phase-2-ready streams (local now, Firestore later)
  Stream<List<Event>> watchEvents();

  Stream<Event?> watchCurrentEvent();

  Stream<List<Member>> watchMembers({required String teamId});

  Stream<List<Member>> watchAllMembers();

  Stream<List<EventStep>> watchSteps({required String eventId});

  Stream<List<AirLog>> watchAirLogs({required String eventId});

  Stream<Parameters> watchParameters();

  // Event management
  Future<void> createEvent({
    required String name,
    required Duration minWashingTime,
    required int minPressureBar,
    required Duration alertThreshold,
  });

  Future<void> setCurrentEvent({required String eventId});

  // Team management
  Future<void> addTeam({
    required String name,
    Duration? initialTimer,
  });

  Future<void> removeTeam({required String teamId});

  // Member management
  Future<void> addMember({
    required String teamId,
    required String name,
    required Duration totalTime,
  });

  Future<void> removeMember({required String memberId});

  Future<void> updateMemberTime({
    required String memberId,
    required Duration newTotalTime,
  });

  // Local functionality now (Firestore later): team-level timer controls.
  Future<void> toggleTeamTimer({required String teamId});

  Future<void> undoTeamTimer({required String teamId});

  // Phase 3: step FSM controls.
  Future<void> advanceTeamStep({required String teamId});

  Future<void> undoTeamStep({required String teamId});

  Future<void> dispose();
}
