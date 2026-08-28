import '../ui/marks/medicine_mark.dart';

export '../ui/marks/medicine_mark.dart' show MarkShape;

/// The three time blocks the home timeline groups doses into. Tokens resolve to configurable clocks.
enum TimeBlock {
  morning('morning', 8, 'MORNING'), // সকাল · default 08:00
  noon('noon', 14, 'NOON'), // দুপুর · default 14:00
  night('night', 21, 'NIGHT'); // রাত  · default 21:00

  const TimeBlock(this.token, this.defaultHour, this.stored);

  final String token;
  final int defaultHour;
  final String stored;

  static TimeBlock fromToken(String t) =>
      TimeBlock.values.firstWhere((b) => b.token == t, orElse: () => TimeBlock.morning);

  static TimeBlock fromStored(String? s) =>
      TimeBlock.values.firstWhere((b) => b.stored == s, orElse: () => TimeBlock.morning);
}

/// খাবারের আগে না পরে — meal relation.
enum FoodRelation {
  before('BEFORE'),
  after('AFTER'),
  none('NONE');

  const FoodRelation(this.stored);
  final String stored;

  static FoodRelation fromStored(String? s) =>
      FoodRelation.values.firstWhere((f) => f.stored == s, orElse: () => FoodRelation.none);
}

enum Frequency {
  daily('DAILY'),
  alternate('ALTERNATE'),
  weekdays('WEEKDAYS'),
  weekly('WEEKLY');

  const Frequency(this.stored);
  final String stored;

  static Frequency fromStored(String? s) =>
      Frequency.values.firstWhere((f) => f.stored == s, orElse: () => Frequency.daily);
}

/// Dose-occurrence status vocabulary (README > Dose Status Vocabulary).
enum DoseStatus {
  upcoming('UPCOMING'),
  taken('TAKEN'),
  takenLate('TAKEN_LATE'),
  missed('MISSED'),
  skipped('SKIPPED');

  const DoseStatus(this.stored);
  final String stored;

  static DoseStatus fromStored(String? s) =>
      DoseStatus.values.firstWhere((d) => d.stored == s, orElse: () => DoseStatus.upcoming);

  bool get isTaken => this == DoseStatus.taken || this == DoseStatus.takenLate;
}

/// Where a confirmation came from.
enum DoseSource {
  alarm('ALARM'),
  home('HOME'),
  recoverySheet('RECOVERY_SHEET'),
  caregiver('CAREGIVER');

  const DoseSource(this.stored);
  final String stored;

  static DoseSource? fromStored(String? s) {
    if (s == null) return null;
    for (final v in DoseSource.values) {
      if (v.stored == s) return v;
    }
    return null;
  }
}

/// How a linked caregiver is told about problems. Channels are independent and can all be on.
enum CaregiverChannel {
  email('EMAIL'),
  sms('SMS'),
  app('APP');

  const CaregiverChannel(this.stored);
  final String stored;

  static CaregiverChannel? fromStored(String? s) {
    for (final v in CaregiverChannel.values) {
      if (v.stored == s) return v;
    }
    return null;
  }
}

enum DigestFrequency {
  dailyDigest('DAILY_DIGEST'),
  immediate('IMMEDIATE');

  const DigestFrequency(this.stored);
  final String stored;

  static DigestFrequency fromStored(String? s) => DigestFrequency.values
      .firstWhere((d) => d.stored == s, orElse: () => DigestFrequency.dailyDigest);
}

/// UI-facing medicine model (localised display name + the Latin pack name are both kept).
class Medicine {
  const Medicine({
    required this.id,
    required this.displayName,
    required this.packName,
    required this.strength,
    required this.form,
    required this.condition,
    required this.mark,
    required this.markColor,
    required this.dosePerIntake,
    required this.foodRelation,
    required this.frequency,
    required this.weekdaysMask,
    required this.timeTokens,
    required this.resolvedTimes,
    required this.stockCount,
    required this.stockUpdatedAt,
    required this.highRisk,
    required this.paused,
  });

  final String id;
  final String displayName; // localised name shown to the patient
  final String packName; // Latin name as printed on the pack (stays Latin)
  final String strength; // e.g. "৫০০ মি.গ্রা." / "500 mg"
  final String form; // e.g. ট্যাবলেট / tablet
  final String condition; // what the patient recognises, e.g. ডায়াবেটিস / diabetes
  final MarkShape mark;
  final int markColor; // ARGB; stored, never derived
  final double dosePerIntake; // supports halves (0.5, 1, 2, 3)
  final FoodRelation foodRelation;
  final Frequency frequency;
  final int weekdaysMask; // bitmask Mon..Sun when frequency == weekdays/weekly
  final List<String> timeTokens; // morning/noon/night
  final List<String> resolvedTimes; // "HH:mm" resolved clock times, parallel to blocks
  final int stockCount;
  final int stockUpdatedAt;
  final bool highRisk; // gates press-and-hold confirmation
  final bool paused;

  Medicine copyWith({
    String? displayName,
    String? packName,
    String? strength,
    String? form,
    String? condition,
    MarkShape? mark,
    int? markColor,
    double? dosePerIntake,
    FoodRelation? foodRelation,
    Frequency? frequency,
    int? weekdaysMask,
    List<String>? timeTokens,
    List<String>? resolvedTimes,
    int? stockCount,
    int? stockUpdatedAt,
    bool? highRisk,
    bool? paused,
  }) =>
      Medicine(
        id: id,
        displayName: displayName ?? this.displayName,
        packName: packName ?? this.packName,
        strength: strength ?? this.strength,
        form: form ?? this.form,
        condition: condition ?? this.condition,
        mark: mark ?? this.mark,
        markColor: markColor ?? this.markColor,
        dosePerIntake: dosePerIntake ?? this.dosePerIntake,
        foodRelation: foodRelation ?? this.foodRelation,
        frequency: frequency ?? this.frequency,
        weekdaysMask: weekdaysMask ?? this.weekdaysMask,
        timeTokens: timeTokens ?? this.timeTokens,
        resolvedTimes: resolvedTimes ?? this.resolvedTimes,
        stockCount: stockCount ?? this.stockCount,
        stockUpdatedAt: stockUpdatedAt ?? this.stockUpdatedAt,
        highRisk: highRisk ?? this.highRisk,
        paused: paused ?? this.paused,
      );
}

/// A single scheduled dose for a given day/time.
class DoseOccurrence {
  const DoseOccurrence({
    required this.id,
    required this.medicineId,
    required this.scheduledEpochMillis,
    required this.hour,
    required this.minute,
    required this.block,
    required this.status,
    this.confirmedAt,
    this.source,
  });

  final int id;
  final String medicineId;
  final int scheduledEpochMillis;
  final int hour;
  final int minute;
  final TimeBlock block;
  final DoseStatus status;
  final int? confirmedAt;
  final DoseSource? source;

  DateTime get scheduledAt => DateTime.fromMillisecondsSinceEpoch(scheduledEpochMillis);
}

/// A dose joined with its medicine — what timeline / alarm / record rows actually render.
class DoseWithMedicine {
  const DoseWithMedicine(this.dose, this.medicine);

  final DoseOccurrence dose;
  final Medicine medicine;
}

/// A time block on the home timeline, with its due doses.
class TimelineBlock {
  const TimelineBlock({
    required this.block,
    required this.hour,
    required this.minute,
    required this.doses,
  });

  final TimeBlock block;
  final int hour;
  final int minute;
  final List<DoseWithMedicine> doses;

  bool get allTaken => doses.isNotEmpty && doses.every((d) => d.dose.status.isTaken);

  bool get allResolved =>
      doses.isNotEmpty && doses.every((d) => d.dose.status.isTaken || d.dose.status == DoseStatus.skipped);

  bool get anyDueNow => doses.any((d) => d.dose.status == DoseStatus.upcoming);
}

class Caregiver {
  const Caregiver({
    required this.id,
    required this.name,
    required this.relationship,
    required this.email,
    required this.emailVerified,
    required this.phone,
    required this.channels,
    required this.digestFrequency,
    required this.escalateOnSecondMiss,
    required this.notifyOnMissedTwice,
    required this.notifyOnOutOfStock,
    required this.weeklySummary,
  });

  final String id;
  final String name;
  final String relationship;
  final String email;
  final bool emailVerified;
  final String phone;
  final Set<CaregiverChannel> channels;
  final DigestFrequency digestFrequency;
  final bool escalateOnSecondMiss;
  final bool notifyOnMissedTwice;
  final bool notifyOnOutOfStock;
  final bool weeklySummary;

  Caregiver copyWith({
    String? name,
    String? relationship,
    String? email,
    bool? emailVerified,
    String? phone,
    Set<CaregiverChannel>? channels,
    DigestFrequency? digestFrequency,
    bool? escalateOnSecondMiss,
    bool? notifyOnMissedTwice,
    bool? notifyOnOutOfStock,
    bool? weeklySummary,
  }) =>
      Caregiver(
        id: id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        email: email ?? this.email,
        emailVerified: emailVerified ?? this.emailVerified,
        phone: phone ?? this.phone,
        channels: channels ?? this.channels,
        digestFrequency: digestFrequency ?? this.digestFrequency,
        escalateOnSecondMiss: escalateOnSecondMiss ?? this.escalateOnSecondMiss,
        notifyOnMissedTwice: notifyOnMissedTwice ?? this.notifyOnMissedTwice,
        notifyOnOutOfStock: notifyOnOutOfStock ?? this.notifyOnOutOfStock,
        weeklySummary: weeklySummary ?? this.weeklySummary,
      );
}

class AlertLogItem {
  const AlertLogItem(this.id, this.kind, this.message, this.sentAtMillis, this.outcome);

  final int id;
  final String kind; // missed | summary | low-stock | reminder
  final String message;
  final int sentAtMillis;
  final String outcome;
}

/// Derived numbers the UI needs but that aren't stored.
class DailyProgress {
  const DailyProgress(this.taken, this.total);

  final int taken;
  final int total;

  int get remaining => (total - taken) < 0 ? 0 : total - taken;
  double get fraction => total == 0 ? 0 : taken / total;
}

class StockStatus {
  const StockStatus({
    required this.medicineId,
    required this.count,
    required this.daysRemaining,
    required this.isLow,
    required this.runsOutEpochMillis,
  });

  final String medicineId;
  final int count;

  /// null when the medicine is paused or its schedule can't yield a rate (never "forever").
  final int? daysRemaining;
  final bool isLow; // ≤ 5 days
  final int? runsOutEpochMillis;
}
