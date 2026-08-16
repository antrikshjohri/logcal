package com.serene.logcal.model

import android.net.Uri
import java.time.LocalDate

sealed class PendingLogStatus {
    object Processing : PendingLogStatus()
    data class Completed(val response: MealLogResponse, val entryId: String) : PendingLogStatus()
    data class Failed(val error: String) : PendingLogStatus()
}

data class PendingMealLog(
    val id: String,
    val foodText: String,
    val imageUris: List<Uri>,
    val mealType: MealType,
    val date: LocalDate,
    val createdAtMillis: Long = System.currentTimeMillis(),
    val isPreviewOnly: Boolean = false,
    val status: PendingLogStatus = PendingLogStatus.Processing,
) {
    val displayText: String
        get() {
            val trimmed = foodText.trim()
            if (trimmed.isNotEmpty()) return trimmed
            if (imageUris.isNotEmpty()) return "Photo meal"
            return "${mealType.rawValue.replaceFirstChar { it.uppercase() }} log"
        }
}
