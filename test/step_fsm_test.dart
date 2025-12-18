import 'package:air_time_manager/data/models/step.dart';
import 'package:air_time_manager/services/step_fsm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FSM next step sequence', () {
    expect(StepFsm.next(null), EventStepType.start);
    expect(StepFsm.next(EventStepType.start), EventStepType.arrive);
    expect(StepFsm.next(EventStepType.arrive), EventStepType.exit);
    expect(StepFsm.next(EventStepType.exit), EventStepType.washing);
    expect(StepFsm.next(EventStepType.washing), EventStepType.start);
  });

  test('Primary label mapping', () {
    expect(StepFsm.primaryLabel(null), 'התחל');
    expect(StepFsm.primaryLabel(EventStepType.start), 'הגעה');
    expect(StepFsm.primaryLabel(EventStepType.arrive), 'יציאה');
    expect(StepFsm.primaryLabel(EventStepType.exit), 'שטיפה');
    expect(StepFsm.primaryLabel(EventStepType.washing), 'התחל');
  });

  test('Timer run mapping', () {
    expect(StepFsm.shouldRunTimer(EventStepType.start), isTrue);
    expect(StepFsm.shouldRunTimer(EventStepType.arrive), isTrue);
    expect(StepFsm.shouldRunTimer(EventStepType.exit), isFalse);
    expect(StepFsm.shouldRunTimer(EventStepType.washing), isFalse);
  });
}
