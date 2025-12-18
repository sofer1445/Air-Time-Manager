class Member {
  final String id;
  final String teamId;
  final String name;

  /// Local-only field for now; later will be derived from air logs / pressure.
  final Duration remainingTime;

  /// Total allocated air-time for progress calculations.
  final Duration totalTime;

  const Member({
    required this.id,
    required this.teamId,
    required this.name,
    required this.remainingTime,
    required this.totalTime,
  });
}
