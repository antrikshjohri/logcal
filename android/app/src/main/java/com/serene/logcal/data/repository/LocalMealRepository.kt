package com.serene.logcal.data.repository

import com.serene.logcal.data.local.MealDao
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
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
            rows.mapNotNull { row ->
                try {
                    val response = json.decodeFromString<MealLogResponse>(row.rawResponseJson)
                    HistoryMeal(
                        id = row.id,
                        timestampMillis = row.timestampMillis,
                        mealType = row.mealType,
                        totalCalories = row.totalCalories,
                        foodText = row.foodText,
                        response = response
                    )
                } catch (t: Throwable) {
                    DebugLogger.e("DEBUG: [LocalMealRepository] Failed to decode rawResponseJson for id=${row.id}", t)
                    null
                }
            }
        }
    }

    suspend fun saveMeal(
        timestampMillis: Long,
        foodText: String,
        mealType: String,
        response: MealLogResponse
    ) {
        val entity = MealEntryEntity(
            id = UUID.randomUUID().toString(),
            timestampMillis = timestampMillis,
            createdAtMillis = System.currentTimeMillis(),
            foodText = foodText,
            mealType = mealType,
            totalCalories = response.totalCalories,
            rawResponseJson = json.encodeToString(response),
        )
        DebugLogger.d("DEBUG: [LocalMealRepository] saveMeal() id=${entity.id} mealType=$mealType calories=${response.totalCalories}")
        mealDao.insertMeal(entity)
    }

    suspend fun deleteMeal(id: String) {
        DebugLogger.d("DEBUG: [LocalMealRepository] deleteMeal() id=$id")
        mealDao.deleteById(id)
    }
}

