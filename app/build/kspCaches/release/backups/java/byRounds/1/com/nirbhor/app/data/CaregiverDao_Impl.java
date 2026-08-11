package com.nirbhor.app.data;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import java.lang.Class;
import java.lang.Exception;
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
public final class CaregiverDao_Impl implements CaregiverDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<CaregiverEntity> __insertionAdapterOfCaregiverEntity;

  private final EntityInsertionAdapter<AlertLogEntity> __insertionAdapterOfAlertLogEntity;

  private final SharedSQLiteStatement __preparedStmtOfDelete;

  public CaregiverDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfCaregiverEntity = new EntityInsertionAdapter<CaregiverEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `caregivers` (`id`,`name`,`relationship`,`email`,`emailVerified`,`phone`,`channels`,`digestFrequency`,`escalateOnSecondMiss`,`notifyOnMissedTwice`,`notifyOnOutOfStock`,`weeklySummary`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CaregiverEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getName());
        statement.bindString(3, entity.getRelationship());
        statement.bindString(4, entity.getEmail());
        final int _tmp = entity.getEmailVerified() ? 1 : 0;
        statement.bindLong(5, _tmp);
        statement.bindString(6, entity.getPhone());
        statement.bindString(7, entity.getChannels());
        statement.bindString(8, entity.getDigestFrequency());
        final int _tmp_1 = entity.getEscalateOnSecondMiss() ? 1 : 0;
        statement.bindLong(9, _tmp_1);
        final int _tmp_2 = entity.getNotifyOnMissedTwice() ? 1 : 0;
        statement.bindLong(10, _tmp_2);
        final int _tmp_3 = entity.getNotifyOnOutOfStock() ? 1 : 0;
        statement.bindLong(11, _tmp_3);
        final int _tmp_4 = entity.getWeeklySummary() ? 1 : 0;
        statement.bindLong(12, _tmp_4);
      }
    };
    this.__insertionAdapterOfAlertLogEntity = new EntityInsertionAdapter<AlertLogEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `alert_log` (`id`,`caregiverId`,`kind`,`message`,`sentAtMillis`,`outcome`) VALUES (nullif(?, 0),?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final AlertLogEntity entity) {
        statement.bindLong(1, entity.getId());
        statement.bindString(2, entity.getCaregiverId());
        statement.bindString(3, entity.getKind());
        statement.bindString(4, entity.getMessage());
        statement.bindLong(5, entity.getSentAtMillis());
        statement.bindString(6, entity.getOutcome());
      }
    };
    this.__preparedStmtOfDelete = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM caregivers WHERE id = ?";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final CaregiverEntity caregiver,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfCaregiverEntity.insert(caregiver);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object addAlert(final AlertLogEntity alert, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfAlertLogEntity.insert(alert);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object delete(final String id, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDelete.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, id);
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
          __preparedStmtOfDelete.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<CaregiverEntity> observePrimary() {
    final String _sql = "SELECT * FROM caregivers LIMIT 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"caregivers"}, new Callable<CaregiverEntity>() {
      @Override
      @Nullable
      public CaregiverEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfRelationship = CursorUtil.getColumnIndexOrThrow(_cursor, "relationship");
          final int _cursorIndexOfEmail = CursorUtil.getColumnIndexOrThrow(_cursor, "email");
          final int _cursorIndexOfEmailVerified = CursorUtil.getColumnIndexOrThrow(_cursor, "emailVerified");
          final int _cursorIndexOfPhone = CursorUtil.getColumnIndexOrThrow(_cursor, "phone");
          final int _cursorIndexOfChannels = CursorUtil.getColumnIndexOrThrow(_cursor, "channels");
          final int _cursorIndexOfDigestFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "digestFrequency");
          final int _cursorIndexOfEscalateOnSecondMiss = CursorUtil.getColumnIndexOrThrow(_cursor, "escalateOnSecondMiss");
          final int _cursorIndexOfNotifyOnMissedTwice = CursorUtil.getColumnIndexOrThrow(_cursor, "notifyOnMissedTwice");
          final int _cursorIndexOfNotifyOnOutOfStock = CursorUtil.getColumnIndexOrThrow(_cursor, "notifyOnOutOfStock");
          final int _cursorIndexOfWeeklySummary = CursorUtil.getColumnIndexOrThrow(_cursor, "weeklySummary");
          final CaregiverEntity _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpRelationship;
            _tmpRelationship = _cursor.getString(_cursorIndexOfRelationship);
            final String _tmpEmail;
            _tmpEmail = _cursor.getString(_cursorIndexOfEmail);
            final boolean _tmpEmailVerified;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfEmailVerified);
            _tmpEmailVerified = _tmp != 0;
            final String _tmpPhone;
            _tmpPhone = _cursor.getString(_cursorIndexOfPhone);
            final String _tmpChannels;
            _tmpChannels = _cursor.getString(_cursorIndexOfChannels);
            final String _tmpDigestFrequency;
            _tmpDigestFrequency = _cursor.getString(_cursorIndexOfDigestFrequency);
            final boolean _tmpEscalateOnSecondMiss;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfEscalateOnSecondMiss);
            _tmpEscalateOnSecondMiss = _tmp_1 != 0;
            final boolean _tmpNotifyOnMissedTwice;
            final int _tmp_2;
            _tmp_2 = _cursor.getInt(_cursorIndexOfNotifyOnMissedTwice);
            _tmpNotifyOnMissedTwice = _tmp_2 != 0;
            final boolean _tmpNotifyOnOutOfStock;
            final int _tmp_3;
            _tmp_3 = _cursor.getInt(_cursorIndexOfNotifyOnOutOfStock);
            _tmpNotifyOnOutOfStock = _tmp_3 != 0;
            final boolean _tmpWeeklySummary;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfWeeklySummary);
            _tmpWeeklySummary = _tmp_4 != 0;
            _result = new CaregiverEntity(_tmpId,_tmpName,_tmpRelationship,_tmpEmail,_tmpEmailVerified,_tmpPhone,_tmpChannels,_tmpDigestFrequency,_tmpEscalateOnSecondMiss,_tmpNotifyOnMissedTwice,_tmpNotifyOnOutOfStock,_tmpWeeklySummary);
          } else {
            _result = null;
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
  public Object getAll(final Continuation<? super List<CaregiverEntity>> $completion) {
    final String _sql = "SELECT * FROM caregivers";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<CaregiverEntity>>() {
      @Override
      @NonNull
      public List<CaregiverEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfRelationship = CursorUtil.getColumnIndexOrThrow(_cursor, "relationship");
          final int _cursorIndexOfEmail = CursorUtil.getColumnIndexOrThrow(_cursor, "email");
          final int _cursorIndexOfEmailVerified = CursorUtil.getColumnIndexOrThrow(_cursor, "emailVerified");
          final int _cursorIndexOfPhone = CursorUtil.getColumnIndexOrThrow(_cursor, "phone");
          final int _cursorIndexOfChannels = CursorUtil.getColumnIndexOrThrow(_cursor, "channels");
          final int _cursorIndexOfDigestFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "digestFrequency");
          final int _cursorIndexOfEscalateOnSecondMiss = CursorUtil.getColumnIndexOrThrow(_cursor, "escalateOnSecondMiss");
          final int _cursorIndexOfNotifyOnMissedTwice = CursorUtil.getColumnIndexOrThrow(_cursor, "notifyOnMissedTwice");
          final int _cursorIndexOfNotifyOnOutOfStock = CursorUtil.getColumnIndexOrThrow(_cursor, "notifyOnOutOfStock");
          final int _cursorIndexOfWeeklySummary = CursorUtil.getColumnIndexOrThrow(_cursor, "weeklySummary");
          final List<CaregiverEntity> _result = new ArrayList<CaregiverEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final CaregiverEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpRelationship;
            _tmpRelationship = _cursor.getString(_cursorIndexOfRelationship);
            final String _tmpEmail;
            _tmpEmail = _cursor.getString(_cursorIndexOfEmail);
            final boolean _tmpEmailVerified;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfEmailVerified);
            _tmpEmailVerified = _tmp != 0;
            final String _tmpPhone;
            _tmpPhone = _cursor.getString(_cursorIndexOfPhone);
            final String _tmpChannels;
            _tmpChannels = _cursor.getString(_cursorIndexOfChannels);
            final String _tmpDigestFrequency;
            _tmpDigestFrequency = _cursor.getString(_cursorIndexOfDigestFrequency);
            final boolean _tmpEscalateOnSecondMiss;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfEscalateOnSecondMiss);
            _tmpEscalateOnSecondMiss = _tmp_1 != 0;
            final boolean _tmpNotifyOnMissedTwice;
            final int _tmp_2;
            _tmp_2 = _cursor.getInt(_cursorIndexOfNotifyOnMissedTwice);
            _tmpNotifyOnMissedTwice = _tmp_2 != 0;
            final boolean _tmpNotifyOnOutOfStock;
            final int _tmp_3;
            _tmp_3 = _cursor.getInt(_cursorIndexOfNotifyOnOutOfStock);
            _tmpNotifyOnOutOfStock = _tmp_3 != 0;
            final boolean _tmpWeeklySummary;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfWeeklySummary);
            _tmpWeeklySummary = _tmp_4 != 0;
            _item = new CaregiverEntity(_tmpId,_tmpName,_tmpRelationship,_tmpEmail,_tmpEmailVerified,_tmpPhone,_tmpChannels,_tmpDigestFrequency,_tmpEscalateOnSecondMiss,_tmpNotifyOnMissedTwice,_tmpNotifyOnOutOfStock,_tmpWeeklySummary);
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
  public Flow<List<AlertLogEntity>> observeAlerts(final int limit) {
    final String _sql = "SELECT * FROM alert_log ORDER BY sentAtMillis DESC LIMIT ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, limit);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"alert_log"}, new Callable<List<AlertLogEntity>>() {
      @Override
      @NonNull
      public List<AlertLogEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfCaregiverId = CursorUtil.getColumnIndexOrThrow(_cursor, "caregiverId");
          final int _cursorIndexOfKind = CursorUtil.getColumnIndexOrThrow(_cursor, "kind");
          final int _cursorIndexOfMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "message");
          final int _cursorIndexOfSentAtMillis = CursorUtil.getColumnIndexOrThrow(_cursor, "sentAtMillis");
          final int _cursorIndexOfOutcome = CursorUtil.getColumnIndexOrThrow(_cursor, "outcome");
          final List<AlertLogEntity> _result = new ArrayList<AlertLogEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final AlertLogEntity _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpCaregiverId;
            _tmpCaregiverId = _cursor.getString(_cursorIndexOfCaregiverId);
            final String _tmpKind;
            _tmpKind = _cursor.getString(_cursorIndexOfKind);
            final String _tmpMessage;
            _tmpMessage = _cursor.getString(_cursorIndexOfMessage);
            final long _tmpSentAtMillis;
            _tmpSentAtMillis = _cursor.getLong(_cursorIndexOfSentAtMillis);
            final String _tmpOutcome;
            _tmpOutcome = _cursor.getString(_cursorIndexOfOutcome);
            _item = new AlertLogEntity(_tmpId,_tmpCaregiverId,_tmpKind,_tmpMessage,_tmpSentAtMillis,_tmpOutcome);
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

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
