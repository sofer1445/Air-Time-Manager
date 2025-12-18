class Parameters {
  /// Minimum washing time requirement.
  final Duration minWashingDuration;

  /// Allowed pressure range (for future validation).
  final int minPressureBar;
  final int maxPressureBar;

  const Parameters({
    required this.minWashingDuration,
    required this.minPressureBar,
    required this.maxPressureBar,
  });
}
