package com.serene.logcal.model

import kotlin.math.round

enum class DietStyle(val rawValue: String) {
    BALANCED("Balanced"),
    HIGH_PROTEIN("High Protein"),
    LOW_CARB("Low Carb"),
    KETO("Ketogenic"),
    CUSTOM("Custom");

    companion object {
        fun fromRawValue(value: String): DietStyle {
            return entries.find { it.rawValue == value } ?: BALANCED
        }

        fun calculateGrams(calories: Double, proteinPercent: Double, carbsPercent: Double, fatPercent: Double): Triple<Double, Double, Double> {
            val pGrams = (calories * proteinPercent) / 4.0
            val cGrams = (calories * carbsPercent) / 4.0
            val fGrams = (calories * fatPercent) / 9.0
            return Triple(round(pGrams), round(cGrams), round(fGrams))
        }
    }

    val macroPercentages: Triple<Double, Double, Double>
        get() = when (this) {
            BALANCED -> Triple(0.30, 0.40, 0.30)
            HIGH_PROTEIN -> Triple(0.40, 0.30, 0.30)
            LOW_CARB -> Triple(0.25, 0.15, 0.60)
            KETO -> Triple(0.20, 0.05, 0.75)
            CUSTOM -> Triple(0.30, 0.40, 0.30)
        }
}
