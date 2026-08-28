import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The local store. Schema mirrors the Room entities one-for-one — same table and column names —
/// so an existing `nirbhor.db` from the Kotlin build opens unchanged.
///
/// Version 2 matches Room's version 2: the unique (medicineId, scheduledEpochMillis) index that
/// stops a racing day-generation from inserting the same dose twice.
class NirbhorDatabase {
  NirbhorDatabase._(this.db);

  final Database db;

  static NirbhorDatabase? _instance;

  static Future<NirbhorDatabase> get() async {
    final existing = _instance;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'nirbhor.db');
    final db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async => _createAll(db),
      onUpgrade: (db, from, to) async {
        if (from < 2) {
          // Older builds could race while generating a day and insert the same dose twice.
          // Keep the oldest occurrence before enforcing the invariant in SQLite.
          await db.execute(
            'DELETE FROM doses WHERE id NOT IN '
            '(SELECT MIN(id) FROM doses GROUP BY medicineId, scheduledEpochMillis)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS '
            'index_doses_medicineId_scheduledEpochMillis ON doses (medicineId, scheduledEpochMillis)',
          );
        }
      },
    );
    final created = NirbhorDatabase._(db);
    _instance = created;
    return created;
  }

  static Future<void> _createAll(Database db) async {
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT NOT NULL PRIMARY KEY,
        displayName TEXT NOT NULL,
        packName TEXT NOT NULL,
        strength TEXT NOT NULL,
        form TEXT NOT NULL,
        condition TEXT NOT NULL,
        mark TEXT NOT NULL,
        markColor INTEGER NOT NULL,
        dosePerIntake REAL NOT NULL,
        foodRelation TEXT NOT NULL,
        frequency TEXT NOT NULL,
        weekdaysMask INTEGER NOT NULL,
        timeTokens TEXT NOT NULL,
        resolvedTimes TEXT NOT NULL,
        stockCount INTEGER NOT NULL,
        stockUpdatedAt INTEGER NOT NULL,
        highRisk INTEGER NOT NULL,
        paused INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId TEXT NOT NULL,
        scheduledEpochMillis INTEGER NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        block TEXT NOT NULL,
        status TEXT NOT NULL,
        confirmedAt INTEGER,
        source TEXT
      )
    ''');
    await db.execute('CREATE INDEX index_doses_medicineId ON doses (medicineId)');
    await db.execute(
        'CREATE INDEX index_doses_scheduledEpochMillis ON doses (scheduledEpochMillis)');
    await db.execute('CREATE UNIQUE INDEX index_doses_medicineId_scheduledEpochMillis '
        'ON doses (medicineId, scheduledEpochMillis)');
    await db.execute('''
      CREATE TABLE caregivers (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        email TEXT NOT NULL,
        emailVerified INTEGER NOT NULL,
        phone TEXT NOT NULL,
        channels TEXT NOT NULL,
        digestFrequency TEXT NOT NULL,
        escalateOnSecondMiss INTEGER NOT NULL,
        notifyOnMissedTwice INTEGER NOT NULL,
        notifyOnOutOfStock INTEGER NOT NULL,
        weeklySummary INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE alert_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caregiverId TEXT NOT NULL,
        kind TEXT NOT NULL,
        message TEXT NOT NULL,
        sentAtMillis INTEGER NOT NULL,
        outcome TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX index_alert_log_caregiverId ON alert_log (caregiverId)');
  }
}
