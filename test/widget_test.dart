// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:air_time_manager/app/app.dart';
import 'package:air_time_manager/data/repositories/in_memory_air_time_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows app title and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      AirTimeManagerApp(repo: InMemoryAirTimeRepository()),
    );

    expect(find.text('ניהול זמן אוויר'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'פרטי אירוע'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'צוותים'), findsOneWidget);
  });
}
