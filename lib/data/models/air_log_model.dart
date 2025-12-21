/// מודל למדידת לחץ אוויר
/// מתעד כל מדידת לחץ של לוחם
class AirLogModel {
  /// מזהה ייחודי
  final String id;

  /// מזהה השלב המקושר
  final String stepId;

  /// מזהה צוות (אופציונלי)
  final String? teamId;

  /// תעודת זהות לוחם (אופציונלי)
  final String? govId;

  /// לחץ אוויר (bar) - טווח: 0-300
  final int pressureBar;

  /// זמן הדגימה
  final DateTime sampleTime;

  /// הערות נוספות
  final String? notes;

  const AirLogModel({
    required this.id,
    required this.stepId,
    this.teamId,
    this.govId,
    required this.pressureBar,
    required this.sampleTime,
    this.notes,
  });

  /// בדיקה אם הלחץ בטווח תקין (0-300)
  bool get isValid => pressureBar >= 0 && pressureBar <= 300;

  /// בדיקה אם הלחץ מתחת למרווח הביטחון (50)
  bool get isBelowSafetyMargin => pressureBar <= 50;

  /// בדיקה אם הלחץ בטווח אזהרה (50-100)
  bool get isInWarningRange => pressureBar > 50 && pressureBar <= 100;

  AirLogModel copyWith({
    String? id,
    String? stepId,
    String? teamId,
    String? govId,
    int? pressureBar,
    DateTime? sampleTime,
    String? notes,
  }) {
    return AirLogModel(
      id: id ?? this.id,
      stepId: stepId ?? this.stepId,
      teamId: teamId ?? this.teamId,
      govId: govId ?? this.govId,
      pressureBar: pressureBar ?? this.pressureBar,
      sampleTime: sampleTime ?? this.sampleTime,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepId': stepId,
      'teamId': teamId,
      'govId': govId,
      'pressureBar': pressureBar,
      'sampleTime': sampleTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory AirLogModel.fromJson(Map<String, dynamic> json) {
    return AirLogModel(
      id: json['id'],
      stepId: json['stepId'],
      teamId: json['teamId'],
      govId: json['govId'],
      pressureBar: json['pressureBar'],
      sampleTime: DateTime.parse(json['sampleTime']),
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'AirLogModel(id: $id, pressureBar: $pressureBar bar, sampleTime: $sampleTime)';
  }
}
