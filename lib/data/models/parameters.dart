/// פרמטרים גלובליים לאירוע
/// מכיל ערכי ברירת מחדל וקבועים לחישובי זמן אוויר
class Parameters {
  /// זמן שטיפה ברירת מחדל (דקות)
  final Duration defaultWashingTime;

  /// זמן שטיפה מינימלי (דקות)
  final Duration minWashingTime;

  /// מרווח ביטחון ללחץ אוויר (bar) - בדרך כלל 50
  final int safetyMarginBar;

  /// קצב צריכה ברירת מחדל (ליטר/דקה)
  final int defaultConsumptionRate;

  /// קצב צריכה לצוות שטיפה (ליטר/דקה)
  final int washingTeamConsumptionRate;

  /// סף התראה (דקות לפני סיום)
  final Duration alertThreshold;

  /// לחץ מינימלי מותר ב-UI (bar)
  final int minPressureBar;

  /// לחץ מקסימלי מותר ב-UI (bar)
  final int maxPressureBar;

  /// לחץ מקסימלי מותר ב-DB (bar)
  final int dbMaxPressureBar;

  const Parameters({
    this.defaultWashingTime = const Duration(minutes: 5),
    this.minWashingTime = const Duration(minutes: 3),
    this.safetyMarginBar = 50,
    this.defaultConsumptionRate = 100,
    this.washingTeamConsumptionRate = 70,
    this.alertThreshold = const Duration(minutes: 10),
    this.minPressureBar = 50,
    this.maxPressureBar = 330,
    this.dbMaxPressureBar = 300,
  });

  /// תאימות לאחור - minWashingDuration
  Duration get minWashingDuration => minWashingTime;

  Parameters copyWith({
    Duration? defaultWashingTime,
    Duration? minWashingTime,
    int? safetyMarginBar,
    int? defaultConsumptionRate,
    int? washingTeamConsumptionRate,
    Duration? alertThreshold,
    int? minPressureBar,
    int? maxPressureBar,
    int? dbMaxPressureBar,
  }) {
    return Parameters(
      defaultWashingTime: defaultWashingTime ?? this.defaultWashingTime,
      minWashingTime: minWashingTime ?? this.minWashingTime,
      safetyMarginBar: safetyMarginBar ?? this.safetyMarginBar,
      defaultConsumptionRate:
          defaultConsumptionRate ?? this.defaultConsumptionRate,
      washingTeamConsumptionRate:
          washingTeamConsumptionRate ?? this.washingTeamConsumptionRate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      minPressureBar: minPressureBar ?? this.minPressureBar,
      maxPressureBar: maxPressureBar ?? this.maxPressureBar,
      dbMaxPressureBar: dbMaxPressureBar ?? this.dbMaxPressureBar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultWashingTimeMinutes': defaultWashingTime.inMinutes,
      'minWashingTimeMinutes': minWashingTime.inMinutes,
      'safetyMarginBar': safetyMarginBar,
      'defaultConsumptionRate': defaultConsumptionRate,
      'washingTeamConsumptionRate': washingTeamConsumptionRate,
      'alertThresholdMinutes': alertThreshold.inMinutes,
      'minPressureBar': minPressureBar,
      'maxPressureBar': maxPressureBar,
      'dbMaxPressureBar': dbMaxPressureBar,
    };
  }

  factory Parameters.fromJson(Map<String, dynamic> json) {
    return Parameters(
      defaultWashingTime:
          Duration(minutes: json['defaultWashingTimeMinutes'] ?? 5),
      minWashingTime: Duration(minutes: json['minWashingTimeMinutes'] ?? 3),
      safetyMarginBar: json['safetyMarginBar'] ?? 50,
      defaultConsumptionRate: json['defaultConsumptionRate'] ?? 100,
      washingTeamConsumptionRate: json['washingTeamConsumptionRate'] ?? 70,
      alertThreshold: Duration(minutes: json['alertThresholdMinutes'] ?? 10),
      minPressureBar: json['minPressureBar'] ?? 50,
      maxPressureBar: json['maxPressureBar'] ?? 330,
      dbMaxPressureBar: json['dbMaxPressureBar'] ?? 300,
    );
  }
}
