package com.serene.logcal.service

import android.content.Context
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class CloudSyncService(private val context: Context) {
    private val firestoreService = FirestoreService()
    private val auth = FirebaseAuth.getInstance()
    private val localRepo = AppGraph.localMealRepository(context)
    private val favRepo = AppGraph.localSavedMealsRepository(context)
    private val prefManager = AppGraph.preferenceManager(context)
    private val json = Json { ignoreUnknownKeys = true }

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _syncError = MutableStateFlow<String?>(null)
    val syncError: StateFlow<String?> = _syncError.asStateFlow()

    private val _lastSyncTimeMillis = MutableStateFlow(0L)
    val lastSyncTimeMillis: StateFlow<Long> = _lastSyncTimeMillis.asStateFlow()

    suspend fun syncMealToCloud(entry: MealEntryEntity) {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) {
            DebugLogger.d("DEBUG: [CloudSyncService] User is anonymous or not signed in, skipping syncMealToCloud")
            return
        }
        try {
            firestoreService.saveMealEntry(entry)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error syncing meal to cloud", e)
            _syncError.value = "Failed to sync meal: ${e.localizedMessage}"
        }
    }

    suspend fun syncFromCloud() {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) {
            DebugLogger.d("DEBUG: [CloudSyncService] User is anonymous or not signed in, skipping syncFromCloud")
            return
        }

        val newUserId = user.uid
        val lastSyncedUserId = prefManager.lastSyncedUserId

        // Clear local meals if account changed
        if (lastSyncedUserId != null && lastSyncedUserId != newUserId) {
            DebugLogger.d("DEBUG: [CloudSyncService] User changed, clearing local data...")
            clearLocalMeals()
        }

        prefManager.lastSyncedUserId = newUserId

        // Guard against duplicate concurrent syncs
        if (_isSyncing.value) {
            DebugLogger.d("DEBUG: [CloudSyncService] Already syncing, skipping duplicate sync request.")
            return
        }

        _isSyncing.value = true
        _syncError.value = null

        try {
            // 1. Sync meals
            val cloudMeals = firestoreService.fetchMealEntries()
            val localMeals = localRepo.observeHistoryMeals().first()
            val localMealIds = localMeals.map { it.id }.toSet()

            val toAdd = mutableListOf<MealEntryEntity>()
            for (cloudMeal in cloudMeals) {
                if (cloudMeal.id !in localMealIds) {
                    toAdd.add(cloudMeal)
                }
            }

            if (toAdd.isNotEmpty()) {
                localRepo.insertMeals(toAdd)
                DebugLogger.d("DEBUG: [CloudSyncService] Merged ${toAdd.size} meals from cloud to local Room DB")
            }

            // 2. Sync favorites
            val cloudFavs = firestoreService.fetchSavedMealsFromCloud()
            val localFavs = favRepo.getAll()
            val localFavIds = localFavs.map { it.id }.toSet()

            val favsToAdd = mutableListOf<SavedMealEntity>()
            for (cloudFav in cloudFavs) {
                if (cloudFav.id !in localFavIds) {
                    favsToAdd.add(cloudFav)
                } else {
                    val local = localFavs.find { it.id == cloudFav.id }
                    if (local != null && (local.title != cloudFav.title || local.displayOrder != cloudFav.displayOrder)) {
                        favRepo.save(cloudFav) // overwrite
                    }
                }
            }

            if (favsToAdd.isNotEmpty()) {
                favRepo.saveAll(favsToAdd)
                DebugLogger.d("DEBUG: [CloudSyncService] Merged ${favsToAdd.size} favorites from cloud to local Room DB")
            }

            _lastSyncTimeMillis.value = System.currentTimeMillis()
            _isSyncing.value = false
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error syncing from cloud", e)
            _syncError.value = "Failed to sync from cloud: ${e.localizedMessage}"
            _isSyncing.value = false
        }
    }

    suspend fun migrateLocalToCloud() {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) {
            DebugLogger.d("DEBUG: [CloudSyncService] User is anonymous, skipping migration")
            return
        }

        _isSyncing.value = true
        _syncError.value = null

        try {
            // Migrate meals
            val localMeals = localRepo.observeHistoryMeals().first()
            if (localMeals.isNotEmpty()) {
                val entities = localMeals.map { meal ->
                    MealEntryEntity(
                        id = meal.id,
                        timestampMillis = meal.timestampMillis,
                        createdAtMillis = meal.createdAtMillis,
                        foodText = meal.foodText,
                        mealType = meal.mealType,
                        totalCalories = meal.totalCalories,
                        rawResponseJson = json.encodeToString(com.serene.logcal.model.MealLogResponse.serializer(), meal.response),
                        hasImage = meal.hasImage
                    )
                }
                firestoreService.syncLocalMealsToCloud(entities)
            }

            // Migrate preferences
            val dailyGoal = prefManager.dailyGoal
            val protein = prefManager.proteinGoal
            val carbs = prefManager.carbsGoal
            val fat = prefManager.fatGoal
            val style = prefManager.dietStyle
            if (dailyGoal > 0) {
                firestoreService.saveDailyGoal(dailyGoal, protein, carbs, fat, style)
            }

            // Migrate favorites
            val localFavs = favRepo.getAll()
            if (localFavs.isNotEmpty()) {
                firestoreService.saveSavedMealsToCloud(localFavs)
            }

            _isSyncing.value = false
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error migrating local data to cloud", e)
            _syncError.value = "Failed to migrate data: ${e.localizedMessage}"
            _isSyncing.value = false
        }
    }

    suspend fun deleteMealFromCloud(id: String) {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) return
        try {
            firestoreService.deleteMealEntry(id)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error deleting meal from cloud", e)
            _syncError.value = "Failed to delete from cloud: ${e.localizedMessage}"
        }
    }

    suspend fun clearLocalMeals() = withContext(Dispatchers.IO) {
        localRepo.deleteAllMeals()
        favRepo.deleteAll()
        prefManager.lastSyncedUserId = null
    }

    suspend fun initializeAnonymousSession() {
        prefManager.lastSyncedUserId = null
        DebugLogger.d("DEBUG: [CloudSyncService] Anonymous session initialized")
    }

    suspend fun syncDailyGoalToCloud(goal: Double) {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) return
        try {
            firestoreService.saveDailyGoal(goal)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error syncing daily goal", e)
        }
    }

    suspend fun syncUserPreferencesToCloud(
        dailyGoal: Double,
        proteinGoal: Double,
        carbsGoal: Double,
        fatGoal: Double,
        dietStyle: String
    ) {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) return
        try {
            firestoreService.saveDailyGoal(dailyGoal, proteinGoal, carbsGoal, fatGoal, dietStyle)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error syncing preferences", e)
        }
    }

    suspend fun syncSavedMealsToCloud() {
        val user = auth.currentUser
        if (user == null || user.isAnonymous) return
        try {
            val localFavs = favRepo.getAll()
            firestoreService.saveSavedMealsToCloud(localFavs)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [CloudSyncService] Error syncing saved meals to cloud", e)
        }
    }
}
