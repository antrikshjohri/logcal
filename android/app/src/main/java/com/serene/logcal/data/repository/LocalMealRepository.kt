package com.serene.logcal.data.repository

import com.serene.logcal.data.local.MealDao
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class LocalMealRepository(
    private val mealDao: MealDao
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    fun observeHistoryMeals(): Flow<List<HistoryMeal>> {
        return mealDao.observeMeals().map { rows ->
            rows.mapNotNull { row -> entityToHistoryMeal(row) }
        }
    }

    private fun entityToHistoryMeal(row: MealEntryEntity): HistoryMeal? {
        return try {
            val response = json.decodeFromString<MealLogResponse>(row.rawResponseJson)
            HistoryMeal(
                id = row.id,
                timestampMillis = row.timestampMillis,
                createdAtMillis = row.createdAtMillis,
                mealType = row.mealType,
                totalCalories = row.totalCalories,
                foodText = row.foodText,
                response = response,
                hasImage = row.hasImage,
            )
        } catch (t: Throwable) {
            DebugLogger.e("DEBUG: [LocalMealRepository] Failed to decode rawResponseJson for id=${row.id}", t)
            null
        }
    }

    suspend fun getMealById(id: String): HistoryMeal? = withContext(Dispatchers.IO) {
        val row = mealDao.getById(id) ?: return@withContext null
        val meal = entityToHistoryMeal(row)
        DebugLogger.d("DEBUG: [LocalMealRepository] getMealById() id=$id found=${meal != null}")
        meal
    }

    suspend fun getMealEntryById(id: String): MealEntryEntity? = withContext(Dispatchers.IO) {
        mealDao.getById(id)
    }

    suspend fun saveMeal(
        timestampMillis: Long,
        foodText: String,
        mealType: String,
        response: MealLogResponse,
        hasImage: Boolean = false,
        id: String? = null
    ) = withContext(Dispatchers.IO) {
        val entity = MealEntryEntity(
            id = id ?: UUID.randomUUID().toString(),
            timestampMillis = timestampMillis,
            createdAtMillis = System.currentTimeMillis(),
            foodText = foodText,
            mealType = mealType,
            totalCalories = response.totalCalories,
            rawResponseJson = json.encodeToString(response),
            hasImage = hasImage,
        )
        DebugLogger.d(
            "DEBUG: [LocalMealRepository] saveMeal() id=${entity.id} mealType=$mealType calories=${response.totalCalories} hasImage=$hasImage"
        )
        mealDao.insertMeal(entity)
    }

    suspend fun updateMeal(meal: MealEntryEntity) = withContext(Dispatchers.IO) {
        DebugLogger.d("DEBUG: [LocalMealRepository] updateMeal() id=${meal.id}")
        mealDao.insertMeal(meal) // insert with REPLACE strategy is effectively an update
    }

    suspend fun deleteMeal(id: String) {
        DebugLogger.d("DEBUG: [LocalMealRepository] deleteMeal() id=$id")
        mealDao.deleteById(id)
    }

    suspend fun deleteMeals(ids: List<String>) {
        DebugLogger.d("DEBUG: [LocalMealRepository] deleteMeals() count=${ids.size}")
        ids.forEach { mealDao.deleteById(it) }
    }

    suspend fun deleteAllMeals() {
        DebugLogger.d("DEBUG: [LocalMealRepository] deleteAllMeals()")
        mealDao.deleteAll()
    }

    suspend fun insertMeals(meals: List<MealEntryEntity>) = withContext(Dispatchers.IO) {
        DebugLogger.d("DEBUG: [LocalMealRepository] insertMeals() count=${meals.size}")
        meals.forEach { mealDao.insertMeal(it) }
    }
}
