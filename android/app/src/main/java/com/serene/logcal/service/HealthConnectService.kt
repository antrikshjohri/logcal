package com.serene.logcal.service

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.BasalMetabolicRateRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.MealType
import androidx.health.connect.client.records.NutritionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.Energy
import androidx.health.connect.client.units.Mass
import androidx.health.connect.client.units.Power
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

data class HealthWorkout(
    val id: String,
    val title: String,
    val durationMinutes: Int,
    val caloriesBurned: Double,
    val startTime: Instant,
)

class HealthConnectService private constructor(private val context: Context) {
    private val prefManager = AppGraph.preferenceManager(context)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    companion object {
        @Volatile
        private var instance: HealthConnectService? = null

        fun getInstance(context: Context): HealthConnectService {
            return instance ?: synchronized(this) {
                instance ?: HealthConnectService(context.applicationContext).also { instance = it }
            }
        }

        val PERMISSIONS = setOf(
            HealthPermission.getReadPermission(NutritionRecord::class),
            HealthPermission.getWritePermission(NutritionRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(BasalMetabolicRateRecord::class),
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        )
    }

    private val healthConnectClient: HealthConnectClient? by lazy {
        if (HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectClient.getOrCreate(context)
        } else {
            null
        }
    }

    private val _isAuthorized = MutableStateFlow(false)
    val isAuthorized: StateFlow<Boolean> = _isAuthorized.asStateFlow()

    fun isAvailable(): Boolean {
        return HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
    }

    suspend fun checkPermissions(): Boolean = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext false
        try {
            val granted = client.permissionController.getGrantedPermissions()
            val hasAll = granted.containsAll(PERMISSIONS)
            _isAuthorized.value = hasAll
            if (hasAll && !prefManager.isHealthConnectEnabled) {
                prefManager.isHealthConnectEnabled = true
            }
            hasAll
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error checking permissions", e)
            false
        }
    }

    /**
     * Saves or updates a meal entry as a NutritionRecord in Health Connect.
     */
    suspend fun saveMealEntry(meal: MealEntryEntity) = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext
        if (!prefManager.isHealthConnectEnabled) return@withContext

        try {
            val mealInstant = Instant.ofEpochMilli(meal.timestampMillis)
            val endInstant = mealInstant.plus(1, ChronoUnit.MINUTES)
            val zoneOffset = ZoneId.systemDefault().rules.getOffset(mealInstant)

            val healthMealType = when (meal.mealType.lowercase()) {
                "breakfast" -> MealType.MEAL_TYPE_BREAKFAST
                "lunch" -> MealType.MEAL_TYPE_LUNCH
                "dinner" -> MealType.MEAL_TYPE_DINNER
                else -> MealType.MEAL_TYPE_SNACK
            }

            val parsedResponse = try {
                json.decodeFromString<MealLogResponse>(meal.rawResponseJson)
            } catch (e: Exception) {
                null
            }

            val record = NutritionRecord(
                startTime = mealInstant,
                startZoneOffset = zoneOffset,
                endTime = endInstant,
                endZoneOffset = zoneOffset,
                metadata = Metadata(clientRecordId = meal.id),
                name = meal.foodText.take(100),
                mealType = healthMealType,
                energy = Energy.kilocalories(meal.totalCalories),
                protein = parsedResponse?.protein?.let { Mass.grams(it) },
                totalCarbohydrate = parsedResponse?.carbs?.let { Mass.grams(it) },
                totalFat = parsedResponse?.fat?.let { Mass.grams(it) },
                dietaryFiber = parsedResponse?.fiber?.let { Mass.grams(it) }
            )

            client.insertRecords(listOf(record))
            DebugLogger.d("HealthConnectService: Successfully saved NutritionRecord for ${meal.foodText}")
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error saving meal to Health Connect", e)
        }
    }

    /**
     * Deletes a meal from Health Connect by its clientRecordId.
     */
    suspend fun deleteMealEntry(mealId: String) = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext
        if (!prefManager.isHealthConnectEnabled) return@withContext

        try {
            client.deleteRecords(
                recordType = NutritionRecord::class,
                recordIdsList = emptyList(),
                clientRecordIdsList = listOf(mealId)
            )
            DebugLogger.d("HealthConnectService: Deleted record for $mealId")
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error deleting meal from Health Connect", e)
        }
    }

    /**
     * Reads active calories burned for a specific date.
     */
    suspend fun fetchActiveCalories(date: LocalDate): Double = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext 0.0
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant()

        try {
            val response = client.aggregate(
                AggregateRequest(
                    metrics = setOf(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(start, end)
                )
            )
            val energy = response[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]
            energy?.inKilocalories ?: 0.0
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error fetching active calories", e)
            0.0
        }
    }

    /**
     * Reads total steps for a specific date.
     */
    suspend fun fetchSteps(date: LocalDate): Long = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext 0L
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant()

        try {
            val response = client.aggregate(
                AggregateRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(start, end)
                )
            )
            response[StepsRecord.COUNT_TOTAL] ?: 0L
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error fetching steps", e)
            0L
        }
    }

    /**
     * Estimates 24-hour basal calories (BMR) for a date.
     */
    suspend fun fetchBasalCalories(date: LocalDate): Double = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext 1600.0
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant()

        try {
            val records = client.readRecords(
                ReadRecordsRequest(
                    recordType = BasalMetabolicRateRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(start, end)
                )
            )
            val latestRate = records.records.lastOrNull()
            if (latestRate != null) {
                latestRate.basalMetabolicRate.inKilocaloriesPerDay
            } else {
                1600.0 // Default healthy baseline
            }
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error fetching basal calories", e)
            1600.0
        }
    }

    /**
     * Reads workouts / exercise sessions for a date.
     */
    suspend fun fetchWorkouts(date: LocalDate): List<HealthWorkout> = withContext(Dispatchers.IO) {
        val client = healthConnectClient ?: return@withContext emptyList()
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant()

        try {
            val sessions = client.readRecords(
                ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(start, end)
                )
            )

            sessions.records.map { session ->
                val duration = ChronoUnit.MINUTES.between(session.startTime, session.endTime).toInt()
                HealthWorkout(
                    id = session.metadata.id,
                    title = session.title ?: "Workout",
                    durationMinutes = duration.coerceAtLeast(1),
                    caloriesBurned = (duration * 6.5), // Estimated active burn
                    startTime = session.startTime
                )
            }
        } catch (e: Exception) {
            DebugLogger.e("HealthConnectService: Error fetching workouts", e)
            emptyList()
        }
    }
}
