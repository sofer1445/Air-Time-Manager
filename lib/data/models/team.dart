import 'package:air_time_manager/data/models/step.dart';

class Team {
  final String id;
  final String name;
  final Duration timer;
  final bool isRunning;
  final EventStepType? currentStep;

  const Team({
    required this.id,
    required this.name,
    required this.timer,
    this.isRunning = false,
    this.currentStep,
  });
}
