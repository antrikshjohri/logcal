package com.serene.logcal.model

data class CompletedMealPreview(
    val id: String,
    val response: MealLogResponse,
    val foodText: String,
    val isRefining: Boolean = false,
    val refineError: String? = null
)
