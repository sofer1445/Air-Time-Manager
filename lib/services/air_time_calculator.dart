import '../data/models/parameters.dart';

/// שירות לחישובי זמן אוויר
/// מיישם את הנוסחאות המדויקות עם מרווח ביטחון
class AirTimeCalculator {
  final Parameters parameters;

  const AirTimeCalculator({
    this.parameters = const Parameters(),
  });

  /// חישוב זמן אוויר נותר (לפני הגעה למוקד)
  ///
  /// נוסחה: timeLeft = washingTime - [(volume × (pressure - safetyMargin)) / consumption]
  ///
  /// פרמטרים:
  /// - [tankVolume]: נפח הבלון (ליטר) - בדרך כלל 6.8 או 9
  /// - [pressureBar]: לחץ נוכחי (bar)
  /// - [consumptionRate]: קצב צריכה (ליטר/דקה)
  /// - [washingTime]: זמן שטיפה (דקות)
  ///
  /// מחזיר: משך זמן בדקות, או 0 אם הלחץ מתחת למרווח הביטחון
  Duration calculateTimeLeftBeforeArrival({
    required double tankVolume,
    required int pressureBar,
    required int consumptionRate,
    Duration? washingTime,
  }) {
    final washing = washingTime ?? parameters.defaultWashingTime;

    // Edge case: לחץ מתחת למרווח ביטחון
    if (pressureBar <= parameters.safetyMarginBar) {
      return Duration.zero;
    }

    // חישוב: זמן = (נפח × (לחץ - 50)) / צריכה
    final effectivePressure = pressureBar - parameters.safetyMarginBar;
    final airTimeMinutes = (tankVolume * effectivePressure) / consumptionRate;

    // זמן נותר = זמן שטיפה - זמן אוויר
    final timeLeftMinutes = washing.inMinutes - airTimeMinutes;

    // לא יכול להיות שלילי
    if (timeLeftMinutes < 0) {
      return Duration.zero;
    }

    return Duration(minutes: timeLeftMinutes.round());
  }

  /// חישוב זמן אוויר נותר (אחרי הגעה למוקד)
  ///
  /// נוסחה: timeLeft = travelDuration - currentTimerValue
  ///
  /// פרמטרים:
  /// - [travelDuration]: משך זמן הנסיעה/הגעה (דקות)
  /// - [currentTimerValue]: ערך טיימר נוכחי (דקות)
  ///
  /// מחזיר: זמן נותר עד סיום
  Duration calculateTimeLeftAfterArrival({
    required Duration travelDuration,
    required Duration currentTimerValue,
  }) {
    final timeLeft = travelDuration - currentTimerValue;

    if (timeLeft.isNegative) {
      return Duration.zero;
    }

    return timeLeft;
  }

  /// חישוב שעת יציאה נדרשת
  ///
  /// מחזיר את השעה בה הצוות צריך לצאת
  ///
  /// פרמטרים:
  /// - [timeLeftMinutes]: זמן נותר (דקות)
  /// - [baseTime]: זמן בסיס (ברירת מחדל: עכשיו)
  ///
  /// מחזיר: DateTime של שעת היציאה
  DateTime calculateRequiredExitTime({
    required int timeLeftMinutes,
    DateTime? baseTime,
  }) {
    final base = baseTime ?? DateTime.now();
    return base.add(Duration(minutes: timeLeftMinutes));
  }

  /// חישוב זמן אוויר ממחשבון בלון
  ///
  /// נוסחה: time = (pressure - safetyMargin) × volume / consumption
  ///
  /// פרמטרים:
  /// - [pressureBar]: לחץ בבלון (bar)
  /// - [tankVolume]: נפח הבלון (ליטר)
  /// - [consumptionRate]: קצב צריכה (ליטר/דקה)
  ///
  /// מחזיר: זמן אוויר בדקות
  int calculateAirTimeFromTank({
    required int pressureBar,
    required double tankVolume,
    required int consumptionRate,
  }) {
    // Edge case
    if (pressureBar <= parameters.safetyMarginBar) {
      return 0;
    }

    final effectivePressure = pressureBar - parameters.safetyMarginBar;
    final minutes = (effectivePressure * tankVolume) / consumptionRate;

    return minutes.round();
  }

  /// בדיקה אם הצוות בזמן סיום אוויר (נסיגה)
  ///
  /// זמן סיום אוויר = כולל זמן שטיפה + זמן הגעה חזרה
  ///
  /// פרמטרים:
  /// - [timeLeftMinutes]: זמן נותר לצוות (דקות)
  ///
  /// מחזיר: true אם בזמן נסיגה (זמן נותר <= 0)
  bool isInAirEndTime(int timeLeftMinutes) {
    return timeLeftMinutes <= 0;
  }

  /// בדיקה אם הצוות בזמן אזהרה
  ///
  /// פרמטרים:
  /// - [timeLeftMinutes]: זמן נותר (דקות)
  ///
  /// מחזיר: true אם בטווח האזהרה (5 דקות אחרונות)
  bool isInWarningTime(int timeLeftMinutes) {
    return timeLeftMinutes > 0 && timeLeftMinutes <= 5;
  }

  /// חישוב מינימום זמן בין לוחמי צוות
  ///
  /// פרמטרים:
  /// - [memberTimes]: רשימת זמני לוחמים (דקות)
  ///
  /// מחזיר: המינימום, או 0 אם הרשימה ריקה
  int calculateMinimumTime(List<int> memberTimes) {
    if (memberTimes.isEmpty) {
      return 0;
    }

    return memberTimes.reduce((a, b) => a < b ? a : b);
  }

  /// פורמט זמן ל-HH:MM:SS
  String formatTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// פורמט DateTime ל-HH:MM:SS
  String formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
