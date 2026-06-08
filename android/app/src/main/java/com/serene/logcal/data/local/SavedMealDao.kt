package com.serene.logcal.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SavedMealDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(meal: SavedMealEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(meals: List<SavedMealEntity>)

    @Query("SELECT * FROM saved_meals ORDER BY displayOrder ASC, title ASC")
    fun observeAll(): Flow<List<SavedMealEntity>>

    @Query("SELECT * FROM saved_meals ORDER BY displayOrder ASC, title ASC")
    suspend fun getAll(): List<SavedMealEntity>

    @Query("SELECT * FROM saved_meals WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): SavedMealEntity?

    @Query("DELETE FROM saved_meals WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM saved_meals")
    suspend fun deleteAll()
}
