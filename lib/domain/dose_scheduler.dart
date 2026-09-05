import 'models.dart';

/// One dose the schedule says should exist.
class PlannedDose {
  const PlannedDose({
    required this.medicineId,
    required this.epochMillis,
    required this.hour,
    required this.minute,
    required this.block,
  });

  final String medicineId;
  final int epochMillis;
  final int hour;
  final int minute;
  final TimeBlock block;
}

/// Generates dose occurrences from a medicine's schedule. Meal-time tokens resolve to configurable
/// clock times (defaults 08:00 / 14:00 / 21:00); we store the token AND the resolved time, so the
/// patient can override the clock later (README > 3c implementation note).
class DoseScheduler {
  DoseScheduler._();

  /// Whether [medicine] is due on [date] (a local date at midnight).
  static bool scheduledOn(Medicine medicine, DateTime date) {
    if (medicine.paused) return false;
    switch (medicine.frequency) {
      case Frequency.daily:
        return true;
      case Frequency.alternate:
        return epochDay(date) % 2 == 0;
      case Frequency.weekdays:
      case Frequency.weekly:
        final bit = 1 << (date.weekday - 1); // Mon=bit0 … Sun=bit6
        return (medicine.weekdaysMask & bit) != 0;
    }
  }

  /// All doses [medicine] should have on [date].
  static List<PlannedDose> dosesFor(Medicine medicine, DateTime date) {
    if (!scheduledOn(medicine, date)) return const [];
    final times = medicine.resolvedTimes.isNotEmpty
        ? medicine.resolvedTimes
        : medicine.timeTokens.map((t) => blockDefaultTime(TimeBlock.fromToken(t))).toList();
    final out = <PlannedDose>[];
    for (var i = 0; i < medicine.timeTokens.length; i++) {
      final block = TimeBlock.fromToken(medicine.timeTokens[i]);
      final hhmm = i < times.length ? times[i] : blockDefaultTime(block);
      final parsed = parseHhmm(hhmm);
      if (parsed == null) continue;
      final at = DateTime(date.year, date.month, date.day, parsed.$1, parsed.$2);
      out.add(PlannedDose(
        medicineId: medicine.id,
        epochMillis: at.millisecondsSinceEpoch,
        hour: parsed.$1,
        minute: parsed.$2,
        block: block,
      ));
    }
    return out;
  }

  static String blockDefaultTime(TimeBlock block) =>
      '${block.defaultHour.toString().padLeft(2, '0')}:00';

  static (int, int)? parseHhmm(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
  }

  /// Snooze from now when delivery was late, never from an already-past scheduled time.
  static int? snoozedEpochMillis(int scheduledEpochMillis, int nowEpochMillis, int minutes) {
    if (minutes <= 0) return null;
    final base = scheduledEpochMillis > nowEpochMillis ? scheduledEpochMillis : nowEpochMillis;
    return base + minutes * 60000;
  }

  static int weekdayBit(int weekday) => 1 << (weekday - 1);

  /// Days since the epoch for a local date — the ALTERNATE-frequency parity key.
  static int epochDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ 86400000;
}

/// A local date with no time component, used as a map key across the record/adherence code.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [n] calendar days from [d], as a local midnight. Never `add(Duration(days: n))`: a Duration is
/// 24 fixed hours, so across a DST change it lands at 01:00 or 23:00 and no longer equals the
/// `dateOnly` keys the record and streak code compares against.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
