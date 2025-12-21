import 'package:flutter_test/flutter_test.dart';
import 'package:air_time_manager/services/air_time_calculator.dart';
import 'package:air_time_manager/data/models/parameters.dart';

void main() {
  group('AirTimeCalculator Tests', () {
    late AirTimeCalculator calculator;
    late Parameters parameters;

    setUp(() {
      parameters = const Parameters(
        defaultWashingTime: Duration(minutes: 5),
        safetyMarginBar: 50,
        defaultConsumptionRate: 100,
      );
      calculator = AirTimeCalculator(parameters: parameters);
    });

    group('calculateTimeLeftBeforeArrival', () {
      test('חישוב תקין עם פרמטרים סטנדרטיים', () {
        // בלון 6.8 ליטר, לחץ 200 bar, צריכה 100 L/min
        // זמן אוויר = (200-50) × 6.8 / 100 = 10.2 דקות
        // זמן נותר = 5 - 10.2 = 0 (לא יכול להיות שלילי)
        final result = calculator.calculateTimeLeftBeforeArrival(
          tankVolume: 6.8,
          pressureBar: 200,
          consumptionRate: 100,
        );

        expect(result, Duration.zero);
      });

      test('לחץ גבוה - זמן ארוך', () {
        // בלון 9 ליטר, לחץ 300 bar, צריכה 70 L/min
        // זמן אוויר = (300-50) × 9 / 70 = 32.14 דקות
        // זמן נותר = 5 - 32.14 = 0
        final result = calculator.calculateTimeLeftBeforeArrival(
          tankVolume: 9.0,
          pressureBar: 300,
          consumptionRate: 70,
        );

        expect(result, Duration.zero);
      });

      test('לחץ מתחת למרווח ביטחון - מחזיר 0', () {
        final result = calculator.calculateTimeLeftBeforeArrival(
          tankVolume: 6.8,
          pressureBar: 50,
          consumptionRate: 100,
        );

        expect(result, Duration.zero);
      });

      test('לחץ מתחת למרווח ביטחון (30) - מחזיר 0', () {
        final result = calculator.calculateTimeLeftBeforeArrival(
          tankVolume: 6.8,
          pressureBar: 30,
          consumptionRate: 100,
        );

        expect(result, Duration.zero);
      });
    });

    group('calculateTimeLeftAfterArrival', () {
      test('חישוב תקין', () {
        final result = calculator.calculateTimeLeftAfterArrival(
          travelDuration: const Duration(minutes: 30),
          currentTimerValue: const Duration(minutes: 10),
        );

        expect(result, const Duration(minutes: 20));
      });

      test('טיימר עבר את זמן הנסיעה - מחזיר 0', () {
        final result = calculator.calculateTimeLeftAfterArrival(
          travelDuration: const Duration(minutes: 30),
          currentTimerValue: const Duration(minutes: 40),
        );

        expect(result, Duration.zero);
      });
    });

    group('calculateRequiredExitTime', () {
      test('חישוב שעת יציאה', () {
        final baseTime = DateTime(2025, 12, 21, 10, 0, 0);
        final result = calculator.calculateRequiredExitTime(
          timeLeftMinutes: 30,
          baseTime: baseTime,
        );

        expect(result, DateTime(2025, 12, 21, 10, 30, 0));
      });
    });

    group('calculateAirTimeFromTank', () {
      test('חישוב מחשבון בלון - מקרה 1', () {
        // (200-50) × 6.8 / 100 = 10.2 דקות
        final result = calculator.calculateAirTimeFromTank(
          pressureBar: 200,
          tankVolume: 6.8,
          consumptionRate: 100,
        );

        expect(result, 10);
      });

      test('חישוב מחשבון בלון - מקרה 2', () {
        // (300-50) × 9 / 70 = 32.14 דקות
        final result = calculator.calculateAirTimeFromTank(
          pressureBar: 300,
          tankVolume: 9.0,
          consumptionRate: 70,
        );

        expect(result, 32);
      });

      test('לחץ מתחת למרווח ביטחון - מחזיר 0', () {
        final result = calculator.calculateAirTimeFromTank(
          pressureBar: 50,
          tankVolume: 6.8,
          consumptionRate: 100,
        );

        expect(result, 0);
      });
    });

    group('isInAirEndTime', () {
      test('זמן נותר 0 - נסיגה', () {
        expect(calculator.isInAirEndTime(0), true);
      });

      test('זמן נותר שלילי - נסיגה', () {
        expect(calculator.isInAirEndTime(-5), true);
      });

      test('זמן נותר חיובי - לא נסיגה', () {
        expect(calculator.isInAirEndTime(10), false);
      });
    });

    group('isInWarningTime', () {
      test('5 דקות נותרו - אזהרה', () {
        expect(calculator.isInWarningTime(5), true);
      });

      test('3 דקות נותרו - אזהרה', () {
        expect(calculator.isInWarningTime(3), true);
      });

      test('6 דקות נותרו - לא אזהרה', () {
        expect(calculator.isInWarningTime(6), false);
      });

      test('0 דקות נותרו - לא אזהרה (זה נסיגה)', () {
        expect(calculator.isInWarningTime(0), false);
      });
    });

    group('calculateMinimumTime', () {
      test('מינימום מרשימה', () {
        final result = calculator.calculateMinimumTime([60, 45, 30, 50]);
        expect(result, 30);
      });

      test('רשימה ריקה - מחזיר 0', () {
        final result = calculator.calculateMinimumTime([]);
        expect(result, 0);
      });

      test('אחד בלבד', () {
        final result = calculator.calculateMinimumTime([42]);
        expect(result, 42);
      });
    });

    group('formatTime', () {
      test('פורמט שעה:דקה:שנייה', () {
        final duration = const Duration(hours: 2, minutes: 30, seconds: 45);
        final result = calculator.formatTime(duration);
        expect(result, '02:30:45');
      });

      test('פורמט דקות בלבד', () {
        final duration = const Duration(minutes: 5, seconds: 30);
        final result = calculator.formatTime(duration);
        expect(result, '00:05:30');
      });
    });

    group('formatDateTime', () {
      test('פורמט זמן', () {
        final dateTime = DateTime(2025, 12, 21, 14, 5, 3);
        final result = calculator.formatDateTime(dateTime);
        expect(result, '14:05:03');
      });
    });
  });
}
