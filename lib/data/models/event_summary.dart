import 'package:flutter/material.dart';

class EventSummary {
  final Duration remainingTime;
  final TimeOfDay requiredExitTime;
  final int alertsCount;

  const EventSummary({
    required this.remainingTime,
    required this.requiredExitTime,
    required this.alertsCount,
  });
}
