package com.serene.logcal.data.local;

import androidx.annotation.NonNull;
import androidx.room.EntityInsertAdapter;
import androidx.room.RoomDatabase;
import androidx.room.coroutines.FlowUtil;
import androidx.room.util.DBUtil;
import androidx.room.util.SQLiteStatementUtil;
import androidx.sqlite.SQLiteStatement;
import java.lang.Class;
import java.lang.NullPointerException;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation", "removal"})
public final class MealDao_Impl implements MealDao {
  private final RoomDatabase __db;

  private final EntityInsertAdapter<MealEntryEntity> __insertAdapterOfMealEntryEntity;

  public MealDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertAdapterOfMealEntryEntity = new EntityInsertAdapter<MealEntryEntity>() {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `meal_entries` (`id`,`timestampMillis`,`createdAtMillis`,`foodText`,`mealType`,`totalCalories`,`rawResponseJson`) VALUES (?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SQLiteStatement statement,
          @NonNull final MealEntryEntity entity) {
        if (entity.getId() == null) {
          statement.bindNull(1);
        } else {
          statement.bindText(1, entity.getId());
        }
        statement.bindLong(2, entity.getTimestampMillis());
        statement.bindLong(3, entity.getCreatedAtMillis());
        if (entity.getFoodText() == null) {
          statement.bindNull(4);
        } else {
          statement.bindText(4, entity.getFoodText());
        }
        if (entity.getMealType() == null) {
          statement.bindNull(5);
        } else {
          statement.bindText(5, entity.getMealType());
        }
        statement.bindDouble(6, entity.getTotalCalories());
        if (entity.getRawResponseJson() == null) {
          statement.bindNull(7);
        } else {
          statement.bindText(7, entity.getRawResponseJson());
        }
      }
    };
  }

  @Override
  public Object insertMeal(final MealEntryEntity meal,
      final Continuation<? super Unit> $completion) {
    if (meal == null) throw new NullPointerException();
    return DBUtil.performSuspending(__db, false, true, (_connection) -> {
      __insertAdapterOfMealEntryEntity.insert(_connection, meal);
      return Unit.INSTANCE;
    }, $completion);
  }

  @Override
  public Flow<List<MealEntryEntity>> observeMeals() {
    final String _sql = "SELECT * FROM meal_entries ORDER BY timestampMillis DESC, createdAtMillis DESC";
    return FlowUtil.createFlow(__db, false, new String[] {"meal_entries"}, (_connection) -> {
      final SQLiteStatement _stmt = _connection.prepare(_sql);
      try {
        final int _columnIndexOfId = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "id");
        final int _columnIndexOfTimestampMillis = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "timestampMillis");
        final int _columnIndexOfCreatedAtMillis = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "createdAtMillis");
        final int _columnIndexOfFoodText = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "foodText");
        final int _columnIndexOfMealType = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "mealType");
        final int _columnIndexOfTotalCalories = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "totalCalories");
        final int _columnIndexOfRawResponseJson = SQLiteStatementUtil.getColumnIndexOrThrow(_stmt, "rawResponseJson");
        final List<MealEntryEntity> _result = new ArrayList<MealEntryEntity>();
        while (_stmt.step()) {
          final MealEntryEntity _item;
          final String _tmpId;
          if (_stmt.isNull(_columnIndexOfId)) {
            _tmpId = null;
          } else {
            _tmpId = _stmt.getText(_columnIndexOfId);
          }
          final long _tmpTimestampMillis;
          _tmpTimestampMillis = _stmt.getLong(_columnIndexOfTimestampMillis);
          final long _tmpCreatedAtMillis;
          _tmpCreatedAtMillis = _stmt.getLong(_columnIndexOfCreatedAtMillis);
          final String _tmpFoodText;
          if (_stmt.isNull(_columnIndexOfFoodText)) {
            _tmpFoodText = null;
          } else {
            _tmpFoodText = _stmt.getText(_columnIndexOfFoodText);
          }
          final String _tmpMealType;
          if (_stmt.isNull(_columnIndexOfMealType)) {
            _tmpMealType = null;
          } else {
            _tmpMealType = _stmt.getText(_columnIndexOfMealType);
          }
          final double _tmpTotalCalories;
          _tmpTotalCalories = _stmt.getDouble(_columnIndexOfTotalCalories);
          final String _tmpRawResponseJson;
          if (_stmt.isNull(_columnIndexOfRawResponseJson)) {
            _tmpRawResponseJson = null;
          } else {
            _tmpRawResponseJson = _stmt.getText(_columnIndexOfRawResponseJson);
          }
          _item = new MealEntryEntity(_tmpId,_tmpTimestampMillis,_tmpCreatedAtMillis,_tmpFoodText,_tmpMealType,_tmpTotalCalories,_tmpRawResponseJson);
          _result.add(_item);
        }
        return _result;
      } finally {
        _stmt.close();
      }
    });
  }

  @Override
  public Object deleteById(final String id, final Continuation<? super Unit> $completion) {
    final String _sql = "DELETE FROM meal_entries WHERE id = ?";
    return DBUtil.performSuspending(__db, false, true, (_connection) -> {
      final SQLiteStatement _stmt = _connection.prepare(_sql);
      try {
        int _argIndex = 1;
        if (id == null) {
          _stmt.bindNull(_argIndex);
        } else {
          _stmt.bindText(_argIndex, id);
        }
        _stmt.step();
        return Unit.INSTANCE;
      } finally {
        _stmt.close();
      }
    }, $completion);
  }

  @Override
  public Object deleteAll(final Continuation<? super Unit> $completion) {
    final String _sql = "DELETE FROM meal_entries";
    return DBUtil.performSuspending(__db, false, true, (_connection) -> {
      final SQLiteStatement _stmt = _connection.prepare(_sql);
      try {
        _stmt.step();
        return Unit.INSTANCE;
      } finally {
        _stmt.close();
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
