package com.serene.logcal.service

import com.google.firebase.functions.FirebaseFunctions
import com.google.gson.Gson
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.json.Json

class FirebaseMealRepository(
    private val functions: FirebaseFunctions = FirebaseFunctions.getInstance("asia-southeast1"),
    private val gson: Gson = Gson(),
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    suspend fun logMeal(
        foodText: String,
        mealType: MealType,
        imageBase64s: List<String> = emptyList(),
        country: String? = null,
    ): Result<MealLogResponse> {
        val hasImages = imageBase64s.isNotEmpty()
        DebugLogger.d(
            "DEBUG: [FirebaseMealRepository] logMeal() start foodTextLen=${foodText.length} mealType=${mealType.rawValue} hasImages=$hasImages imageCount=${imageBase64s.size}"
        )

        return try {
            val payload = hashMapOf<String, Any>(
                "foodText" to foodText,
                "mealType" to mealType.rawValue
            )
            if (hasImages) {
                payload["imageBase64s"] = imageBase64s
                payload["imageBase64"] = imageBase64s.first()
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

    suspend fun refineMealLog(
        foodText: String,
        mealType: MealType,
        previousEstimate: MealLogResponse,
        correctionPrompt: String,
        country: String? = null
    ): Result<MealLogResponse> {
        DebugLogger.d(
            "DEBUG: [FirebaseMealRepository] refineMealLog() start foodTextLen=${foodText.length} mealType=${mealType.rawValue} correctionPromptLen=${correctionPrompt.length}"
        )
        return try {
            val prevJson = gson.toJson(previousEstimate)
            val prevMap = gson.fromJson(prevJson, Map::class.java)

            val payload = hashMapOf<String, Any>(
                "foodText" to foodText,
                "mealType" to mealType.rawValue,
                "correctionPrompt" to correctionPrompt,
                "previousEstimate" to prevMap
            )
            if (!country.isNullOrBlank()) {
                payload["country"] = country
            }

            val callable = functions.getHttpsCallable("refineMealLog")
            val response = callable.call(payload).await()

            val responseJson = gson.toJson(response.data)
            DebugLogger.d("DEBUG: [FirebaseMealRepository] refineMealLog() responseJson=${responseJson.take(500)}")

            val decoded = json.decodeFromString(MealLogResponse.serializer(), responseJson)
            Result.success(decoded)
        } catch (t: Throwable) {
            DebugLogger.e("DEBUG: [FirebaseMealRepository] refineMealLog() failed", t)
            Result.failure(t)
        }
    }
}

