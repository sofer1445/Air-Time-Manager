class AirLog {
  final String id;
  final String eventId;
  final String teamId;
  final String? memberId;

  /// A short description (for MVP/demo).
  final String note;

  final DateTime createdAt;

  const AirLog({
    required this.id,
    required this.eventId,
    required this.teamId,
    required this.memberId,
    required this.note,
    required this.createdAt,
  });
}
