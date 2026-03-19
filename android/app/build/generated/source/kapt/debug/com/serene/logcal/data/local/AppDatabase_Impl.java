package com.serene.logcal.data.local;

import androidx.annotation.NonNull;
import androidx.room.InvalidationTracker;
import androidx.room.RoomOpenDelegate;
import androidx.room.migration.AutoMigrationSpec;
import androidx.room.migration.Migration;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.sqlite.SQLite;
import androidx.sqlite.SQLiteConnection;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation", "removal"})
public final class AppDatabase_Impl extends AppDatabase {
  private volatile MealDao _mealDao;

  @Override
  @NonNull
  protected RoomOpenDelegate createOpenDelegate() {
    final RoomOpenDelegate _openDelegate = new RoomOpenDelegate(1, "c3f739b7934fe1a566d076038b86da1d", "e776e613b14b612f62bc3599bee3dbb0") {
      @Override
      public void createAllTables(@NonNull final SQLiteConnection connection) {
        SQLite.execSQL(connection, "CREATE TABLE IF NOT EXISTS `meal_entries` (`id` TEXT NOT NULL, `timestampMillis` INTEGER NOT NULL, `createdAtMillis` INTEGER NOT NULL, `foodText` TEXT NOT NULL, `mealType` TEXT NOT NULL, `totalCalories` REAL NOT NULL, `rawResponseJson` TEXT NOT NULL, PRIMARY KEY(`id`))");
        SQLite.execSQL(connection, "CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        SQLite.execSQL(connection, "INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, 'c3f739b7934fe1a566d076038b86da1d')");
      }

      @Override
      public void dropAllTables(@NonNull final SQLiteConnection connection) {
        SQLite.execSQL(connection, "DROP TABLE IF EXISTS `meal_entries`");
      }

      @Override
      public void onCreate(@NonNull final SQLiteConnection connection) {
      }

      @Override
      public void onOpen(@NonNull final SQLiteConnection connection) {
        internalInitInvalidationTracker(connection);
      }

      @Override
      public void onPreMigrate(@NonNull final SQLiteConnection connection) {
        DBUtil.dropFtsSyncTriggers(connection);
      }

      @Override
      public void onPostMigrate(@NonNull final SQLiteConnection connection) {
      }

      @Override
      @NonNull
      public RoomOpenDelegate.ValidationResult onValidateSchema(
          @NonNull final SQLiteConnection connection) {
        final Map<String, TableInfo.Column> _columnsMealEntries = new HashMap<String, TableInfo.Column>(7);
        _columnsMealEntries.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("timestampMillis", new TableInfo.Column("timestampMillis", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("createdAtMillis", new TableInfo.Column("createdAtMillis", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("foodText", new TableInfo.Column("foodText", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("mealType", new TableInfo.Column("mealType", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("totalCalories", new TableInfo.Column("totalCalories", "REAL", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealEntries.put("rawResponseJson", new TableInfo.Column("rawResponseJson", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final Set<TableInfo.ForeignKey> _foreignKeysMealEntries = new HashSet<TableInfo.ForeignKey>(0);
        final Set<TableInfo.Index> _indicesMealEntries = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoMealEntries = new TableInfo("meal_entries", _columnsMealEntries, _foreignKeysMealEntries, _indicesMealEntries);
        final TableInfo _existingMealEntries = TableInfo.read(connection, "meal_entries");
        if (!_infoMealEntries.equals(_existingMealEntries)) {
          return new RoomOpenDelegate.ValidationResult(false, "meal_entries(com.serene.logcal.data.local.MealEntryEntity).\n"
                  + " Expected:\n" + _infoMealEntries + "\n"
                  + " Found:\n" + _existingMealEntries);
        }
        return new RoomOpenDelegate.ValidationResult(true, null);
      }
    };
    return _openDelegate;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final Map<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final Map<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "meal_entries");
  }

  @Override
  public void clearAllTables() {
    super.performClear(false, "meal_entries");
  }

  @Override
  @NonNull
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final Map<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(MealDao.class, MealDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  @NonNull
  public Set<Class<? extends AutoMigrationSpec>> getRequiredAutoMigrationSpecs() {
    final Set<Class<? extends AutoMigrationSpec>> _autoMigrationSpecsSet = new HashSet<Class<? extends AutoMigrationSpec>>();
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
  public MealDao mealDao() {
    if (_mealDao != null) {
      return _mealDao;
    } else {
      synchronized(this) {
        if(_mealDao == null) {
          _mealDao = new MealDao_Impl(this);
        }
        return _mealDao;
      }
    }
  }
}
