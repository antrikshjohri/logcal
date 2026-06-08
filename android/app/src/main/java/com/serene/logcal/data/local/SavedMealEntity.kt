package com.serene.logcal.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "saved_meals")
data class SavedMealEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val foodText: String,
    val mealType: String,
    val totalCalories: Double,
    val rawResponseJson: String,
    val sourceMealId: String? = null,
    val displayOrder: Int = 0,
    val createdAtMillis: Long = System.currentTimeMillis(),
    val updatedAtMillis: Long = System.currentTimeMillis(),
)
