package com.serene.logcal.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.serene.logcal.model.MealLogResponse

@Entity(tableName = "meal_entries")
data class MealEntryEntity(
    @PrimaryKey
    val id: String,
    val timestampMillis: Long,
    val createdAtMillis: Long,
    val foodText: String,
    val mealType: String,
    val totalCalories: Double,
    val rawResponseJson: String,
)

data class HistoryMeal(
    val id: String,
    val timestampMillis: Long,
    val mealType: String,
    val totalCalories: Double,
    val foodText: String,
    val response: MealLogResponse,
)

