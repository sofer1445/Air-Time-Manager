import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );

    final scheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.inverseSurface,
        foregroundColor: scheme.onInverseSurface,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    );
  }
}
