import 'package:air_time_manager/data/models/step.dart';
import 'package:air_time_manager/data/models/step_type.dart';

/// Finite State Machine לניהול מעברים בין שלבי משימה
/// 
/// רצף מלא: null → entry → arrival → exit → washStart → washEnd → entry (חזרה)
class StepFsm {
  /// מעבר לשלב הבא
  /// 
  /// - null → entry (כניסה ראשונה)
  /// - entry → arrival (הגיעו למוקד)
  /// - arrival → exit (יוצאים מהמוקד)
  /// - exit → washStart (מתחילים שטיפה)
  /// - washStart → washEnd (גמרו שטיפה)
  /// - washEnd → entry (כניסה נוספת - Round 2+)
  static EventStepType? next(EventStepType? current) {
    if (current == null) {
      return EventStepType.start; // legacy support
    }

    return switch (current) {
      EventStepType.start => EventStepType.arrive,
      EventStepType.arrive => EventStepType.exit,
      EventStepType.exit => EventStepType.washing,
      EventStepType.washing => EventStepType.start,
    };
  }

  /// מעבר לשלב הבא (גרסה חדשה עם StepType)
  static StepType? nextStep(StepType? current) {
    if (current == null) {
      return StepType.entry;
    }

    return switch (current) {
      StepType.entry => StepType.arrival,
      StepType.arrival => StepType.exit,
      StepType.exit => StepType.washStart,
      StepType.washStart => StepType.washEnd,
      StepType.washEnd => StepType.entry, // כניסה נוספת
    };
  }

  /// מעבר לשלב הקודם (Undo)
  /// 
  /// מחזיר null אם אין שלב קודם (נמצאים בהתחלה)
  static StepType? previousStep(StepType? current) {
    if (current == null) {
      return null;
    }

    return switch (current) {
      StepType.entry => null, // אין קודם
      StepType.arrival => StepType.entry,
      StepType.exit => StepType.arrival,
      StepType.washStart => StepType.exit,
      StepType.washEnd => StepType.washStart,
    };
  }

  /// האם הטיימר צריך לרוץ בשלב זה
  /// 
  /// - entry: כן (זמן עבודה)
  /// - arrival: כן (זמן עבודה)
  /// - exit: לא (בדרך חזרה)
  /// - washStart: לא (שוטפים)
  /// - washEnd: לא (סיימו)
  static bool shouldRunTimer(EventStepType? step) {
    if (step == null) return false;

    return switch (step) {
      EventStepType.start => true,
      EventStepType.arrive => true,
      EventStepType.exit => false,
      EventStepType.washing => false,
    };
  }

  /// האם הטיימר צריך לרוץ (גרסה חדשה)
  static bool shouldRunTimerForStep(StepType? step) {
    if (step == null) return false;

    return switch (step) {
      StepType.entry => true,
      StepType.arrival => true,
      StepType.exit => false,
      StepType.washStart => false,
      StepType.washEnd => false,
    };
  }

  /// טקסט הכפתור הראשי
  /// 
  /// מתאים לפעולה הבאה שהמשתמש צריך לבצע
  static String primaryLabel(EventStepType? current) {
    return switch (current) {
      null => 'כניסה לזירה',
      EventStepType.start => 'הגעה למוקד',
      EventStepType.arrive => 'יציאה מהמוקד',
      EventStepType.exit => 'תחילת שטיפה',
      EventStepType.washing => 'סיום שטיפה',
    };
  }

  /// טקסט כפתור (גרסה חדשה)
  static String buttonLabel(StepType? current) {
    if (current == null) {
      return 'כניסה לזירה';
    }

    return switch (current) {
      StepType.entry => 'הגעה למוקד',
      StepType.arrival => 'יציאה מהמוקד',
      StepType.exit => 'תחילת שטיפה',
      StepType.washStart => 'סיום שטיפה',
      StepType.washEnd => 'כניסה נוספת לזירה',
    };
  }

  /// טקסט תיאור השלב
  static String label(EventStepType step) {
    return switch (step) {
      EventStepType.start => 'בזירה',
      EventStepType.arrive => 'במוקד',
      EventStepType.exit => 'בדרך חזרה',
      EventStepType.washing => 'שטיפה',
    };
  }

  /// צבע השלב (לממשק)
  static String colorForStep(StepType step) {
    return switch (step) {
      StepType.entry => 'green',
      StepType.arrival => 'orange',
      StepType.exit => 'red',
      StepType.washStart => 'blue',
      StepType.washEnd => 'grey',
    };
  }

  /// אייקון לשלב
  static String iconForStep(StepType step) {
    return step.icon;
  }

  /// המרה ל-Firestore (legacy)
  static String toFirestore(EventStepType step) {
    return switch (step) {
      EventStepType.start => 'start',
      EventStepType.arrive => 'arrive',
      EventStepType.exit => 'exit',
      EventStepType.washing => 'washing',
    };
  }

  /// המרה מ-Firestore (legacy)
  static EventStepType fromFirestore(String? value) {
    return switch (value) {
      'arrive' => EventStepType.arrive,
      'exit' => EventStepType.exit,
      'washing' => EventStepType.washing,
      'start' || null || _ => EventStepType.start,
    };
  }

  /// בדיקה אם אפשר לבצע Undo
  static bool canUndo(StepType? currentStep) {
    return currentStep != null && previousStep(currentStep) != null;
  }

  /// בדיקה אם זה כניסה נוספת (Round 2+)
  static bool isReentry(StepType? currentStep, int roundNumber) {
    return currentStep == StepType.entry && roundNumber > 1;
  }
}

