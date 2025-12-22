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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firestore-backed repository (Phase 2).
///
/// - Offline-first (uses Firestore local persistence)
/// - Realtime listeners
/// - Seed/demo data (only if empty)
///
/// Notes:
/// - We avoid per-second Firestore writes. When a timer is running we store a
///   `runningSince` timestamp + `timerSeconds` snapshot and compute countdown on
///   the client.
/// - UI stays unchanged; this repo matches the existing `AirTimeRepository` API.
class FirestoreAirTimeRepository implements AirTimeRepository {
  static const String _defaultEventId = 'current';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final _teamsController = StreamController<List<Team>>.broadcast();
  final _eventSummaryController = StreamController<EventSummary>.broadcast();

  Timer? _ticker;

  List<_TeamDoc> _latestTeams = const [];

  FirestoreAirTimeRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance {
    _firestore.settings = const Settings(persistenceEnabled: true);

    _listenTeams();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitTeams();
      _emitEventSummary();
    });
  }

  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  Future<void> ensureSeedData() async {
    // Create event doc.
    final eventRef = _eventRef(_defaultEventId);
    final eventSnap = await eventRef.get();
    if (!eventSnap.exists) {
      await eventRef.set({
        'name': 'אירוע דמו',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Parameters.
    final paramsRef = _parametersRef('current');
    final paramsSnap = await paramsRef.get();
    if (!paramsSnap.exists) {
      await paramsRef.set({
        'minWashingSeconds': const Duration(minutes: 5).inSeconds,
        'minPressureBar': 200,
        'maxPressureBar': 300,
      });
    }

    // Teams.
    final teamsCol = _teamsCol(_defaultEventId);
    final teamsSnap = await teamsCol.limit(1).get();
    if (teamsSnap.docs.isEmpty) {
      final batch = _firestore.batch();

      void addTeam(String id, String name, Duration timer) {
        final ref = teamsCol.doc(id);
        batch.set(ref, {
          'name': name,
          'timerSeconds': timer.inSeconds,
          'isRunning': false,
          'runningSince': null,
          'undoTimerSeconds': null,
          'currentStep': null,
          'undoStep': null,
          'currentStepV2': null,
          'undoStepV2': null,
        });
      }

      addTeam('alpha', 'צוות אלפא', const Duration(minutes: 63));
      addTeam('bravo', 'צוות בראבו', const Duration(minutes: 60));
      addTeam('charlie', 'צוות צ׳רלי', const Duration(minutes: 58));

      await batch.commit();
    }

    // Members per team.
    await _ensureSeedMembers(
      teamId: 'alpha',
      members: const [
        ('m1', 'לוחם 1', Duration(minutes: 75)),
        ('m2', 'לוחם 2', Duration(minutes: 63)),
      ],
    );
    await _ensureSeedMembers(
      teamId: 'bravo',
      members: const [('m3', 'לוחם 3', Duration(minutes: 60))],
    );
    await _ensureSeedMembers(
      teamId: 'charlie',
      members: const [('m4', 'לוחם 4', Duration(minutes: 58))],
    );

    // Steps + AirLogs collections exist implicitly, no need to seed.
  }

  Future<void> _ensureSeedMembers({
    required String teamId,
    required List<(String id, String name, Duration total)> members,
  }) async {
    final membersCol = _membersCol(_defaultEventId, teamId);
    final snap = await membersCol.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final (id, name, total) in members) {
      batch.set(membersCol.doc(id), {
        'name': name,
        'totalSeconds': total.inSeconds,
        'remainingSeconds': total.inSeconds,
        'undoRemainingSeconds': null,
      });
    }
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _eventRef(String eventId) {
    return _firestore.collection('events').doc(eventId);
  }

  CollectionReference<Map<String, dynamic>> _teamsCol(String eventId) {
    return _eventRef(eventId).collection('teams');
  }

  DocumentReference<Map<String, dynamic>> _teamRef(
    String eventId,
    String teamId,
  ) {
    return _teamsCol(eventId).doc(teamId);
  }

  CollectionReference<Map<String, dynamic>> _membersCol(
    String eventId,
    String teamId,
  ) {
    return _teamRef(eventId, teamId).collection('members');
  }

  DocumentReference<Map<String, dynamic>> _parametersRef(String id) {
    return _firestore.collection('parameters').doc(id);
  }

  CollectionReference<Map<String, dynamic>> _stepsCol(String eventId) {
    return _eventRef(eventId).collection('steps');
  }

  CollectionReference<Map<String, dynamic>> _airLogsCol(String eventId) {
    return _eventRef(eventId).collection('airLogs');
  }

  void _listenTeams() {
    _teamsCol(_defaultEventId).snapshots().listen((snapshot) {
      _latestTeams = snapshot.docs
          .map(_TeamDoc.fromQueryDoc)
          .toList(growable: false);
      _emitTeams();
      _emitEventSummary();
    });
  }

  void _emitTeams() {
    final now = DateTime.now();
    final computed = _latestTeams
        .map((t) => t.toTeam(now))
        .toList(growable: false);
    _teamsController.add(computed);
  }

  void _emitEventSummary() async {
    final teams = _latestTeams;
    if (teams.isEmpty) {
      _eventSummaryController.add(
        EventSummary(
          remainingTime: Duration.zero,
          requiredExitTime: TimeOfDay.fromDateTime(DateTime.now()),
          alertsCount: 0,
        ),
      );
      return;
    }

    final params = await watchParameters().first;

    final now = DateTime.now();
    Duration minRemaining = const Duration(days: 3650);
    var alerts = 0;
    for (final t in teams) {
      final remaining = t.remaining(now);
      if (remaining < minRemaining) minRemaining = remaining;
      if (remaining <= params.minWashingDuration) alerts++;
    }

    _eventSummaryController.add(
      EventSummary(
        remainingTime: minRemaining,
        requiredExitTime: TimeOfDay.fromDateTime(
          DateTime.now().add(minRemaining),
        ),
        alertsCount: alerts,
      ),
    );
  }

  @override
  Stream<EventSummary> watchEventSummary() {
    return Stream<EventSummary>.multi((controller) {
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
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (d) => Event(
              id: d.id,
              name: (d.data()['name'] as String?) ?? 'אירוע',
              createdAt:
                  (d.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Stream<Event?> watchCurrentEvent() {
    return _eventRef(_defaultEventId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? const <String, dynamic>{};
      return Event(
        id: snap.id,
        name: (data['name'] as String?) ?? 'אירוע',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  @override
  Stream<List<Member>> watchMembers({required String teamId}) {
    final teamDocStream = _teamRef(
      _defaultEventId,
      teamId,
    ).snapshots().map(_TeamDoc.fromSnapshot);

    return Stream<List<Member>>.multi((controller) {
      _TeamDoc? latestTeam;
      List<_MemberDoc> latestMembers = const [];

      void emit() {
        final now = DateTime.now();
        final team = latestTeam;
        final computed = latestMembers
            .map((m) => m.toMember(now, team: team))
            .toList(growable: false);
        controller.add(computed);
      }

      final subs = <StreamSubscription<dynamic>>[];

      subs.add(
        teamDocStream.listen((t) {
          latestTeam = t;
          emit();
        }, onError: controller.addError),
      );

      subs.add(
        _membersCol(_defaultEventId, teamId).snapshots().listen((snapshot) {
          latestMembers = snapshot.docs
              .map(_MemberDoc.fromDoc)
              .toList(growable: false);
          emit();
        }, onError: controller.addError),
      );

      subs.add(
        Stream<DateTime>.periodic(
          const Duration(seconds: 1),
          (_) => DateTime.now(),
        ).listen((_) {
          if (latestTeam?.isRunning == true) {
            emit();
          }
        }, onError: controller.addError),
      );

      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    });
  }

  @override
  Stream<List<Member>> watchAllMembers() {
    // For MVP we aggregate members across all teams under current event.
    return watchTeams().asyncMap((teams) async {
      final results = <Member>[];
      for (final team in teams) {
        final members = await watchMembers(teamId: team.id).first;
        results.addAll(members);
      }
      return results;
    });
  }

  @override
  Stream<List<EventStep>> watchSteps({required String eventId}) {
    return _stepsCol(
      eventId,
    ).orderBy('createdAt', descending: false).snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) {
            final data = d.data();
            final type = (data['type'] as String?) ?? 'start';
            return EventStep(
              id: d.id,
              eventId: eventId,
              teamId: data['teamId'] as String?,
              type: _stepTypeFromString(type),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<List<AirLog>> watchAirLogs({required String eventId}) {
    return _airLogsCol(
      eventId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) {
            final data = d.data();
            return AirLog(
              id: d.id,
              eventId: eventId,
              teamId: (data['teamId'] as String?) ?? 'unknown',
              memberId: data['memberId'] as String?,
              note: (data['note'] as String?) ?? '',
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<Parameters> watchParameters() {
    return _parametersRef('current').snapshots().map((snap) {
      final data = snap.data() ?? const <String, dynamic>{};
      return Parameters(
        minWashingTime: Duration(
          seconds: (data['minWashingSeconds'] as num?)?.toInt() ?? 300,
        ),
        minPressureBar: (data['minPressureBar'] as num?)?.toInt() ?? 200,
        maxPressureBar: (data['maxPressureBar'] as num?)?.toInt() ?? 300,
      );
    });
  }

  @override
  Future<void> toggleTeamTimer({required String teamId}) async {
    final teamRef = _teamRef(_defaultEventId, teamId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(teamRef);
      final data = snap.data() ?? const <String, dynamic>{};
      final isRunning = (data['isRunning'] as bool?) ?? false;
      final timerSeconds = (data['timerSeconds'] as num?)?.toInt() ?? 0;
      final runningSince = data['runningSince'] as Timestamp?;

      if (isRunning) {
        final elapsed = runningSince == null
            ? 0
            : DateTime.now().difference(runningSince.toDate()).inSeconds;
        final next = (timerSeconds - elapsed).clamp(0, 1 << 31);

        tx.update(teamRef, {
          'isRunning': false,
          'runningSince': null,
          'timerSeconds': next,
        });
      } else {
        tx.update(teamRef, {
          'isRunning': true,
          'runningSince': FieldValue.serverTimestamp(),
          'undoTimerSeconds': timerSeconds,
        });
      }
    });

    // Best-effort: snapshot undo for members on start, and write remaining on stop.
    await _syncMembersWithTeamToggle(teamId: teamId);

    await _appendAirLog(teamId: teamId, note: 'toggle timer (mvp)');
  }

  Future<void> _syncMembersWithTeamToggle({required String teamId}) async {
    final teamSnap = await _teamRef(_defaultEventId, teamId).get();
    final team = _TeamDoc.fromSnapshot(teamSnap);

    final membersCol = _membersCol(_defaultEventId, teamId);
    final membersSnap = await membersCol.get();
    final batch = _firestore.batch();

    final now = DateTime.now();
    for (final doc in membersSnap.docs) {
      final m = _MemberDoc.fromDoc(doc);
      if (team.isRunning) {
        // Team is now running: store undo snapshot.
        batch.update(doc.reference, {
          'undoRemainingSeconds': m.remainingSeconds,
        });
      } else {
        // Team stopped: persist computed remaining.
        final remaining = m.computeRemaining(now, team: team);
        batch.update(doc.reference, {'remainingSeconds': remaining.inSeconds});
      }
    }

    await batch.commit();
  }

  @override
  Future<void> undoTeamTimer({required String teamId}) async {
    final teamRef = _teamRef(_defaultEventId, teamId);
    final membersCol = _membersCol(_defaultEventId, teamId);

    await _firestore.runTransaction((tx) async {
      final teamSnap = await tx.get(teamRef);
      final teamData = teamSnap.data() ?? const <String, dynamic>{};
      final undoTimerSeconds = (teamData['undoTimerSeconds'] as num?)?.toInt();
      if (undoTimerSeconds == null) return;

      tx.update(teamRef, {
        'isRunning': false,
        'runningSince': null,
        'timerSeconds': undoTimerSeconds,
        'undoTimerSeconds': null,
      });
    });

    final membersSnap = await membersCol.get();
    final batch = _firestore.batch();
    for (final doc in membersSnap.docs) {
      final data = doc.data();
      final undo = (data['undoRemainingSeconds'] as num?)?.toInt();
      if (undo == null) continue;
      batch.update(doc.reference, {
        'remainingSeconds': undo,
        'undoRemainingSeconds': null,
      });
    }
    await batch.commit();

    await _appendAirLog(teamId: teamId, note: 'undo timer (mvp)');
  }

  @override
  Future<void> advanceTeamStep({required String teamId}) async {
    final teamRef = _teamRef(_defaultEventId, teamId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(teamRef);
      final data = snap.data() ?? const <String, dynamic>{};

      final currentStepV2Str = data['currentStepV2'] as String?;
      final legacyCurrentStepStr = data['currentStep'] as String?;

      final currentStep = currentStepV2Str != null
          ? StepTypeExtension.fromJson(currentStepV2Str)
          : _stepTypeV2FromLegacyString(legacyCurrentStepStr);
      final next = StepFsm.nextStep(currentStep);

      final isRunning = (data['isRunning'] as bool?) ?? false;
      final timerSeconds = (data['timerSeconds'] as num?)?.toInt() ?? 0;
      final runningSince = data['runningSince'] as Timestamp?;

      final shouldRun = StepFsm.shouldRunTimerForStep(next);

      var nextTimerSeconds = timerSeconds;

      // If the timer was already running, first "commit" elapsed time into
      // timerSeconds before we reset runningSince for the next step.
      if (isRunning && runningSince != null) {
        final elapsed = DateTime.now()
            .difference(runningSince.toDate())
            .inSeconds;
        nextTimerSeconds = (timerSeconds - elapsed).clamp(0, 1 << 31);
      }

      if (isRunning && !shouldRun) {
        final elapsed = runningSince == null
            ? 0
            : DateTime.now().difference(runningSince.toDate()).inSeconds;
        nextTimerSeconds = (timerSeconds - elapsed).clamp(0, 1 << 31);
      }

      tx.update(teamRef, {
        'undoStepV2': currentStep?.toJson(),
        'currentStepV2': next?.toJson(),
        // Legacy fields for backward compatibility.
        'undoStep': legacyCurrentStepStr,
        'currentStep': _legacyStepStringFromV2(next),
        'isRunning': shouldRun,
        'runningSince': shouldRun ? FieldValue.serverTimestamp() : null,
        'timerSeconds': nextTimerSeconds,
        'undoTimerSeconds': timerSeconds,
      });
    });

    // Record step + log (best-effort).
    final teamSnap = await teamRef.get();
    final stepV2Str = teamSnap.data()?['currentStepV2'] as String?;
    final stepV2 = stepV2Str == null ? null : StepTypeExtension.fromJson(stepV2Str);
    final legacyType = stepV2 == null
        ? (teamSnap.data()?['currentStep'] as String?)
        : _legacyStepStringFromV2(stepV2);
    final stepRef = _stepsCol(_defaultEventId).doc();
    await stepRef.set({
      'teamId': teamId,
      'type': legacyType ?? 'start',
      'typeV2': stepV2?.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _appendAirLog(teamId: teamId, note: 'advance step (mvp)');
  }

  @override
  Future<void> undoTeamStep({required String teamId}) async {
    final teamRef = _teamRef(_defaultEventId, teamId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(teamRef);
      final data = snap.data() ?? const <String, dynamic>{};
      final undoStepV2Str = data['undoStepV2'] as String?;
      final undoLegacyStr = data['undoStep'] as String?;
      if (undoStepV2Str == null && undoLegacyStr == null) return;

      final undoTimerSeconds = (data['undoTimerSeconds'] as num?)?.toInt();
      final restoredV2 = undoStepV2Str != null
          ? StepTypeExtension.fromJson(undoStepV2Str)
          : _stepTypeV2FromLegacyString(undoLegacyStr);
      final shouldRun = StepFsm.shouldRunTimerForStep(restoredV2);

      final update = <String, dynamic>{
        'currentStepV2': restoredV2?.toJson(),
        'undoStepV2': null,
        // Legacy fields (best-effort).
        'currentStep': _legacyStepStringFromV2(restoredV2),
        'undoStep': null,
        'undoTimerSeconds': null,
        'isRunning': shouldRun,
        'runningSince': shouldRun ? FieldValue.serverTimestamp() : null,
      };
      if (undoTimerSeconds != null) {
        update['timerSeconds'] = undoTimerSeconds;
      }

      tx.update(teamRef, update);
    });

    await _appendAirLog(teamId: teamId, note: 'undo step (mvp)');
  }

  Future<void> _appendAirLog({
    required String teamId,
    required String note,
  }) async {
    final ref = _airLogsCol(_defaultEventId).doc();
    await ref.set({
      'teamId': teamId,
      'memberId': null,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createEvent({
    required String name,
    required Duration minWashingTime,
    required int minPressureBar,
    required Duration alertThreshold,
  }) async {
    await ensureSignedIn();
    final now = DateTime.now();
    final eventId = 'event_${now.millisecondsSinceEpoch}';
    
    final batch = _firestore.batch();
    
    // Create event
    batch.set(_eventRef(eventId), {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Set parameters
    batch.set(_parametersRef(eventId), {
      'minWashingSeconds': minWashingTime.inSeconds,
      'minPressureBar': minPressureBar,
      'alertThresholdSeconds': alertThreshold.inSeconds,
    });
    
    await batch.commit();
  }

  @override
  Future<void> setCurrentEvent({required String eventId}) async {
    // In Firestore version, we would update a user preference doc
    // For now, this is a no-op since we use a default event
  }

  @override
  Future<void> addTeam({
    required String name,
    Duration? initialTimer,
  }) async {
    await ensureSignedIn();
    final timer = initialTimer ?? Duration.zero;
    await _teamsCol(_defaultEventId).add({
      'name': name,
      'timerSeconds': timer.inSeconds,
      'isRunning': false,
      'runningSince': null,
      'undoTimerSeconds': null,
      'currentStep': null,
      'undoStep': null,
      'currentStepV2': null,
      'undoStepV2': null,
    });
  }

  @override
  Future<void> removeTeam({required String teamId}) async {
    await ensureSignedIn();
    final batch = _firestore.batch();
    
    // Delete team
    batch.delete(_teamsCol(_defaultEventId).doc(teamId));
    
    // Delete all members of the team
    final membersSnap = await _membersCol(_defaultEventId, teamId).get();
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  @override
  Future<void> addMember({
    required String teamId,
    required String name,
    required Duration totalTime,
  }) async {
    await ensureSignedIn();
    await _membersCol(_defaultEventId, teamId).add({
      'name': name,
      'totalSeconds': totalTime.inSeconds,
      'remainingSeconds': totalTime.inSeconds,
    });
  }

  @override
  Future<void> removeMember({required String memberId}) async {
    await ensureSignedIn();
    // We need to find which team this member belongs to
    // For simplicity, we'll search through all teams
    final teams = await _teamsCol(_defaultEventId).get();
    for (final teamDoc in teams.docs) {
      final memberRef = _membersCol(_defaultEventId, teamDoc.id).doc(memberId);
      final memberSnap = await memberRef.get();
      if (memberSnap.exists) {
        await memberRef.delete();
        return;
      }
    }
  }

  @override
  Future<void> updateMemberTime({
    required String memberId,
    required Duration newTotalTime,
  }) async {
    await ensureSignedIn();
    // Find the member and update
    final teams = await _teamsCol(_defaultEventId).get();
    for (final teamDoc in teams.docs) {
      final memberRef = _membersCol(_defaultEventId, teamDoc.id).doc(memberId);
      final memberSnap = await memberRef.get();
      if (memberSnap.exists) {
        await memberRef.update({
          'totalSeconds': newTotalTime.inSeconds,
          'remainingSeconds': newTotalTime.inSeconds,
        });
        return;
      }
    }
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    await _teamsController.close();
    await _eventSummaryController.close();
  }
}

EventStepType _stepTypeFromString(String value) {
  return switch (value) {
    'start' => EventStepType.start,
    'arrive' => EventStepType.arrive,
    'exit' => EventStepType.exit,
    'washing' => EventStepType.washing,
    _ => EventStepType.start,
  };
}

StepType? _stepTypeV2FromLegacyString(String? value) {
  return switch (value) {
    'start' => StepType.entry,
    'arrive' => StepType.arrival,
    'exit' => StepType.exit,
    'washing' => StepType.washStart,
    null => null,
    _ => StepType.entry,
  };
}

String? _legacyStepStringFromV2(StepType? step) {
  return switch (step) {
    null => null,
    StepType.entry => 'start',
    StepType.arrival => 'arrive',
    StepType.exit => 'exit',
    StepType.washStart => 'washing',
    StepType.washEnd => 'washing',
  };
}

class _TeamDoc {
  final String id;
  final String name;
  final int timerSeconds;
  final bool isRunning;
  final DateTime? runningSince;
  final StepType? currentStep;

  const _TeamDoc({
    required this.id,
    required this.name,
    required this.timerSeconds,
    required this.isRunning,
    required this.runningSince,
    required this.currentStep,
  });

  static _TeamDoc fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      return const _TeamDoc(
        id: 'missing',
        name: 'צוות',
        timerSeconds: 0,
        isRunning: false,
        runningSince: null,
        currentStep: null,
      );
    }
    return fromSnapshotDoc(snap);
  }

  static _TeamDoc fromQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final currentStepV2Str = data['currentStepV2'] as String?;
    final legacyCurrentStepStr = data['currentStep'] as String?;

    final step = currentStepV2Str != null
        ? StepTypeExtension.fromJson(currentStepV2Str)
        : _stepTypeV2FromLegacyString(legacyCurrentStepStr);
    return _TeamDoc(
      id: d.id,
      name: (data['name'] as String?) ?? 'צוות',
      timerSeconds: (data['timerSeconds'] as num?)?.toInt() ?? 0,
      isRunning: (data['isRunning'] as bool?) ?? false,
      runningSince: (data['runningSince'] as Timestamp?)?.toDate(),
      currentStep: step,
    );
  }

  static _TeamDoc fromSnapshotDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const <String, dynamic>{};
    final currentStepV2Str = data['currentStepV2'] as String?;
    final legacyCurrentStepStr = data['currentStep'] as String?;

    final step = currentStepV2Str != null
        ? StepTypeExtension.fromJson(currentStepV2Str)
        : _stepTypeV2FromLegacyString(legacyCurrentStepStr);
    return _TeamDoc(
      id: d.id,
      name: (data['name'] as String?) ?? 'צוות',
      timerSeconds: (data['timerSeconds'] as num?)?.toInt() ?? 0,
      isRunning: (data['isRunning'] as bool?) ?? false,
      runningSince: (data['runningSince'] as Timestamp?)?.toDate(),
      currentStep: step,
    );
  }

  Duration remaining(DateTime now) {
    if (!isRunning || runningSince == null) {
      return Duration(seconds: timerSeconds);
    }
    final elapsed = now.difference(runningSince!).inSeconds;
    final next = (timerSeconds - elapsed).clamp(0, 1 << 31);
    return Duration(seconds: next);
  }

  Team toTeam(DateTime now) {
    return Team(
      id: id,
      name: name,
      timer: remaining(now),
      isRunning: isRunning,
      currentStep: currentStep,
    );
  }
}

class _MemberDoc {
  final String id;
  final String name;
  final int totalSeconds;
  final int remainingSeconds;

  const _MemberDoc({
    required this.id,
    required this.name,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  static _MemberDoc fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return _MemberDoc(
      id: d.id,
      name: (data['name'] as String?) ?? 'לוחם',
      totalSeconds: (data['totalSeconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (data['remainingSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Duration computeRemaining(DateTime now, {required _TeamDoc team}) {
    if (!team.isRunning || team.runningSince == null) {
      return Duration(seconds: remainingSeconds);
    }
    final elapsed = now.difference(team.runningSince!).inSeconds;
    final next = (remainingSeconds - elapsed).clamp(0, 1 << 31);
    return Duration(seconds: next);
  }

  Member toMember(DateTime now, {required _TeamDoc? team}) {
    final remainingDuration = (team == null)
        ? Duration(seconds: remainingSeconds)
        : computeRemaining(now, team: team);
    return Member(
      id: id,
      teamId: team?.id ?? 'unknown',
      name: name,
      remainingTime: remainingDuration,
      totalTime: Duration(seconds: totalSeconds),
    );
  }
}
