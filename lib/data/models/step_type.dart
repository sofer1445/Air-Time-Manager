/// סוגי שלבים במשימה
enum StepType {
  /// כניסה לזירה
  entry,

  /// הגעה למוקד
  arrival,

  /// יציאה מהמוקד
  exit,

  /// תחילת שטיפה
  washStart,

  /// סיום שטיפה
  washEnd,
}

extension StepTypeExtension on StepType {
  /// שם השלב בעברית
  String get displayName {
    switch (this) {
      case StepType.entry:
        return 'כניסה לזירה';
      case StepType.arrival:
        return 'הגעה למוקד';
      case StepType.exit:
        return 'יציאה מהמוקד';
      case StepType.washStart:
        return 'תחילת שטיפה';
      case StepType.washEnd:
        return 'סיום שטיפה';
    }
  }

  /// אייקון לשלב
  String get icon {
    switch (this) {
      case StepType.entry:
        return '🚪';
      case StepType.arrival:
        return '🎯';
      case StepType.exit:
        return '🔙';
      case StepType.washStart:
        return '🚿';
      case StepType.washEnd:
        return '✅';
    }
  }

  /// המרה ל-String לשמירה
  String toJson() => name;

  /// יצירה מ-String
  static StepType fromJson(String json) {
    return StepType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => StepType.entry,
    );
  }
}
