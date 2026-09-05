import 'package:flutter_test/flutter_test.dart';
import 'package:nirbhor/domain/dose_scheduler.dart';
import 'package:nirbhor/domain/models.dart';
import 'package:nirbhor/domain/stock_calculator.dart';
import 'package:nirbhor/i18n/numerals.dart';

void main() {
  group('addDays', () {
    test('lands on local midnight across a month boundary', () {
      final d = addDays(DateTime(2026, 1, 31), 1);
      expect(d, DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('is the inverse of itself', () {
      final today = dateOnly(DateTime.now());
      expect(addDays(addDays(today, 40), -40), today);
    });
  });

  group('Numerals', () {
    test('toAscii reverses Bengali digits and leaves the rest', () {
      expect(Numerals.toAscii('১৯৬০'), '1960');
      expect(Numerals.toAscii('19৬0'), '1960');
      expect(Numerals.toAscii('abc'), 'abc');
    });

    test('Bangla honours the 24-hour setting', () {
      expect(Numerals.time(20, 5, true, true), '২০:০৫');
      expect(Numerals.time(20, 5, true, false), 'রাত ৮:০৫');
      expect(Numerals.time(8, 0, false, true), '08:00');
    });
  });

  group('StockCalculator', () {
    test('days estimate matches the whole-unit deduction for half doses', () {
      expect(StockCalculator.unitsPerIntake(0.5), 1);
      expect(StockCalculator.unitsPerIntake(1.5), 2);
      final days = StockCalculator.estimatedDaysFrom(
        stockCount: 30,
        dosePerIntake: 0.5,
        timesPerScheduledDay: 1,
        frequency: Frequency.daily,
        weekdaysMask: 0,
      );
      expect(days, 30);
    });

    test('paused or unschedulable medicine has no estimate', () {
      expect(
        StockCalculator.estimatedDaysFrom(
          stockCount: 30,
          dosePerIntake: 1,
          timesPerScheduledDay: 1,
          frequency: Frequency.weekly,
          weekdaysMask: 0,
        ),
        isNull,
      );
    });
  });

  group('DoseScheduler', () {
    test('snooze counts from now when delivery was late', () {
      expect(DoseScheduler.snoozedEpochMillis(1000, 5000, 10), 5000 + 600000);
      expect(DoseScheduler.snoozedEpochMillis(9000, 5000, 10), 9000 + 600000);
      expect(DoseScheduler.snoozedEpochMillis(9000, 5000, 0), isNull);
    });
  });
}
