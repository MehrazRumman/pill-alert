package com.nirbhor.app.data;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Integer;
import java.lang.Long;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class DoseDao_Impl implements DoseDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<DoseEntity> __insertionAdapterOfDoseEntity;

  private final EntityDeletionOrUpdateAdapter<DoseEntity> __updateAdapterOfDoseEntity;

  private final SharedSQLiteStatement __preparedStmtOfSetStatus;

  private final SharedSQLiteStatement __preparedStmtOfDeleteUpcomingForMedicine;

  public DoseDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfDoseEntity = new EntityInsertionAdapter<DoseEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `doses` (`id`,`medicineId`,`scheduledEpochMillis`,`hour`,`minute`,`block`,`status`,`confirmedAt`,`source`) VALUES (nullif(?, 0),?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final DoseEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getMedicineId());
        statement.bindLong(3, entity.getScheduledEpochMillis());
        statement.bindLong(4, entity.getHour());
        statement.bindLong(5, entity.getMinute());
        statement.bindString(6, entity.getBlock());
        statement.bindString(7, entity.getStatus());
        if (entity.getConfirmedAt() == null) {
          statement.bindNull(8);
        } else {
          statement.bindLong(8, entity.getConfirmedAt());
        }
        if (entity.getSource() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getSource());
        }
      }
    };
    this.__updateAdapterOfDoseEntity = new EntityDeletionOrUpdateAdapter<DoseEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "UPDATE OR ABORT `doses` SET `id` = ?,`medicineId` = ?,`scheduledEpochMillis` = ?,`hour` = ?,`minute` = ?,`block` = ?,`status` = ?,`confirmedAt` = ?,`source` = ? WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final DoseEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getMedicineId());
        statement.bindLong(3, entity.getScheduledEpochMillis());
        statement.bindLong(4, entity.getHour());
        statement.bindLong(5, entity.getMinute());
        statement.bindString(6, entity.getBlock());
        statement.bindString(7, entity.getStatus());
        if (entity.getConfirmedAt() == null) {
          statement.bindNull(8);
        } else {
          statement.bindLong(8, entity.getConfirmedAt());
        }
        if (entity.getSource() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getSource());
        }
        statement.bindLong(10, entity.getId());
      }
    };
    this.__preparedStmtOfSetStatus = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "UPDATE doses SET status = ?, confirmedAt = ?, source = ? WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteUpcomingForMedicine = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM doses WHERE medicineId = ? AND scheduledEpochMillis >= ? AND status = 'UPCOMING'";
        return _query;
      }
    };
  }

  @Override
  public Object insertAll(final List<DoseEntity> doses,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfDoseEntity.insert(doses);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object update(final DoseEntity dose, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __updateAdapterOfDoseEntity.handle(dose);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object setStatus(final long id, final String status, final Long confirmedAt,
      final String source, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfSetStatus.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, status);
        _argIndex = 2;
        if (confirmedAt == null) {
          _stmt.bindNull(_argIndex);
        } else {
          _stmt.bindLong(_argIndex, confirmedAt);
        }
        _argIndex = 3;
        if (source == null) {
          _stmt.bindNull(_argIndex);
        } else {
          _stmt.bindString(_argIndex, source);
        }
        _argIndex = 4;
        _stmt.bindLong(_argIndex, id);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfSetStatus.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteUpcomingForMedicine(final String medicineId, final long fromMillis,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteUpcomingForMedicine.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, medicineId);
        _argIndex = 2;
        _stmt.bindLong(_argIndex, fromMillis);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteUpcomingForMedicine.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<DoseEntity>> observeBetween(final long startMillis, final long endMillis) {
    final String _sql = "SELECT * FROM doses WHERE scheduledEpochMillis BETWEEN ? AND ? ORDER BY scheduledEpochMillis ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, startMillis);
    _argIndex = 2;
    _statement.bindLong(_argIndex, endMillis);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"doses"}, new Callable<List<DoseEntity>>() {
      @Override
      @NonNull
      public List<DoseEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMedicineId = CursorUtil.getColumnIndexOrThrow(_cursor, "medicineId");
          final int _cursorIndexOfScheduledEpochMillis = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduledEpochMillis");
          final int _cursorIndexOfHour = CursorUtil.getColumnIndexOrThrow(_cursor, "hour");
          final int _cursorIndexOfMinute = CursorUtil.getColumnIndexOrThrow(_cursor, "minute");
          final int _cursorIndexOfBlock = CursorUtil.getColumnIndexOrThrow(_cursor, "block");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfConfirmedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "confirmedAt");
          final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
          final List<DoseEntity> _result = new ArrayList<DoseEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final DoseEntity _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpMedicineId;
            _tmpMedicineId = _cursor.getString(_cursorIndexOfMedicineId);
            final long _tmpScheduledEpochMillis;
            _tmpScheduledEpochMillis = _cursor.getLong(_cursorIndexOfScheduledEpochMillis);
            final int _tmpHour;
            _tmpHour = _cursor.getInt(_cursorIndexOfHour);
            final int _tmpMinute;
            _tmpMinute = _cursor.getInt(_cursorIndexOfMinute);
            final String _tmpBlock;
            _tmpBlock = _cursor.getString(_cursorIndexOfBlock);
            final String _tmpStatus;
            _tmpStatus = _cursor.getString(_cursorIndexOfStatus);
            final Long _tmpConfirmedAt;
            if (_cursor.isNull(_cursorIndexOfConfirmedAt)) {
              _tmpConfirmedAt = null;
            } else {
              _tmpConfirmedAt = _cursor.getLong(_cursorIndexOfConfirmedAt);
            }
            final String _tmpSource;
            if (_cursor.isNull(_cursorIndexOfSource)) {
              _tmpSource = null;
            } else {
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
            }
            _item = new DoseEntity(_tmpId,_tmpMedicineId,_tmpScheduledEpochMillis,_tmpHour,_tmpMinute,_tmpBlock,_tmpStatus,_tmpConfirmedAt,_tmpSource);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getBetween(final long startMillis, final long endMillis,
      final Continuation<? super List<DoseEntity>> $completion) {
    final String _sql = "SELECT * FROM doses WHERE scheduledEpochMillis BETWEEN ? AND ? ORDER BY scheduledEpochMillis ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, startMillis);
    _argIndex = 2;
    _statement.bindLong(_argIndex, endMillis);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<DoseEntity>>() {
      @Override
      @NonNull
      public List<DoseEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMedicineId = CursorUtil.getColumnIndexOrThrow(_cursor, "medicineId");
          final int _cursorIndexOfScheduledEpochMillis = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduledEpochMillis");
          final int _cursorIndexOfHour = CursorUtil.getColumnIndexOrThrow(_cursor, "hour");
          final int _cursorIndexOfMinute = CursorUtil.getColumnIndexOrThrow(_cursor, "minute");
          final int _cursorIndexOfBlock = CursorUtil.getColumnIndexOrThrow(_cursor, "block");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfConfirmedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "confirmedAt");
          final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
          final List<DoseEntity> _result = new ArrayList<DoseEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final DoseEntity _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpMedicineId;
            _tmpMedicineId = _cursor.getString(_cursorIndexOfMedicineId);
            final long _tmpScheduledEpochMillis;
            _tmpScheduledEpochMillis = _cursor.getLong(_cursorIndexOfScheduledEpochMillis);
            final int _tmpHour;
            _tmpHour = _cursor.getInt(_cursorIndexOfHour);
            final int _tmpMinute;
            _tmpMinute = _cursor.getInt(_cursorIndexOfMinute);
            final String _tmpBlock;
            _tmpBlock = _cursor.getString(_cursorIndexOfBlock);
            final String _tmpStatus;
            _tmpStatus = _cursor.getString(_cursorIndexOfStatus);
            final Long _tmpConfirmedAt;
            if (_cursor.isNull(_cursorIndexOfConfirmedAt)) {
              _tmpConfirmedAt = null;
            } else {
              _tmpConfirmedAt = _cursor.getLong(_cursorIndexOfConfirmedAt);
            }
            final String _tmpSource;
            if (_cursor.isNull(_cursorIndexOfSource)) {
              _tmpSource = null;
            } else {
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
            }
            _item = new DoseEntity(_tmpId,_tmpMedicineId,_tmpScheduledEpochMillis,_tmpHour,_tmpMinute,_tmpBlock,_tmpStatus,_tmpConfirmedAt,_tmpSource);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object get(final long id, final Continuation<? super DoseEntity> $completion) {
    final String _sql = "SELECT * FROM doses WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<DoseEntity>() {
      @Override
      @Nullable
      public DoseEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMedicineId = CursorUtil.getColumnIndexOrThrow(_cursor, "medicineId");
          final int _cursorIndexOfScheduledEpochMillis = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduledEpochMillis");
          final int _cursorIndexOfHour = CursorUtil.getColumnIndexOrThrow(_cursor, "hour");
          final int _cursorIndexOfMinute = CursorUtil.getColumnIndexOrThrow(_cursor, "minute");
          final int _cursorIndexOfBlock = CursorUtil.getColumnIndexOrThrow(_cursor, "block");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfConfirmedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "confirmedAt");
          final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
          final DoseEntity _result;
          if (_cursor.moveToFirst()) {
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpMedicineId;
            _tmpMedicineId = _cursor.getString(_cursorIndexOfMedicineId);
            final long _tmpScheduledEpochMillis;
            _tmpScheduledEpochMillis = _cursor.getLong(_cursorIndexOfScheduledEpochMillis);
            final int _tmpHour;
            _tmpHour = _cursor.getInt(_cursorIndexOfHour);
            final int _tmpMinute;
            _tmpMinute = _cursor.getInt(_cursorIndexOfMinute);
            final String _tmpBlock;
            _tmpBlock = _cursor.getString(_cursorIndexOfBlock);
            final String _tmpStatus;
            _tmpStatus = _cursor.getString(_cursorIndexOfStatus);
            final Long _tmpConfirmedAt;
            if (_cursor.isNull(_cursorIndexOfConfirmedAt)) {
              _tmpConfirmedAt = null;
            } else {
              _tmpConfirmedAt = _cursor.getLong(_cursorIndexOfConfirmedAt);
            }
            final String _tmpSource;
            if (_cursor.isNull(_cursorIndexOfSource)) {
              _tmpSource = null;
            } else {
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
            }
            _result = new DoseEntity(_tmpId,_tmpMedicineId,_tmpScheduledEpochMillis,_tmpHour,_tmpMinute,_tmpBlock,_tmpStatus,_tmpConfirmedAt,_tmpSource);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object getForMedicineBetween(final String medicineId, final long startMillis,
      final long endMillis, final Continuation<? super List<DoseEntity>> $completion) {
    final String _sql = "SELECT * FROM doses WHERE medicineId = ? AND scheduledEpochMillis BETWEEN ? AND ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 3);
    int _argIndex = 1;
    _statement.bindString(_argIndex, medicineId);
    _argIndex = 2;
    _statement.bindLong(_argIndex, startMillis);
    _argIndex = 3;
    _statement.bindLong(_argIndex, endMillis);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<DoseEntity>>() {
      @Override
      @NonNull
      public List<DoseEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMedicineId = CursorUtil.getColumnIndexOrThrow(_cursor, "medicineId");
          final int _cursorIndexOfScheduledEpochMillis = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduledEpochMillis");
          final int _cursorIndexOfHour = CursorUtil.getColumnIndexOrThrow(_cursor, "hour");
          final int _cursorIndexOfMinute = CursorUtil.getColumnIndexOrThrow(_cursor, "minute");
          final int _cursorIndexOfBlock = CursorUtil.getColumnIndexOrThrow(_cursor, "block");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfConfirmedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "confirmedAt");
          final int _cursorIndexOfSource = CursorUtil.getColumnIndexOrThrow(_cursor, "source");
          final List<DoseEntity> _result = new ArrayList<DoseEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final DoseEntity _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpMedicineId;
            _tmpMedicineId = _cursor.getString(_cursorIndexOfMedicineId);
            final long _tmpScheduledEpochMillis;
            _tmpScheduledEpochMillis = _cursor.getLong(_cursorIndexOfScheduledEpochMillis);
            final int _tmpHour;
            _tmpHour = _cursor.getInt(_cursorIndexOfHour);
            final int _tmpMinute;
            _tmpMinute = _cursor.getInt(_cursorIndexOfMinute);
            final String _tmpBlock;
            _tmpBlock = _cursor.getString(_cursorIndexOfBlock);
            final String _tmpStatus;
            _tmpStatus = _cursor.getString(_cursorIndexOfStatus);
            final Long _tmpConfirmedAt;
            if (_cursor.isNull(_cursorIndexOfConfirmedAt)) {
              _tmpConfirmedAt = null;
            } else {
              _tmpConfirmedAt = _cursor.getLong(_cursorIndexOfConfirmedAt);
            }
            final String _tmpSource;
            if (_cursor.isNull(_cursorIndexOfSource)) {
              _tmpSource = null;
            } else {
              _tmpSource = _cursor.getString(_cursorIndexOfSource);
            }
            _item = new DoseEntity(_tmpId,_tmpMedicineId,_tmpScheduledEpochMillis,_tmpHour,_tmpMinute,_tmpBlock,_tmpStatus,_tmpConfirmedAt,_tmpSource);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object countBetween(final long startMillis, final long endMillis,
      final Continuation<? super Integer> $completion) {
    final String _sql = "SELECT COUNT(*) FROM doses WHERE scheduledEpochMillis BETWEEN ? AND ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, startMillis);
    _argIndex = 2;
    _statement.bindLong(_argIndex, endMillis);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<Integer>() {
      @Override
      @NonNull
      public Integer call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final Integer _result;
          if (_cursor.moveToFirst()) {
            final int _tmp;
            _tmp = _cursor.getInt(0);
            _result = _tmp;
          } else {
            _result = 0;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
