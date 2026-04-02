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

    @Query("SELECT * FROM meal_entries ORDER BY timestampMillis DESC, createdAtMillis DESC")
    fun observeMeals(): Flow<List<MealEntryEntity>>

    @Query("SELECT * FROM meal_entries WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): MealEntryEntity?

    @Query("DELETE FROM meal_entries WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM meal_entries")
    suspend fun deleteAll()
}

