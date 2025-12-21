import 'package:flutter/material.dart';

class EventSummary {
  final Duration remainingTime;
  final TimeOfDay requiredExitTime;
  final int alertsCount;
  final Duration alertThreshold;

  const EventSummary({
    required this.remainingTime,
    required this.requiredExitTime,
    required this.alertsCount,
    this.alertThreshold = const Duration(minutes: 10),
  });
}
