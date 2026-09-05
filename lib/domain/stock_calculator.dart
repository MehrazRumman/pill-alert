import 'dart:math' as math;

import 'models.dart';

/// Shared stock math so add, cabinet, refill, and alerts cannot disagree.
class StockCalculator {
  StockCalculator._();

  /// Units removed from stock by one intake. `stockCount` is an integer column shared with the
  /// Kotlin schema, so a half tablet costs a whole unit; the days estimate below uses the same
  /// number so the cabinet never promises more days than the count can actually deliver.
  static int unitsPerIntake(double dosePerIntake) => math.max(1, dosePerIntake.ceil());

  static int? estimatedDaysFrom({
    required int stockCount,
    required double dosePerIntake,
    required int timesPerScheduledDay,
    required Frequency frequency,
    required int weekdaysMask,
    bool paused = false,
  }) {
    if (paused || stockCount < 0 || dosePerIntake <= 0 || timesPerScheduledDay <= 0) return null;
    final double scheduledDaysPerWeek = switch (frequency) {
      Frequency.daily => 7,
      Frequency.alternate => 3.5,
      Frequency.weekdays || Frequency.weekly => _bitCount(weekdaysMask & 0x7F).toDouble(),
    };
    if (scheduledDaysPerWeek <= 0) return null;
    final averagePerDay =
        unitsPerIntake(dosePerIntake) * timesPerScheduledDay * scheduledDaysPerWeek / 7;
    return ((stockCount < 0 ? 0 : stockCount) / averagePerDay).floor();
  }

  static int? estimatedDays(Medicine medicine) => estimatedDaysFrom(
        stockCount: medicine.stockCount,
        dosePerIntake: medicine.dosePerIntake,
        timesPerScheduledDay: medicine.timeTokens.length,
        frequency: medicine.frequency,
        weekdaysMask: medicine.weekdaysMask,
        paused: medicine.paused,
      );

  static int _bitCount(int v) {
    var n = v;
    var c = 0;
    while (n != 0) {
      c += n & 1;
      n >>= 1;
    }
    return c;
  }
}
