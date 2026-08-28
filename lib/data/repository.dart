import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/dose_scheduler.dart';
import '../domain/models.dart';
import '../domain/stock_calculator.dart';
import 'database.dart';
import 'mappers.dart';

/// Adherence over a rolling window.
class AdherenceWindow {
  const AdherenceWindow({
    required this.taken,
    required this.takenLate,
    required this.missed,
    required this.skipped,
    required this.total,
    required this.streakDays,
  });

  final int taken;
  final int takenLate;
  final int missed;
  final int skipped;
  final int total;
  final int streakDays;

  /// Percentage taken on time; late doses still appear in [taken] but not this numerator.
  int get percent => total == 0 ? 0 : (((taken - takenLate) / total) * 100).toInt();
}

enum DayState { full, partial, missed, future, empty }

class DayCell {
  const DayCell(this.date, this.state);

  final DateTime date;
  final DayState state;
}

/// Which time of day a patient misses most, and how often. Only produced when the history is
/// strong enough to mean something — see [NirbhorRepository.weakestBlock].
class BlockInsight {
  const BlockInsight(this.block, this.missed, this.total);

  final TimeBlock block;
  final int missed;
  final int total;

  double get missRate => total == 0 ? 0 : missed / total;
  int get missPercent => (missRate * 100).round();
}

class MedAdherence {
  const MedAdherence(this.medicine, this.taken, this.takenLate, this.total);

  final Medicine medicine;
  final int taken;
  final int takenLate;
  final int total;

  int get percent => total == 0 ? 0 : (((taken - takenLate) / total) * 100).toInt();
}

/// Single source of truth for medicines, doses and caregivers. Local-first: all writes are
/// optimistic and immediate; caregiver delivery / sync happen out of band (README > Offline).
///
/// Room handed screens a `Flow` per query. Here the repository is a [ChangeNotifier] that pings
/// after every write, and `RepoBuilder` re-runs its query on that ping — the same "screens never
/// hold stale rows" guarantee with no stream plumbing.
class NirbhorRepository extends ChangeNotifier {
  NirbhorRepository._(this._db);

  final NirbhorDatabase _db;
  Database get _raw => _db.db;

  static NirbhorRepository? _instance;

  static Future<NirbhorRepository> get() async {
    final existing = _instance;
    if (existing != null) return existing;
    final created = NirbhorRepository._(await NirbhorDatabase.get());
    _instance = created;
    return created;
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---- Medicines --------------------------------------------------------

  Future<List<Medicine>> medicines() async {
    final rows = await _raw.query('medicines', orderBy: 'createdAt ASC');
    return rows.map(medicineFromRow).toList();
  }

  Future<Medicine?> medicine(String id) async {
    final rows = await _raw.query('medicines', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : medicineFromRow(rows.first);
  }

  Future<void> upsertMedicine(Medicine medicine) async {
    await _raw.transaction((txn) async {
      final rows =
          await txn.query('medicines', where: 'id = ?', whereArgs: [medicine.id], limit: 1);
      final existing = rows.isEmpty ? null : rows.first;
      final createdAt = (existing?['createdAt'] as num?)?.toInt() ?? _now;
      await txn.insert(
        'medicines',
        medicineToRow(medicine, createdAt: createdAt),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      var scheduleChanged = existing == null;
      if (existing != null) {
        final old = medicineFromRow(existing);
        scheduleChanged = old.frequency != medicine.frequency ||
            old.weekdaysMask != medicine.weekdaysMask ||
            !listEquals(old.timeTokens, medicine.timeTokens) ||
            !listEquals(old.resolvedTimes, medicine.resolvedTimes) ||
            old.paused != medicine.paused;
      }
      if (scheduleChanged) await _regenerateUpcoming(txn, medicine.id);
    });
    notifyListeners();
  }

  /// Deletes a medicine and its doses, returning the removed dose ids so their alarms can be
  /// cancelled. Every caller must cancel them — a reminder notification is posted ongoing, so an
  /// orphaned alarm would leave an undismissable row on the shade.
  Future<List<int>> deleteMedicine(String id) async {
    final removed = <int>[];
    await _raw.transaction((txn) async {
      final rows = await txn.query('doses', columns: ['id'], where: 'medicineId = ?', whereArgs: [id]);
      removed.addAll(rows.map((r) => (r['id'] as num).toInt()));
      await txn.delete('doses', where: 'medicineId = ?', whereArgs: [id]);
      await txn.delete('medicines', where: 'id = ?', whereArgs: [id]);
    });
    notifyListeners();
    return removed;
  }

  Future<void> addStock(String id, int delta) async {
    await _raw.rawUpdate(
      'UPDATE medicines SET stockCount = MAX(0, stockCount + ?), stockUpdatedAt = ? WHERE id = ?',
      [delta, _now, id],
    );
    notifyListeners();
  }

  Future<void> setStock(String id, int count) async {
    await _raw.rawUpdate(
      'UPDATE medicines SET stockCount = ?, stockUpdatedAt = ? WHERE id = ?',
      [count < 0 ? 0 : count, _now, id],
    );
    notifyListeners();
  }

  // ---- Doses ------------------------------------------------------------

  (int, int) _dayBounds(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch - 1);
  }

  /// Ensures every scheduled dose for [date] exists in the DB (idempotent).
  Future<void> ensureDosesFor(DateTime date, {bool notify = true}) async {
    await _ensureDosesFor(_raw, date);
    if (notify) notifyListeners();
  }

  Future<void> _ensureDosesFor(DatabaseExecutor ex, DateTime date) async {
    final (start, end) = _dayBounds(date);
    final existingRows = await ex.query(
      'doses',
      columns: ['medicineId', 'scheduledEpochMillis'],
      where: 'scheduledEpochMillis BETWEEN ? AND ?',
      whereArgs: [start, end],
    );
    final existing = existingRows
        .map((r) => '${r['medicineId']}@${(r['scheduledEpochMillis'] as num).toInt()}')
        .toSet();
    final meds = (await ex.query('medicines')).map(medicineFromRow);

    final batch = ex.batch();
    var queued = 0;
    for (final m in meds) {
      for (final planned in DoseScheduler.dosesFor(m, date)) {
        if (existing.contains('${planned.medicineId}@${planned.epochMillis}')) continue;
        batch.insert(
          'doses',
          {
            'medicineId': planned.medicineId,
            'scheduledEpochMillis': planned.epochMillis,
            'hour': planned.hour,
            'minute': planned.minute,
            'block': planned.block.stored,
            'status': DoseStatus.upcoming.stored,
            'confirmedAt': null,
            'source': null,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        queued++;
      }
    }
    if (queued > 0) await batch.commit(noResult: true);
  }

  /// Regenerates future UPCOMING doses for a medicine after a schedule edit.
  Future<void> _regenerateUpcoming(DatabaseExecutor ex, String medicineId) async {
    final today = dateOnly(DateTime.now());
    await ex.delete(
      'doses',
      where: 'medicineId = ? AND scheduledEpochMillis >= ? AND status = ?',
      whereArgs: [medicineId, _dayBounds(today).$1, DoseStatus.upcoming.stored],
    );
    for (var i = 0; i <= 14; i++) {
      await _ensureDosesFor(ex, today.add(Duration(days: i)));
    }
  }

  /// Doses for [date] grouped into the three time blocks, joined with their medicines.
  Future<List<TimelineBlock>> timelineFor(DateTime date) async {
    final (start, end) = _dayBounds(date);
    final doseRows = await _raw.query(
      'doses',
      where: 'scheduledEpochMillis BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'scheduledEpochMillis ASC',
    );
    final byId = {for (final m in await medicines()) m.id: m};
    final joined = <DoseWithMedicine>[];
    for (final row in doseRows) {
      final dose = doseFromRow(row);
      final med = byId[dose.medicineId];
      if (med != null) joined.add(DoseWithMedicine(dose, med));
    }
    final blocks = <TimelineBlock>[];
    for (final block in TimeBlock.values) {
      final blockDoses = joined.where((d) => d.dose.block == block).toList()
        ..sort((a, b) => a.dose.scheduledEpochMillis.compareTo(b.dose.scheduledEpochMillis));
      if (blockDoses.isEmpty) continue;
      final first = blockDoses.first.dose;
      blocks.add(TimelineBlock(
        block: block,
        hour: first.hour,
        minute: first.minute,
        doses: blockDoses,
      ));
    }
    return blocks;
  }

  Future<void> markTaken(
    int doseId, {
    DoseSource source = DoseSource.home,
    bool? late,
  }) async {
    await _raw.transaction((txn) async {
      final doseRows = await txn.query('doses', where: 'id = ?', whereArgs: [doseId], limit: 1);
      if (doseRows.isEmpty) return;
      final dose = doseFromRow(doseRows.first);
      final medRows =
          await txn.query('medicines', where: 'id = ?', whereArgs: [dose.medicineId], limit: 1);
      if (medRows.isEmpty) return;
      final medicine = medicineFromRow(medRows.first);

      final now = _now;
      final wasLate = late ?? (now > dose.scheduledEpochMillis + 30 * 60000);
      final status = wasLate ? DoseStatus.takenLate : DoseStatus.taken;
      final changed = await txn.rawUpdate(
        'UPDATE doses SET status = ?, confirmedAt = ?, source = ? WHERE id = ? AND status IN (?, ?, ?)',
        [
          status.stored,
          now,
          source.stored,
          doseId,
          DoseStatus.upcoming.stored,
          DoseStatus.missed.stored,
          DoseStatus.skipped.stored,
        ],
      );
      if (changed == 0) return;
      final used = math.max(1, medicine.dosePerIntake.ceil());
      await txn.rawUpdate(
        'UPDATE medicines SET stockCount = MAX(0, stockCount - ?), stockUpdatedAt = ? WHERE id = ?',
        [used, now, medicine.id],
      );
    });
    notifyListeners();
  }

  Future<void> undoTaken(int doseId) async {
    await _raw.transaction((txn) async {
      final doseRows = await txn.query('doses', where: 'id = ?', whereArgs: [doseId], limit: 1);
      if (doseRows.isEmpty) return;
      final dose = doseFromRow(doseRows.first);
      final medRows =
          await txn.query('medicines', where: 'id = ?', whereArgs: [dose.medicineId], limit: 1);
      if (medRows.isEmpty) return;
      final medicine = medicineFromRow(medRows.first);

      final changed = await txn.rawUpdate(
        'UPDATE doses SET status = ?, confirmedAt = NULL, source = NULL WHERE id = ? AND status IN (?, ?)',
        [DoseStatus.upcoming.stored, doseId, DoseStatus.taken.stored, DoseStatus.takenLate.stored],
      );
      if (changed == 0) return;
      final used = math.max(1, medicine.dosePerIntake.ceil());
      await txn.rawUpdate(
        'UPDATE medicines SET stockCount = MAX(0, stockCount + ?), stockUpdatedAt = ? WHERE id = ?',
        [used, _now, medicine.id],
      );
    });
    notifyListeners();
  }

  Future<void> skipDose(int doseId, {DoseSource source = DoseSource.recoverySheet}) async {
    await _raw.rawUpdate(
      'UPDATE doses SET status = ?, confirmedAt = ?, source = ? WHERE id = ? AND status IN (?, ?)',
      [
        DoseStatus.skipped.stored,
        _now,
        source.stored,
        doseId,
        DoseStatus.upcoming.stored,
        DoseStatus.missed.stored,
      ],
    );
    notifyListeners();
  }

  /// Marks unanswered doses missed after a grace period, keeping adherence records truthful.
  Future<List<DoseWithMedicine>> markOverdueDoses({int graceMinutes = 30}) async {
    final result = <DoseWithMedicine>[];
    await _raw.transaction((txn) async {
      final cutoff = _now - math.max(0, graceMinutes) * 60000;
      final rows = await txn.query(
        'doses',
        where: 'status = ? AND scheduledEpochMillis < ?',
        whereArgs: [DoseStatus.upcoming.stored, cutoff],
        orderBy: 'scheduledEpochMillis ASC',
      );
      if (rows.isEmpty) return;
      await txn.rawUpdate(
        'UPDATE doses SET status = ? WHERE status = ? AND scheduledEpochMillis < ?',
        [DoseStatus.missed.stored, DoseStatus.upcoming.stored, cutoff],
      );
      final meds = {for (final m in (await txn.query('medicines')).map(medicineFromRow)) m.id: m};
      for (final row in rows) {
        final dose = doseFromRow({...row, 'status': DoseStatus.missed.stored});
        final med = meds[dose.medicineId];
        if (med != null) result.add(DoseWithMedicine(dose, med));
      }
    });
    if (result.isNotEmpty) notifyListeners();
    return result;
  }

  /// Snooze +10 min (repeats handled by the alarm scheduler); shifts the scheduled time.
  Future<void> snoozeDose(int doseId, {int minutes = 10}) async {
    final rows = await _raw.query('doses', where: 'id = ?', whereArgs: [doseId], limit: 1);
    if (rows.isEmpty) return;
    final dose = doseFromRow(rows.first);
    if (dose.status != DoseStatus.upcoming) return;
    final shifted = DoseScheduler.snoozedEpochMillis(dose.scheduledEpochMillis, _now, minutes);
    if (shifted == null) return;
    final at = DateTime.fromMillisecondsSinceEpoch(shifted);
    await _raw.rawUpdate(
      'UPDATE doses SET scheduledEpochMillis = ?, hour = ?, minute = ? WHERE id = ? AND status = ?',
      [shifted, at.hour, at.minute, doseId, DoseStatus.upcoming.stored],
    );
    notifyListeners();
  }

  // ---- Derivations ------------------------------------------------------

  Future<List<StockStatus>> stockStatuses() async {
    final meds = await medicines();
    final today = dateOnly(DateTime.now());
    return meds.map((m) {
      final days = StockCalculator.estimatedDays(m);
      final runsOut =
          days == null ? null : today.add(Duration(days: days)).millisecondsSinceEpoch;
      return StockStatus(
        medicineId: m.id,
        count: m.stockCount,
        daysRemaining: days,
        isLow: days != null && days <= 5,
        runsOutEpochMillis: runsOut,
      );
    }).toList();
  }

  Future<List<DoseOccurrence>> _dosesBetween(int start, int end) async {
    final rows = await _raw.query(
      'doses',
      where: 'scheduledEpochMillis BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'scheduledEpochMillis ASC',
    );
    return rows.map(doseFromRow).toList();
  }

  Future<AdherenceWindow> adherenceOver(int days) async {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1)).millisecondsSinceEpoch;
    final end = today.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
    final doses = await _dosesBetween(start, end);
    final takenLate = doses.where((d) => d.status == DoseStatus.takenLate).length;
    final taken = doses.where((d) => d.status.isTaken).length;
    final missed = doses.where((d) => d.status == DoseStatus.missed).length;
    final skipped = doses.where((d) => d.status == DoseStatus.skipped).length;
    final total = doses.where((d) => d.status != DoseStatus.upcoming).length;
    return AdherenceWindow(
      taken: taken,
      takenLate: takenLate,
      missed: missed,
      skipped: skipped,
      total: total,
      streakDays: _streak(doses),
    );
  }

  int _streak(List<DoseOccurrence> doses) {
    final byDay = <DateTime, List<DoseOccurrence>>{};
    for (final d in doses) {
      byDay.putIfAbsent(dateOnly(d.scheduledAt), () => []).add(d);
    }
    var streak = 0;
    var day = dateOnly(DateTime.now()).subtract(const Duration(days: 1)); // fully-completed past days
    while (true) {
      final d = byDay[day];
      if (d == null) break;
      final done = d.isNotEmpty && d.every((x) => x.status.isTaken);
      if (!done) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Upcoming doses within [within] from now — used by the alarm scheduler.
  Future<List<DoseOccurrence>> upcomingDoses({Duration within = const Duration(hours: 48)}) async {
    final now = _now;
    final doses = await _dosesBetween(now, now + within.inMilliseconds);
    return doses.where((d) => d.status == DoseStatus.upcoming).toList()
      ..sort((a, b) => a.scheduledEpochMillis.compareTo(b.scheduledEpochMillis));
  }

  /// All doses scheduled around [epochMillis] (±[toleranceMin]) joined with medicines — the alarm
  /// payload.
  Future<List<DoseWithMedicine>> dosesAround(int epochMillis, {int toleranceMin = 30}) async {
    final tol = toleranceMin * 60000;
    final doses = (await _dosesBetween(epochMillis - tol, epochMillis + tol))
        .where((d) => d.status == DoseStatus.upcoming);
    final meds = {for (final m in await medicines()) m.id: m};
    final out = <DoseWithMedicine>[];
    for (final d in doses) {
      final m = meds[d.medicineId];
      if (m != null) out.add(DoseWithMedicine(d, m));
    }
    return out;
  }

  Future<DoseWithMedicine?> doseWithMedicine(int doseId) async {
    final rows = await _raw.query('doses', where: 'id = ?', whereArgs: [doseId], limit: 1);
    if (rows.isEmpty) return null;
    final dose = doseFromRow(rows.first);
    final med = await medicine(dose.medicineId);
    if (med == null) return null;
    return DoseWithMedicine(dose, med);
  }

  /// Per-day completion cells for the record grid (oldest→newest), covering [days] ending today.
  Future<List<DayCell>> dayCells(int days) async {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1)).millisecondsSinceEpoch;
    final end = today.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
    final byDay = <DateTime, List<DoseOccurrence>>{};
    for (final d in await _dosesBetween(start, end)) {
      byDay.putIfAbsent(dateOnly(d.scheduledAt), () => []).add(d);
    }
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final d = byDay[date] ?? const <DoseOccurrence>[];
      final DayState state;
      if (date.isAfter(today)) {
        state = DayState.future;
      } else if (d.isEmpty) {
        state = DayState.empty;
      } else if (date == today && d.any((x) => x.status == DoseStatus.upcoming)) {
        state = d.any((x) => x.status.isTaken) ? DayState.partial : DayState.future;
      } else if (d.every((x) => x.status.isTaken)) {
        state = DayState.full;
      } else if (d.every((x) => x.status == DoseStatus.missed || x.status == DoseStatus.skipped)) {
        state = DayState.missed;
      } else if (d.any((x) => x.status.isTaken)) {
        state = DayState.partial;
      } else {
        state = DayState.missed;
      }
      return DayCell(date, state);
    });
  }

  /// Consecutive days, counting back from today, on which every scheduled dose was taken.
  ///
  /// A day still in progress neither extends nor breaks the run, so the number never drops just
  /// because it is morning and today's doses are not due yet. Days with nothing scheduled are
  /// skipped for the same reason: there was nothing to keep or to break.
  Future<int> currentStreak({int lookback = 120}) async {
    final cells = await dayCells(lookback);
    var streak = 0;
    for (final cell in cells.reversed) {
      switch (cell.state) {
        case DayState.full:
          streak++;
        case DayState.future:
        case DayState.empty:
          continue;
        case DayState.partial:
        case DayState.missed:
          return streak;
      }
    }
    return streak;
  }

  /// The next dose still to come, or null when nothing is scheduled ahead.
  Future<DoseWithMedicine?> nextDose() async {
    final upcoming = await upcomingDoses();
    if (upcoming.isEmpty) return null;
    return doseWithMedicine(upcoming.first.id);
  }

  /// The block of the day the patient misses most often over the last [days].
  ///
  /// Returns null unless the history actually supports a claim: at least [minMissed] misses in
  /// that block, at least [minTotal] doses scheduled in it, and a miss rate clearly worse than the
  /// rest of the day. Telling someone they "often miss the evening" on the strength of two doses
  /// would be a guess dressed as a finding.
  Future<BlockInsight?> weakestBlock({
    int days = 30,
    int minMissed = 3,
    int minTotal = 6,
  }) async {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1)).millisecondsSinceEpoch;
    final end = today.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;

    // Upcoming and skipped doses are excluded: neither is a miss the patient can act on.
    final settled = (await _dosesBetween(start, end))
        .where((d) => d.status.isTaken || d.status == DoseStatus.missed)
        .toList();
    if (settled.isEmpty) return null;

    final totals = <TimeBlock, int>{};
    final missed = <TimeBlock, int>{};
    for (final d in settled) {
      totals[d.block] = (totals[d.block] ?? 0) + 1;
      if (d.status == DoseStatus.missed) {
        missed[d.block] = (missed[d.block] ?? 0) + 1;
      }
    }

    BlockInsight? worst;
    for (final block in TimeBlock.values) {
      final total = totals[block] ?? 0;
      final miss = missed[block] ?? 0;
      if (total < minTotal || miss < minMissed) continue;
      final candidate = BlockInsight(block, miss, total);
      if (worst == null || candidate.missRate > worst.missRate) worst = candidate;
    }
    if (worst == null) return null;

    // Only worth saying if this block is meaningfully worse than the day as a whole.
    final overallMissed = settled.where((d) => d.status == DoseStatus.missed).length;
    final overallRate = overallMissed / settled.length;
    return worst.missRate > overallRate * 1.25 ? worst : null;
  }

  /// Per-medicine adherence over the last [days].
  Future<List<MedAdherence>> perMedicineAdherence(int days) async {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1)).millisecondsSinceEpoch;
    final end = today.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
    final meds = await medicines();
    final byMed = <String, List<DoseOccurrence>>{};
    for (final d in await _dosesBetween(start, end)) {
      byMed.putIfAbsent(d.medicineId, () => []).add(d);
    }
    return meds.map((m) {
      final d = (byMed[m.id] ?? const <DoseOccurrence>[])
          .where((x) => x.status != DoseStatus.upcoming)
          .toList();
      final taken = d.where((x) => x.status.isTaken).length;
      final takenLate = d.where((x) => x.status == DoseStatus.takenLate).length;
      return MedAdherence(m, taken, takenLate, d.length);
    }).toList();
  }

  // ---- Caregiver --------------------------------------------------------

  Future<List<Caregiver>> caregivers() async =>
      (await _raw.query('caregivers')).map(caregiverFromRow).toList();

  Future<Caregiver?> primaryCaregiver() async {
    final rows = await _raw.query('caregivers', limit: 1);
    return rows.isEmpty ? null : caregiverFromRow(rows.first);
  }

  Future<List<AlertLogItem>> alertLog({int limit = 20}) async {
    final rows =
        await _raw.query('alert_log', orderBy: 'sentAtMillis DESC', limit: limit);
    return rows
        .map((r) => AlertLogItem(
              (r['id'] as num).toInt(),
              r['kind'] as String,
              r['message'] as String,
              (r['sentAtMillis'] as num).toInt(),
              r['outcome'] as String,
            ))
        .toList();
  }

  Future<void> upsertCaregiver(Caregiver caregiver) async {
    await _raw.insert('caregivers', caregiverToRow(caregiver),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<void> deleteCaregiver(String id) async {
    await _raw.delete('caregivers', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> addAlert({
    required String caregiverId,
    required String kind,
    required String message,
    required String outcome,
  }) async {
    await _raw.insert('alert_log', {
      'caregiverId': caregiverId,
      'kind': kind,
      'message': message,
      'sentAtMillis': _now,
      'outcome': outcome,
    });
    notifyListeners();
  }
}
