import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:flutter/material.dart';

class AppScope extends InheritedWidget {
  final AirTimeRepository repo;

  const AppScope({super.key, required this.repo, required super.child});

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.repo != repo;
}
