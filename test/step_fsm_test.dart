import 'package:air_time_manager/data/models/step_type.dart';
import 'package:air_time_manager/services/step_fsm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FSM next step sequence (StepType)', () {
    expect(StepFsm.nextStep(null), StepType.entry);
    expect(StepFsm.nextStep(StepType.entry), StepType.arrival);
    expect(StepFsm.nextStep(StepType.arrival), StepType.exit);
    expect(StepFsm.nextStep(StepType.exit), StepType.washStart);
    expect(StepFsm.nextStep(StepType.washStart), StepType.washEnd);
    expect(StepFsm.nextStep(StepType.washEnd), StepType.entry);
  });

  test('Button label mapping (StepType)', () {
    expect(StepFsm.buttonLabel(null), 'כניסה לזירה');
    expect(StepFsm.buttonLabel(StepType.entry), 'הגעה למוקד');
    expect(StepFsm.buttonLabel(StepType.arrival), 'יציאה מהמוקד');
    expect(StepFsm.buttonLabel(StepType.exit), 'תחילת שטיפה');
    expect(StepFsm.buttonLabel(StepType.washStart), 'סיום שטיפה');
    expect(StepFsm.buttonLabel(StepType.washEnd), 'כניסה נוספת לזירה');
  });

  test('Timer run mapping (StepType)', () {
    expect(StepFsm.shouldRunTimerForStep(StepType.entry), isTrue);
    expect(StepFsm.shouldRunTimerForStep(StepType.arrival), isTrue);
    expect(StepFsm.shouldRunTimerForStep(StepType.exit), isTrue);
    expect(StepFsm.shouldRunTimerForStep(StepType.washStart), isTrue);
    expect(StepFsm.shouldRunTimerForStep(StepType.washEnd), isTrue);
  });

  test('Undo previous step (StepType)', () {
    expect(StepFsm.previousStep(null), isNull);
    expect(StepFsm.previousStep(StepType.entry), isNull);
    expect(StepFsm.previousStep(StepType.arrival), StepType.entry);
    expect(StepFsm.previousStep(StepType.exit), StepType.arrival);
    expect(StepFsm.previousStep(StepType.washStart), StepType.exit);
    expect(StepFsm.previousStep(StepType.washEnd), StepType.washStart);
  });
}
