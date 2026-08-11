package com.nirbhor.app.data;

import androidx.annotation.NonNull;
import androidx.room.DatabaseConfiguration;
import androidx.room.InvalidationTracker;
import androidx.room.RoomDatabase;
import androidx.room.RoomOpenHelper;
import androidx.room.migration.AutoMigrationSpec;
import androidx.room.migration.Migration;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.sqlite.db.SupportSQLiteDatabase;
import androidx.sqlite.db.SupportSQLiteOpenHelper;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class NirbhorDatabase_Impl extends NirbhorDatabase {
  private volatile MedicineDao _medicineDao;

  private volatile DoseDao _doseDao;

  private volatile CaregiverDao _caregiverDao;

  @Override
  @NonNull
  protected SupportSQLiteOpenHelper createOpenHelper(@NonNull final DatabaseConfiguration config) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(config, new RoomOpenHelper.Delegate(2) {
      @Override
      public void createAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `medicines` (`id` TEXT NOT NULL, `displayName` TEXT NOT NULL, `packName` TEXT NOT NULL, `strength` TEXT NOT NULL, `form` TEXT NOT NULL, `condition` TEXT NOT NULL, `mark` TEXT NOT NULL, `markColor` INTEGER NOT NULL, `dosePerIntake` REAL NOT NULL, `foodRelation` TEXT NOT NULL, `frequency` TEXT NOT NULL, `weekdaysMask` INTEGER NOT NULL, `timeTokens` TEXT NOT NULL, `resolvedTimes` TEXT NOT NULL, `stockCount` INTEGER NOT NULL, `stockUpdatedAt` INTEGER NOT NULL, `highRisk` INTEGER NOT NULL, `paused` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `doses` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `medicineId` TEXT NOT NULL, `scheduledEpochMillis` INTEGER NOT NULL, `hour` INTEGER NOT NULL, `minute` INTEGER NOT NULL, `block` TEXT NOT NULL, `status` TEXT NOT NULL, `confirmedAt` INTEGER, `source` TEXT)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_doses_medicineId` ON `doses` (`medicineId`)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_doses_scheduledEpochMillis` ON `doses` (`scheduledEpochMillis`)");
        db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS `index_doses_medicineId_scheduledEpochMillis` ON `doses` (`medicineId`, `scheduledEpochMillis`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS `caregivers` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `relationship` TEXT NOT NULL, `email` TEXT NOT NULL, `emailVerified` INTEGER NOT NULL, `phone` TEXT NOT NULL, `channels` TEXT NOT NULL, `digestFrequency` TEXT NOT NULL, `escalateOnSecondMiss` INTEGER NOT NULL, `notifyOnMissedTwice` INTEGER NOT NULL, `notifyOnOutOfStock` INTEGER NOT NULL, `weeklySummary` INTEGER NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `alert_log` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `caregiverId` TEXT NOT NULL, `kind` TEXT NOT NULL, `message` TEXT NOT NULL, `sentAtMillis` INTEGER NOT NULL, `outcome` TEXT NOT NULL)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_alert_log_caregiverId` ON `alert_log` (`caregiverId`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '9af6b3634c01272127002fa23094ddfb')");
      }

      @Override
      public void dropAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("DROP TABLE IF EXISTS `medicines`");
        db.execSQL("DROP TABLE IF EXISTS `doses`");
        db.execSQL("DROP TABLE IF EXISTS `caregivers`");
        db.execSQL("DROP TABLE IF EXISTS `alert_log`");
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onDestructiveMigration(db);
          }
        }
      }

      @Override
      public void onCreate(@NonNull final SupportSQLiteDatabase db) {
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onCreate(db);
          }
        }
      }

      @Override
      public void onOpen(@NonNull final SupportSQLiteDatabase db) {
        mDatabase = db;
        internalInitInvalidationTracker(db);
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onOpen(db);
          }
        }
      }

      @Override
      public void onPreMigrate(@NonNull final SupportSQLiteDatabase db) {
        DBUtil.dropFtsSyncTriggers(db);
      }

      @Override
      public void onPostMigrate(@NonNull final SupportSQLiteDatabase db) {
      }

      @Override
      @NonNull
      public RoomOpenHelper.ValidationResult onValidateSchema(
          @NonNull final SupportSQLiteDatabase db) {
        final HashMap<String, TableInfo.Column> _columnsMedicines = new HashMap<String, TableInfo.Column>(19);
        _columnsMedicines.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("displayName", new TableInfo.Column("displayName", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("packName", new TableInfo.Column("packName", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("strength", new TableInfo.Column("strength", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("form", new TableInfo.Column("form", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("condition", new TableInfo.Column("condition", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("mark", new TableInfo.Column("mark", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("markColor", new TableInfo.Column("markColor", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("dosePerIntake", new TableInfo.Column("dosePerIntake", "REAL", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("foodRelation", new TableInfo.Column("foodRelation", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("frequency", new TableInfo.Column("frequency", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("weekdaysMask", new TableInfo.Column("weekdaysMask", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("timeTokens", new TableInfo.Column("timeTokens", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("resolvedTimes", new TableInfo.Column("resolvedTimes", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("stockCount", new TableInfo.Column("stockCount", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("stockUpdatedAt", new TableInfo.Column("stockUpdatedAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("highRisk", new TableInfo.Column("highRisk", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("paused", new TableInfo.Column("paused", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMedicines.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysMedicines = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesMedicines = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoMedicines = new TableInfo("medicines", _columnsMedicines, _foreignKeysMedicines, _indicesMedicines);
        final TableInfo _existingMedicines = TableInfo.read(db, "medicines");
        if (!_infoMedicines.equals(_existingMedicines)) {
          return new RoomOpenHelper.ValidationResult(false, "medicines(com.nirbhor.app.data.MedicineEntity).\n"
                  + " Expected:\n" + _infoMedicines + "\n"
                  + " Found:\n" + _existingMedicines);
        }
        final HashMap<String, TableInfo.Column> _columnsDoses = new HashMap<String, TableInfo.Column>(9);
        _columnsDoses.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("medicineId", new TableInfo.Column("medicineId", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("scheduledEpochMillis", new TableInfo.Column("scheduledEpochMillis", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("hour", new TableInfo.Column("hour", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("minute", new TableInfo.Column("minute", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("block", new TableInfo.Column("block", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("status", new TableInfo.Column("status", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("confirmedAt", new TableInfo.Column("confirmedAt", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDoses.put("source", new TableInfo.Column("source", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysDoses = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesDoses = new HashSet<TableInfo.Index>(3);
        _indicesDoses.add(new TableInfo.Index("index_doses_medicineId", false, Arrays.asList("medicineId"), Arrays.asList("ASC")));
        _indicesDoses.add(new TableInfo.Index("index_doses_scheduledEpochMillis", false, Arrays.asList("scheduledEpochMillis"), Arrays.asList("ASC")));
        _indicesDoses.add(new TableInfo.Index("index_doses_medicineId_scheduledEpochMillis", true, Arrays.asList("medicineId", "scheduledEpochMillis"), Arrays.asList("ASC", "ASC")));
        final TableInfo _infoDoses = new TableInfo("doses", _columnsDoses, _foreignKeysDoses, _indicesDoses);
        final TableInfo _existingDoses = TableInfo.read(db, "doses");
        if (!_infoDoses.equals(_existingDoses)) {
          return new RoomOpenHelper.ValidationResult(false, "doses(com.nirbhor.app.data.DoseEntity).\n"
                  + " Expected:\n" + _infoDoses + "\n"
                  + " Found:\n" + _existingDoses);
        }
        final HashMap<String, TableInfo.Column> _columnsCaregivers = new HashMap<String, TableInfo.Column>(12);
        _columnsCaregivers.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("relationship", new TableInfo.Column("relationship", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("email", new TableInfo.Column("email", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("emailVerified", new TableInfo.Column("emailVerified", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("phone", new TableInfo.Column("phone", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("channels", new TableInfo.Column("channels", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("digestFrequency", new TableInfo.Column("digestFrequency", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("escalateOnSecondMiss", new TableInfo.Column("escalateOnSecondMiss", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("notifyOnMissedTwice", new TableInfo.Column("notifyOnMissedTwice", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("notifyOnOutOfStock", new TableInfo.Column("notifyOnOutOfStock", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCaregivers.put("weeklySummary", new TableInfo.Column("weeklySummary", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysCaregivers = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesCaregivers = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoCaregivers = new TableInfo("caregivers", _columnsCaregivers, _foreignKeysCaregivers, _indicesCaregivers);
        final TableInfo _existingCaregivers = TableInfo.read(db, "caregivers");
        if (!_infoCaregivers.equals(_existingCaregivers)) {
          return new RoomOpenHelper.ValidationResult(false, "caregivers(com.nirbhor.app.data.CaregiverEntity).\n"
                  + " Expected:\n" + _infoCaregivers + "\n"
                  + " Found:\n" + _existingCaregivers);
        }
        final HashMap<String, TableInfo.Column> _columnsAlertLog = new HashMap<String, TableInfo.Column>(6);
        _columnsAlertLog.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAlertLog.put("caregiverId", new TableInfo.Column("caregiverId", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAlertLog.put("kind", new TableInfo.Column("kind", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAlertLog.put("message", new TableInfo.Column("message", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAlertLog.put("sentAtMillis", new TableInfo.Column("sentAtMillis", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAlertLog.put("outcome", new TableInfo.Column("outcome", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysAlertLog = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesAlertLog = new HashSet<TableInfo.Index>(1);
        _indicesAlertLog.add(new TableInfo.Index("index_alert_log_caregiverId", false, Arrays.asList("caregiverId"), Arrays.asList("ASC")));
        final TableInfo _infoAlertLog = new TableInfo("alert_log", _columnsAlertLog, _foreignKeysAlertLog, _indicesAlertLog);
        final TableInfo _existingAlertLog = TableInfo.read(db, "alert_log");
        if (!_infoAlertLog.equals(_existingAlertLog)) {
          return new RoomOpenHelper.ValidationResult(false, "alert_log(com.nirbhor.app.data.AlertLogEntity).\n"
                  + " Expected:\n" + _infoAlertLog + "\n"
                  + " Found:\n" + _existingAlertLog);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "9af6b3634c01272127002fa23094ddfb", "7431cea3eecae10948cd7a55dd0ee6de");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(config.context).name(config.name).callback(_openCallback).build();
    final SupportSQLiteOpenHelper _helper = config.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "medicines","doses","caregivers","alert_log");
  }

  @Override
  public void clearAllTables() {
    super.assertNotMainThread();
    final SupportSQLiteDatabase _db = super.getOpenHelper().getWritableDatabase();
    try {
      super.beginTransaction();
      _db.execSQL("DELETE FROM `medicines`");
      _db.execSQL("DELETE FROM `doses`");
      _db.execSQL("DELETE FROM `caregivers`");
      _db.execSQL("DELETE FROM `alert_log`");
      super.setTransactionSuccessful();
    } finally {
      super.endTransaction();
      _db.query("PRAGMA wal_checkpoint(FULL)").close();
      if (!_db.inTransaction()) {
        _db.execSQL("VACUUM");
      }
    }
  }

  @Override
  @NonNull
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final HashMap<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(MedicineDao.class, MedicineDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(DoseDao.class, DoseDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(CaregiverDao.class, CaregiverDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  @NonNull
  public Set<Class<? extends AutoMigrationSpec>> getRequiredAutoMigrationSpecs() {
    final HashSet<Class<? extends AutoMigrationSpec>> _autoMigrationSpecsSet = new HashSet<Class<? extends AutoMigrationSpec>>();
    return _autoMigrationSpecsSet;
  }

  @Override
  @NonNull
  public List<Migration> getAutoMigrations(
      @NonNull final Map<Class<? extends AutoMigrationSpec>, AutoMigrationSpec> autoMigrationSpecs) {
    final List<Migration> _autoMigrations = new ArrayList<Migration>();
    return _autoMigrations;
  }

  @Override
  public MedicineDao medicineDao() {
    if (_medicineDao != null) {
      return _medicineDao;
    } else {
      synchronized(this) {
        if(_medicineDao == null) {
          _medicineDao = new MedicineDao_Impl(this);
        }
        return _medicineDao;
      }
    }
  }

  @Override
  public DoseDao doseDao() {
    if (_doseDao != null) {
      return _doseDao;
    } else {
      synchronized(this) {
        if(_doseDao == null) {
          _doseDao = new DoseDao_Impl(this);
        }
        return _doseDao;
      }
    }
  }

  @Override
  public CaregiverDao caregiverDao() {
    if (_caregiverDao != null) {
      return _caregiverDao;
    } else {
      synchronized(this) {
        if(_caregiverDao == null) {
          _caregiverDao = new CaregiverDao_Impl(this);
        }
        return _caregiverDao;
      }
    }
  }
}
