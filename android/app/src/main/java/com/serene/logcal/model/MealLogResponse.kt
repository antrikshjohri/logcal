package com.serene.logcal.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class MealLogResponse(
    @SerialName("meal_type")
    val mealType: String,
    @SerialName("total_calories")
    val totalCalories: Double,
    val protein: Double? = null,
    val carbs: Double? = null,
    val fat: Double? = null,
    val fiber: Double? = null,
    val items: List<MealItem> = emptyList(),
    @SerialName("needs_clarification")
    val needsClarification: Boolean = false,
    @SerialName("clarifying_question")
    val clarifyingQuestion: String? = null,
    val sources: List<MealSource> = emptyList(),
)

@Serializable
data class MealSource(
    val title: String,
    val url: String,
) {
    val displayTitle: String
        get() {
            val trimmed = title.trim()
            if (trimmed.isNotEmpty() && trimmed != url) return trimmed
            return url
                .removePrefix("https://")
                .removePrefix("http://")
                .removePrefix("www.")
                .substringBefore("/")
                .ifBlank { "Source" }
        }
}

@Serializable
data class MealItem(
    val name: String,
    val quantity: String,
    val calories: Double,
    val protein: Double? = null,
    val carbs: Double? = null,
    val fat: Double? = null,
    val fiber: Double? = null,
    val assumptions: String? = null,
    val confidence: Double? = null,
)
