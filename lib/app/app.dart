import 'package:air_time_manager/app/app_scope.dart';
import 'package:air_time_manager/app/theme/app_theme.dart';
import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:air_time_manager/features/event/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AirTimeManagerApp extends StatefulWidget {
  final AirTimeRepository repo;

  const AirTimeManagerApp({super.key, required this.repo});

  @override
  State<AirTimeManagerApp> createState() => _AirTimeManagerAppState();
}

class _AirTimeManagerAppState extends State<AirTimeManagerApp> {
  @override
  void dispose() {
    widget.repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: widget.repo,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ניהול זמן אוויר',
        theme: AppTheme.light(),
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const EventScreen(),
      ),
    );
  }
}
