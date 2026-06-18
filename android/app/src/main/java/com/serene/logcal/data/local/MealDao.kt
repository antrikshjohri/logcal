package com.serene.logcal.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface MealDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMeal(meal: MealEntryEntity)

    @Query("SELECT * FROM meal_entries WHERE deleted = 0 ORDER BY timestampMillis DESC, createdAtMillis DESC")
    fun observeMeals(): Flow<List<MealEntryEntity>>

    @Query("SELECT * FROM meal_entries WHERE id = :id AND deleted = 0 LIMIT 1")
    suspend fun getById(id: String): MealEntryEntity?

    @Query(
        """
        SELECT EXISTS(
            SELECT 1 FROM meal_entries
            WHERE mealType = :mealType
            AND timestampMillis >= :startMillis
            AND timestampMillis < :endMillis
            AND deleted = 0
        )
        """
    )
    suspend fun hasMealTypeBetween(mealType: String, startMillis: Long, endMillis: Long): Boolean

    @Query("SELECT EXISTS(SELECT 1 FROM meal_entries WHERE createdAtMillis >= :cutoffMillis AND deleted = 0)")
    suspend fun hasMealCreatedSince(cutoffMillis: Long): Boolean

    @Query("UPDATE meal_entries SET sourceSavedMealId = :sourceSavedMealId WHERE id = :mealId")
    suspend fun updateSourceSavedMealId(mealId: String, sourceSavedMealId: String?)

    @Query("UPDATE meal_entries SET sourceSavedMealId = NULL WHERE sourceSavedMealId = :sourceSavedMealId")
    suspend fun clearSourceSavedMealId(sourceSavedMealId: String)

    @Query("UPDATE meal_entries SET deleted = 1 WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM meal_entries")
    suspend fun deleteAll()

    @Query("SELECT * FROM meal_entries")
    suspend fun getAllMeals(): List<MealEntryEntity>
}
