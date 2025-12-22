import 'dart:async';
import 'package:air_time_manager/data/models/event_summary.dart';
import 'package:air_time_manager/data/models/team.dart';
import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:flutter/material.dart';

/// שירות להתראות מקומיות על צוותים שנגמר להם הזמן
class AlertService {
  final AirTimeRepository _repo;
  final BuildContext _context;
  StreamSubscription? _summarySubscription;
  StreamSubscription? _teamsSubscription;
  
  final Set<String> _alreadyAlertedTeams = {};
  EventSummary? _lastSummary;

  AlertService({
    required AirTimeRepository repo,
    required BuildContext context,
  })  : _repo = repo,
        _context = context;

  void start() {
    _summarySubscription = _repo.watchEventSummary().listen(_onSummaryUpdate);
    _teamsSubscription = _repo.watchTeams().listen(_onTeamsUpdate);
  }

  void _onSummaryUpdate(EventSummary summary) {
    _lastSummary = summary;
  }

  void _onTeamsUpdate(List<Team> teams) {
    if (_lastSummary == null) return;

    // בדוק אילו צוותים מתחת לסף ההתראה
    final threshold = _lastSummary!.alertThreshold;
    
    for (final team in teams) {
      // אם הצוות כבר קיבל התראה, דלג
      if (_alreadyAlertedTeams.contains(team.id)) continue;
      
      // אם הזמן נמוך מהסף, שלח התראה
      if (team.timer <= threshold && team.timer > Duration.zero) {
        _showAlert(team);
        _alreadyAlertedTeams.add(team.id);
      }
    }

    // נקה התראות עבור צוותים שחזרו מעל הסף
    _alreadyAlertedTeams.removeWhere((teamId) {
      final team = teams.firstWhere(
        (t) => t.id == teamId,
        orElse: () => Team(
          id: teamId,
          name: '',
          timer: Duration.zero,
          currentStep: null,
          isRunning: false,
        ),
      );
      return team.timer > threshold;
    });
  }

  void _showAlert(Team team) {
    if (!_context.mounted) return;

    final messenger = ScaffoldMessenger.of(_context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ ${team.name} מתקרב לסיום זמן אוויר!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'הבנתי',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // ניתן להוסיף כאן גם התראות push אם יש
    // _sendPushNotification(team);
  }

  void dispose() {
    _summarySubscription?.cancel();
    _teamsSubscription?.cancel();
    _alreadyAlertedTeams.clear();
  }
}
