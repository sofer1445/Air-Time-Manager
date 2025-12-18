import 'package:air_time_manager/data/models/step.dart';

class StepFsm {
  static EventStepType next(EventStepType? current) {
    return switch (current) {
      null => EventStepType.start,
      EventStepType.start => EventStepType.arrive,
      EventStepType.arrive => EventStepType.exit,
      EventStepType.exit => EventStepType.washing,
      EventStepType.washing => EventStepType.start,
    };
  }

  static bool shouldRunTimer(EventStepType step) {
    return switch (step) {
      EventStepType.start => true,
      EventStepType.arrive => true,
      EventStepType.exit => false,
      EventStepType.washing => false,
    };
  }

  static String primaryLabel(EventStepType? current) {
    return switch (current) {
      null => 'התחל',
      EventStepType.start => 'הגעה',
      EventStepType.arrive => 'יציאה',
      EventStepType.exit => 'שטיפה',
      EventStepType.washing => 'התחל',
    };
  }

  static String label(EventStepType step) {
    return switch (step) {
      EventStepType.start => 'התחלה',
      EventStepType.arrive => 'הגעה',
      EventStepType.exit => 'יציאה',
      EventStepType.washing => 'שטיפה',
    };
  }

  static String toFirestore(EventStepType step) {
    return switch (step) {
      EventStepType.start => 'start',
      EventStepType.arrive => 'arrive',
      EventStepType.exit => 'exit',
      EventStepType.washing => 'washing',
    };
  }

  static EventStepType fromFirestore(String? value) {
    return switch (value) {
      'arrive' => EventStepType.arrive,
      'exit' => EventStepType.exit,
      'washing' => EventStepType.washing,
      'start' || null || _ => EventStepType.start,
    };
  }
}
