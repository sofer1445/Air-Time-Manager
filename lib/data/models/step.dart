enum EventStepType { start, arrive, exit, washing }

class EventStep {
  final String id;
  final String eventId;
  final String? teamId;
  final EventStepType type;
  final DateTime createdAt;

  const EventStep({
    required this.id,
    required this.eventId,
    required this.teamId,
    required this.type,
    required this.createdAt,
  });
}
