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
public final class MedicineDao_Impl implements MedicineDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<MedicineEntity> __insertionAdapterOfMedicineEntity;

  private final EntityDeletionOrUpdateAdapter<MedicineEntity> __updateAdapterOfMedicineEntity;

  private final SharedSQLiteStatement __preparedStmtOfSetStock;

  private final SharedSQLiteStatement __preparedStmtOfDelete;

  public MedicineDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfMedicineEntity = new EntityInsertionAdapter<MedicineEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `medicines` (`id`,`displayName`,`packName`,`strength`,`form`,`condition`,`mark`,`markColor`,`dosePerIntake`,`foodRelation`,`frequency`,`weekdaysMask`,`timeTokens`,`resolvedTimes`,`stockCount`,`stockUpdatedAt`,`highRisk`,`paused`,`createdAt`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final MedicineEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getDisplayName());
        statement.bindString(3, entity.getPackName());
        statement.bindString(4, entity.getStrength());
        statement.bindString(5, entity.getForm());
        statement.bindString(6, entity.getCondition());
        statement.bindString(7, entity.getMark());
        statement.bindLong(8, entity.getMarkColor());
        statement.bindDouble(9, entity.getDosePerIntake());
        statement.bindString(10, entity.getFoodRelation());
        statement.bindString(11, entity.getFrequency());
        statement.bindLong(12, entity.getWeekdaysMask());
        statement.bindString(13, entity.getTimeTokens());
        statement.bindString(14, entity.getResolvedTimes());
        statement.bindLong(15, entity.getStockCount());
        statement.bindLong(16, entity.getStockUpdatedAt());
        final int _tmp = entity.getHighRisk() ? 1 : 0;
        statement.bindLong(17, _tmp);
        final int _tmp_1 = entity.getPaused() ? 1 : 0;
        statement.bindLong(18, _tmp_1);
        statement.bindLong(19, entity.getCreatedAt());
      }
    };
    this.__updateAdapterOfMedicineEntity = new EntityDeletionOrUpdateAdapter<MedicineEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "UPDATE OR ABORT `medicines` SET `id` = ?,`displayName` = ?,`packName` = ?,`strength` = ?,`form` = ?,`condition` = ?,`mark` = ?,`markColor` = ?,`dosePerIntake` = ?,`foodRelation` = ?,`frequency` = ?,`weekdaysMask` = ?,`timeTokens` = ?,`resolvedTimes` = ?,`stockCount` = ?,`stockUpdatedAt` = ?,`highRisk` = ?,`paused` = ?,`createdAt` = ? WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final MedicineEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getDisplayName());
        statement.bindString(3, entity.getPackName());
        statement.bindString(4, entity.getStrength());
        statement.bindString(5, entity.getForm());
        statement.bindString(6, entity.getCondition());
        statement.bindString(7, entity.getMark());
        statement.bindLong(8, entity.getMarkColor());
        statement.bindDouble(9, entity.getDosePerIntake());
        statement.bindString(10, entity.getFoodRelation());
        statement.bindString(11, entity.getFrequency());
        statement.bindLong(12, entity.getWeekdaysMask());
        statement.bindString(13, entity.getTimeTokens());
        statement.bindString(14, entity.getResolvedTimes());
        statement.bindLong(15, entity.getStockCount());
        statement.bindLong(16, entity.getStockUpdatedAt());
        final int _tmp = entity.getHighRisk() ? 1 : 0;
        statement.bindLong(17, _tmp);
        final int _tmp_1 = entity.getPaused() ? 1 : 0;
        statement.bindLong(18, _tmp_1);
        statement.bindLong(19, entity.getCreatedAt());
        statement.bindString(20, entity.getId());
      }
    };
    this.__preparedStmtOfSetStock = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "UPDATE medicines SET stockCount = ?, stockUpdatedAt = ? WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDelete = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM medicines WHERE id = ?";
        return _query;
      }
    };
  }

  @Override
  public Object upsert(final MedicineEntity medicine,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfMedicineEntity.insert(medicine);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object update(final MedicineEntity medicine,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __updateAdapterOfMedicineEntity.handle(medicine);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object setStock(final String id, final int count, final long updatedAt,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfSetStock.acquire();
        int _argIndex = 1;
        _stmt.bindLong(_argIndex, count);
        _argIndex = 2;
        _stmt.bindLong(_argIndex, updatedAt);
        _argIndex = 3;
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
          __preparedStmtOfSetStock.release(_stmt);
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
  public Flow<List<MedicineEntity>> observeAll() {
    final String _sql = "SELECT * FROM medicines ORDER BY createdAt ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"medicines"}, new Callable<List<MedicineEntity>>() {
      @Override
      @NonNull
      public List<MedicineEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfDisplayName = CursorUtil.getColumnIndexOrThrow(_cursor, "displayName");
          final int _cursorIndexOfPackName = CursorUtil.getColumnIndexOrThrow(_cursor, "packName");
          final int _cursorIndexOfStrength = CursorUtil.getColumnIndexOrThrow(_cursor, "strength");
          final int _cursorIndexOfForm = CursorUtil.getColumnIndexOrThrow(_cursor, "form");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfMark = CursorUtil.getColumnIndexOrThrow(_cursor, "mark");
          final int _cursorIndexOfMarkColor = CursorUtil.getColumnIndexOrThrow(_cursor, "markColor");
          final int _cursorIndexOfDosePerIntake = CursorUtil.getColumnIndexOrThrow(_cursor, "dosePerIntake");
          final int _cursorIndexOfFoodRelation = CursorUtil.getColumnIndexOrThrow(_cursor, "foodRelation");
          final int _cursorIndexOfFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "frequency");
          final int _cursorIndexOfWeekdaysMask = CursorUtil.getColumnIndexOrThrow(_cursor, "weekdaysMask");
          final int _cursorIndexOfTimeTokens = CursorUtil.getColumnIndexOrThrow(_cursor, "timeTokens");
          final int _cursorIndexOfResolvedTimes = CursorUtil.getColumnIndexOrThrow(_cursor, "resolvedTimes");
          final int _cursorIndexOfStockCount = CursorUtil.getColumnIndexOrThrow(_cursor, "stockCount");
          final int _cursorIndexOfStockUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "stockUpdatedAt");
          final int _cursorIndexOfHighRisk = CursorUtil.getColumnIndexOrThrow(_cursor, "highRisk");
          final int _cursorIndexOfPaused = CursorUtil.getColumnIndexOrThrow(_cursor, "paused");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<MedicineEntity> _result = new ArrayList<MedicineEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final MedicineEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpDisplayName;
            _tmpDisplayName = _cursor.getString(_cursorIndexOfDisplayName);
            final String _tmpPackName;
            _tmpPackName = _cursor.getString(_cursorIndexOfPackName);
            final String _tmpStrength;
            _tmpStrength = _cursor.getString(_cursorIndexOfStrength);
            final String _tmpForm;
            _tmpForm = _cursor.getString(_cursorIndexOfForm);
            final String _tmpCondition;
            _tmpCondition = _cursor.getString(_cursorIndexOfCondition);
            final String _tmpMark;
            _tmpMark = _cursor.getString(_cursorIndexOfMark);
            final long _tmpMarkColor;
            _tmpMarkColor = _cursor.getLong(_cursorIndexOfMarkColor);
            final float _tmpDosePerIntake;
            _tmpDosePerIntake = _cursor.getFloat(_cursorIndexOfDosePerIntake);
            final String _tmpFoodRelation;
            _tmpFoodRelation = _cursor.getString(_cursorIndexOfFoodRelation);
            final String _tmpFrequency;
            _tmpFrequency = _cursor.getString(_cursorIndexOfFrequency);
            final int _tmpWeekdaysMask;
            _tmpWeekdaysMask = _cursor.getInt(_cursorIndexOfWeekdaysMask);
            final String _tmpTimeTokens;
            _tmpTimeTokens = _cursor.getString(_cursorIndexOfTimeTokens);
            final String _tmpResolvedTimes;
            _tmpResolvedTimes = _cursor.getString(_cursorIndexOfResolvedTimes);
            final int _tmpStockCount;
            _tmpStockCount = _cursor.getInt(_cursorIndexOfStockCount);
            final long _tmpStockUpdatedAt;
            _tmpStockUpdatedAt = _cursor.getLong(_cursorIndexOfStockUpdatedAt);
            final boolean _tmpHighRisk;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfHighRisk);
            _tmpHighRisk = _tmp != 0;
            final boolean _tmpPaused;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfPaused);
            _tmpPaused = _tmp_1 != 0;
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new MedicineEntity(_tmpId,_tmpDisplayName,_tmpPackName,_tmpStrength,_tmpForm,_tmpCondition,_tmpMark,_tmpMarkColor,_tmpDosePerIntake,_tmpFoodRelation,_tmpFrequency,_tmpWeekdaysMask,_tmpTimeTokens,_tmpResolvedTimes,_tmpStockCount,_tmpStockUpdatedAt,_tmpHighRisk,_tmpPaused,_tmpCreatedAt);
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
  public Flow<MedicineEntity> observe(final String id) {
    final String _sql = "SELECT * FROM medicines WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"medicines"}, new Callable<MedicineEntity>() {
      @Override
      @Nullable
      public MedicineEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfDisplayName = CursorUtil.getColumnIndexOrThrow(_cursor, "displayName");
          final int _cursorIndexOfPackName = CursorUtil.getColumnIndexOrThrow(_cursor, "packName");
          final int _cursorIndexOfStrength = CursorUtil.getColumnIndexOrThrow(_cursor, "strength");
          final int _cursorIndexOfForm = CursorUtil.getColumnIndexOrThrow(_cursor, "form");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfMark = CursorUtil.getColumnIndexOrThrow(_cursor, "mark");
          final int _cursorIndexOfMarkColor = CursorUtil.getColumnIndexOrThrow(_cursor, "markColor");
          final int _cursorIndexOfDosePerIntake = CursorUtil.getColumnIndexOrThrow(_cursor, "dosePerIntake");
          final int _cursorIndexOfFoodRelation = CursorUtil.getColumnIndexOrThrow(_cursor, "foodRelation");
          final int _cursorIndexOfFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "frequency");
          final int _cursorIndexOfWeekdaysMask = CursorUtil.getColumnIndexOrThrow(_cursor, "weekdaysMask");
          final int _cursorIndexOfTimeTokens = CursorUtil.getColumnIndexOrThrow(_cursor, "timeTokens");
          final int _cursorIndexOfResolvedTimes = CursorUtil.getColumnIndexOrThrow(_cursor, "resolvedTimes");
          final int _cursorIndexOfStockCount = CursorUtil.getColumnIndexOrThrow(_cursor, "stockCount");
          final int _cursorIndexOfStockUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "stockUpdatedAt");
          final int _cursorIndexOfHighRisk = CursorUtil.getColumnIndexOrThrow(_cursor, "highRisk");
          final int _cursorIndexOfPaused = CursorUtil.getColumnIndexOrThrow(_cursor, "paused");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final MedicineEntity _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpDisplayName;
            _tmpDisplayName = _cursor.getString(_cursorIndexOfDisplayName);
            final String _tmpPackName;
            _tmpPackName = _cursor.getString(_cursorIndexOfPackName);
            final String _tmpStrength;
            _tmpStrength = _cursor.getString(_cursorIndexOfStrength);
            final String _tmpForm;
            _tmpForm = _cursor.getString(_cursorIndexOfForm);
            final String _tmpCondition;
            _tmpCondition = _cursor.getString(_cursorIndexOfCondition);
            final String _tmpMark;
            _tmpMark = _cursor.getString(_cursorIndexOfMark);
            final long _tmpMarkColor;
            _tmpMarkColor = _cursor.getLong(_cursorIndexOfMarkColor);
            final float _tmpDosePerIntake;
            _tmpDosePerIntake = _cursor.getFloat(_cursorIndexOfDosePerIntake);
            final String _tmpFoodRelation;
            _tmpFoodRelation = _cursor.getString(_cursorIndexOfFoodRelation);
            final String _tmpFrequency;
            _tmpFrequency = _cursor.getString(_cursorIndexOfFrequency);
            final int _tmpWeekdaysMask;
            _tmpWeekdaysMask = _cursor.getInt(_cursorIndexOfWeekdaysMask);
            final String _tmpTimeTokens;
            _tmpTimeTokens = _cursor.getString(_cursorIndexOfTimeTokens);
            final String _tmpResolvedTimes;
            _tmpResolvedTimes = _cursor.getString(_cursorIndexOfResolvedTimes);
            final int _tmpStockCount;
            _tmpStockCount = _cursor.getInt(_cursorIndexOfStockCount);
            final long _tmpStockUpdatedAt;
            _tmpStockUpdatedAt = _cursor.getLong(_cursorIndexOfStockUpdatedAt);
            final boolean _tmpHighRisk;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfHighRisk);
            _tmpHighRisk = _tmp != 0;
            final boolean _tmpPaused;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfPaused);
            _tmpPaused = _tmp_1 != 0;
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _result = new MedicineEntity(_tmpId,_tmpDisplayName,_tmpPackName,_tmpStrength,_tmpForm,_tmpCondition,_tmpMark,_tmpMarkColor,_tmpDosePerIntake,_tmpFoodRelation,_tmpFrequency,_tmpWeekdaysMask,_tmpTimeTokens,_tmpResolvedTimes,_tmpStockCount,_tmpStockUpdatedAt,_tmpHighRisk,_tmpPaused,_tmpCreatedAt);
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
  public Object get(final String id, final Continuation<? super MedicineEntity> $completion) {
    final String _sql = "SELECT * FROM medicines WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<MedicineEntity>() {
      @Override
      @Nullable
      public MedicineEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfDisplayName = CursorUtil.getColumnIndexOrThrow(_cursor, "displayName");
          final int _cursorIndexOfPackName = CursorUtil.getColumnIndexOrThrow(_cursor, "packName");
          final int _cursorIndexOfStrength = CursorUtil.getColumnIndexOrThrow(_cursor, "strength");
          final int _cursorIndexOfForm = CursorUtil.getColumnIndexOrThrow(_cursor, "form");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfMark = CursorUtil.getColumnIndexOrThrow(_cursor, "mark");
          final int _cursorIndexOfMarkColor = CursorUtil.getColumnIndexOrThrow(_cursor, "markColor");
          final int _cursorIndexOfDosePerIntake = CursorUtil.getColumnIndexOrThrow(_cursor, "dosePerIntake");
          final int _cursorIndexOfFoodRelation = CursorUtil.getColumnIndexOrThrow(_cursor, "foodRelation");
          final int _cursorIndexOfFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "frequency");
          final int _cursorIndexOfWeekdaysMask = CursorUtil.getColumnIndexOrThrow(_cursor, "weekdaysMask");
          final int _cursorIndexOfTimeTokens = CursorUtil.getColumnIndexOrThrow(_cursor, "timeTokens");
          final int _cursorIndexOfResolvedTimes = CursorUtil.getColumnIndexOrThrow(_cursor, "resolvedTimes");
          final int _cursorIndexOfStockCount = CursorUtil.getColumnIndexOrThrow(_cursor, "stockCount");
          final int _cursorIndexOfStockUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "stockUpdatedAt");
          final int _cursorIndexOfHighRisk = CursorUtil.getColumnIndexOrThrow(_cursor, "highRisk");
          final int _cursorIndexOfPaused = CursorUtil.getColumnIndexOrThrow(_cursor, "paused");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final MedicineEntity _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpDisplayName;
            _tmpDisplayName = _cursor.getString(_cursorIndexOfDisplayName);
            final String _tmpPackName;
            _tmpPackName = _cursor.getString(_cursorIndexOfPackName);
            final String _tmpStrength;
            _tmpStrength = _cursor.getString(_cursorIndexOfStrength);
            final String _tmpForm;
            _tmpForm = _cursor.getString(_cursorIndexOfForm);
            final String _tmpCondition;
            _tmpCondition = _cursor.getString(_cursorIndexOfCondition);
            final String _tmpMark;
            _tmpMark = _cursor.getString(_cursorIndexOfMark);
            final long _tmpMarkColor;
            _tmpMarkColor = _cursor.getLong(_cursorIndexOfMarkColor);
            final float _tmpDosePerIntake;
            _tmpDosePerIntake = _cursor.getFloat(_cursorIndexOfDosePerIntake);
            final String _tmpFoodRelation;
            _tmpFoodRelation = _cursor.getString(_cursorIndexOfFoodRelation);
            final String _tmpFrequency;
            _tmpFrequency = _cursor.getString(_cursorIndexOfFrequency);
            final int _tmpWeekdaysMask;
            _tmpWeekdaysMask = _cursor.getInt(_cursorIndexOfWeekdaysMask);
            final String _tmpTimeTokens;
            _tmpTimeTokens = _cursor.getString(_cursorIndexOfTimeTokens);
            final String _tmpResolvedTimes;
            _tmpResolvedTimes = _cursor.getString(_cursorIndexOfResolvedTimes);
            final int _tmpStockCount;
            _tmpStockCount = _cursor.getInt(_cursorIndexOfStockCount);
            final long _tmpStockUpdatedAt;
            _tmpStockUpdatedAt = _cursor.getLong(_cursorIndexOfStockUpdatedAt);
            final boolean _tmpHighRisk;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfHighRisk);
            _tmpHighRisk = _tmp != 0;
            final boolean _tmpPaused;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfPaused);
            _tmpPaused = _tmp_1 != 0;
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _result = new MedicineEntity(_tmpId,_tmpDisplayName,_tmpPackName,_tmpStrength,_tmpForm,_tmpCondition,_tmpMark,_tmpMarkColor,_tmpDosePerIntake,_tmpFoodRelation,_tmpFrequency,_tmpWeekdaysMask,_tmpTimeTokens,_tmpResolvedTimes,_tmpStockCount,_tmpStockUpdatedAt,_tmpHighRisk,_tmpPaused,_tmpCreatedAt);
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
  public Object getAll(final Continuation<? super List<MedicineEntity>> $completion) {
    final String _sql = "SELECT * FROM medicines";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<MedicineEntity>>() {
      @Override
      @NonNull
      public List<MedicineEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfDisplayName = CursorUtil.getColumnIndexOrThrow(_cursor, "displayName");
          final int _cursorIndexOfPackName = CursorUtil.getColumnIndexOrThrow(_cursor, "packName");
          final int _cursorIndexOfStrength = CursorUtil.getColumnIndexOrThrow(_cursor, "strength");
          final int _cursorIndexOfForm = CursorUtil.getColumnIndexOrThrow(_cursor, "form");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfMark = CursorUtil.getColumnIndexOrThrow(_cursor, "mark");
          final int _cursorIndexOfMarkColor = CursorUtil.getColumnIndexOrThrow(_cursor, "markColor");
          final int _cursorIndexOfDosePerIntake = CursorUtil.getColumnIndexOrThrow(_cursor, "dosePerIntake");
          final int _cursorIndexOfFoodRelation = CursorUtil.getColumnIndexOrThrow(_cursor, "foodRelation");
          final int _cursorIndexOfFrequency = CursorUtil.getColumnIndexOrThrow(_cursor, "frequency");
          final int _cursorIndexOfWeekdaysMask = CursorUtil.getColumnIndexOrThrow(_cursor, "weekdaysMask");
          final int _cursorIndexOfTimeTokens = CursorUtil.getColumnIndexOrThrow(_cursor, "timeTokens");
          final int _cursorIndexOfResolvedTimes = CursorUtil.getColumnIndexOrThrow(_cursor, "resolvedTimes");
          final int _cursorIndexOfStockCount = CursorUtil.getColumnIndexOrThrow(_cursor, "stockCount");
          final int _cursorIndexOfStockUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "stockUpdatedAt");
          final int _cursorIndexOfHighRisk = CursorUtil.getColumnIndexOrThrow(_cursor, "highRisk");
          final int _cursorIndexOfPaused = CursorUtil.getColumnIndexOrThrow(_cursor, "paused");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<MedicineEntity> _result = new ArrayList<MedicineEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final MedicineEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpDisplayName;
            _tmpDisplayName = _cursor.getString(_cursorIndexOfDisplayName);
            final String _tmpPackName;
            _tmpPackName = _cursor.getString(_cursorIndexOfPackName);
            final String _tmpStrength;
            _tmpStrength = _cursor.getString(_cursorIndexOfStrength);
            final String _tmpForm;
            _tmpForm = _cursor.getString(_cursorIndexOfForm);
            final String _tmpCondition;
            _tmpCondition = _cursor.getString(_cursorIndexOfCondition);
            final String _tmpMark;
            _tmpMark = _cursor.getString(_cursorIndexOfMark);
            final long _tmpMarkColor;
            _tmpMarkColor = _cursor.getLong(_cursorIndexOfMarkColor);
            final float _tmpDosePerIntake;
            _tmpDosePerIntake = _cursor.getFloat(_cursorIndexOfDosePerIntake);
            final String _tmpFoodRelation;
            _tmpFoodRelation = _cursor.getString(_cursorIndexOfFoodRelation);
            final String _tmpFrequency;
            _tmpFrequency = _cursor.getString(_cursorIndexOfFrequency);
            final int _tmpWeekdaysMask;
            _tmpWeekdaysMask = _cursor.getInt(_cursorIndexOfWeekdaysMask);
            final String _tmpTimeTokens;
            _tmpTimeTokens = _cursor.getString(_cursorIndexOfTimeTokens);
            final String _tmpResolvedTimes;
            _tmpResolvedTimes = _cursor.getString(_cursorIndexOfResolvedTimes);
            final int _tmpStockCount;
            _tmpStockCount = _cursor.getInt(_cursorIndexOfStockCount);
            final long _tmpStockUpdatedAt;
            _tmpStockUpdatedAt = _cursor.getLong(_cursorIndexOfStockUpdatedAt);
            final boolean _tmpHighRisk;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfHighRisk);
            _tmpHighRisk = _tmp != 0;
            final boolean _tmpPaused;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfPaused);
            _tmpPaused = _tmp_1 != 0;
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new MedicineEntity(_tmpId,_tmpDisplayName,_tmpPackName,_tmpStrength,_tmpForm,_tmpCondition,_tmpMark,_tmpMarkColor,_tmpDosePerIntake,_tmpFoodRelation,_tmpFrequency,_tmpWeekdaysMask,_tmpTimeTokens,_tmpResolvedTimes,_tmpStockCount,_tmpStockUpdatedAt,_tmpHighRisk,_tmpPaused,_tmpCreatedAt);
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
  public Object count(final Continuation<? super Integer> $completion) {
    final String _sql = "SELECT COUNT(*) FROM medicines";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
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
