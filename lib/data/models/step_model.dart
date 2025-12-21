import 'step_type.dart';

/// מודל לשלב במשימה
/// מתעד כל פעולה שמבצע צוות או לוחם
class StepModel {
  /// מזהה ייחודי
  final String id;

  /// סוג השלב
  final StepType type;

  /// זמן ביצוע השלב
  final DateTime timestamp;

  /// מזהה צוות (אופציונלי)
  final String? teamId;

  /// תעודת זהות לוחם (אופציונלי)
  final String? govId;

  /// מספר סבב (Round)
  final int roundNumber;

  /// הערות נוספות
  final String? notes;

  const StepModel({
    required this.id,
    required this.type,
    required this.timestamp,
    this.teamId,
    this.govId,
    this.roundNumber = 1,
    this.notes,
  });

  StepModel copyWith({
    String? id,
    StepType? type,
    DateTime? timestamp,
    String? teamId,
    String? govId,
    int? roundNumber,
    String? notes,
  }) {
    return StepModel(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      teamId: teamId ?? this.teamId,
      govId: govId ?? this.govId,
      roundNumber: roundNumber ?? this.roundNumber,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'teamId': teamId,
      'govId': govId,
      'roundNumber': roundNumber,
      'notes': notes,
    };
  }

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      id: json['id'],
      type: StepTypeExtension.fromJson(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      teamId: json['teamId'],
      govId: json['govId'],
      roundNumber: json['roundNumber'] ?? 1,
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'StepModel(id: $id, type: ${type.displayName}, timestamp: $timestamp, teamId: $teamId)';
  }
}
