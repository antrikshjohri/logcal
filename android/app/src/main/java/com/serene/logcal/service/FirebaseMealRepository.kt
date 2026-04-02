package com.serene.logcal.service

import com.google.firebase.functions.FirebaseFunctions
import com.google.gson.Gson
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.json.Json

class FirebaseMealRepository(
    private val functions: FirebaseFunctions = FirebaseFunctions.getInstance(),
    private val gson: Gson = Gson(),
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    suspend fun logMeal(
        foodText: String,
        mealType: MealType,
        imageBase64: String? = null,
        country: String? = null,
    ): Result<MealLogResponse> {
        val hasImage = !imageBase64.isNullOrBlank()
        DebugLogger.d(
            "DEBUG: [FirebaseMealRepository] logMeal() start foodTextLen=${foodText.length} mealType=${mealType.rawValue} hasImage=$hasImage imageBase64Len=${imageBase64?.length ?: 0}"
        )

        return try {
            val payload = hashMapOf<String, Any>(
                "foodText" to foodText,
                "mealType" to mealType.rawValue
            )
            if (hasImage) {
                payload["imageBase64"] = imageBase64!!
            }
            if (!country.isNullOrBlank()) {
                payload["country"] = country
            }

            val callable = functions.getHttpsCallable("logMeal")
            val response = callable.call(payload).await()

            // Firebase returns the payload as a structured object (Map/List). Convert via Gson -> JSON -> Kotlin models.
            val responseJson = gson.toJson(response.data)
            DebugLogger.d("DEBUG: [FirebaseMealRepository] logMeal() responseJson=${responseJson.take(500)}")

            val decoded = json.decodeFromString(MealLogResponse.serializer(), responseJson)
            Result.success(decoded)
        } catch (t: Throwable) {
            DebugLogger.e("DEBUG: [FirebaseMealRepository] logMeal() failed", t)
            Result.failure(t)
        }
    }
}

