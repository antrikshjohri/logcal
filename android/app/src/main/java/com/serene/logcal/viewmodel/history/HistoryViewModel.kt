package com.serene.logcal.viewmodel.history

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.data.local.PreferenceManager
import com.serene.logcal.model.MealLogResponse
import kotlinx.serialization.json.Json
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.CloudSyncService
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID

data class HistoryUiState(
    val isLoading: Boolean = true,
    val meals: List<HistoryMeal> = emptyList(),
    val errorMessage: String? = null,
)

class HistoryViewModel(application: Application) : AndroidViewModel(application) {
    private val localRepo = AppGraph.localMealRepository(application)
    private val favRepo = AppGraph.localSavedMealsRepository(application)
    private val syncService = AppGraph.cloudSyncService(application)
    private val gson = Gson()
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    val isRefreshing: StateFlow<Boolean> = syncService.isSyncing

    fun refreshData() {
        viewModelScope.launch {
            syncService.syncFromCloud()
        }
    }

    init {
        DebugLogger.d("DEBUG: [HistoryViewModel] init()")
        observeHistory()
    }

    private fun observeHistory() {
        viewModelScope.launch {
            localRepo.observeHistoryMeals().collect { meals ->
                DebugLogger.d("DEBUG: [HistoryViewModel] observeHistory() meals=${meals.size}")
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        meals = meals,
                        errorMessage = null
                    )
                }
            }
        }
    }

    fun deleteMeal(id: String) {
        viewModelScope.launch {
            try {
                // Trigger cloud delete
                syncService.deleteMealFromCloud(id)
                // Delete locally
                localRepo.deleteMeal(id)
                AnalyticsService.trackMealDeleted()
            } catch (t: Throwable) {
                DebugLogger.e("DEBUG: [HistoryViewModel] deleteMeal() failed id=$id", t)
                _uiState.update { it.copy(errorMessage = "Failed to delete meal") }
            }
        }
    }

    fun deleteMeals(ids: List<String>) {
        if (ids.isEmpty()) return
        viewModelScope.launch {
            try {
                DebugLogger.d("DEBUG: [HistoryViewModel] deleteMeals() count=${ids.size}")
                for (id in ids) {
                    syncService.deleteMealFromCloud(id)
                }
                localRepo.deleteMeals(ids)
                AnalyticsService.trackMealDeleted()
            } catch (t: Throwable) {
                DebugLogger.e("DEBUG: [HistoryViewModel] deleteMeals() failed", t)
                _uiState.update { it.copy(errorMessage = "Failed to delete meals") }
            }
        }
    }

    fun deleteAllMeals() {
        viewModelScope.launch {
            try {
                DebugLogger.d("DEBUG: [HistoryViewModel] deleteAllMeals()")
                val currentMeals = _uiState.value.meals
                for (meal in currentMeals) {
                    syncService.deleteMealFromCloud(meal.id)
                }
                localRepo.deleteAllMeals()
                AnalyticsService.trackMealDeleted()
            } catch (t: Throwable) {
                DebugLogger.e("DEBUG: [HistoryViewModel] deleteAllMeals() failed", t)
                _uiState.update { it.copy(errorMessage = "Failed to clear history") }
            }
        }
    }

    suspend fun getMealById(id: String): HistoryMeal? {
        DebugLogger.d("DEBUG: [HistoryViewModel] getMealById() id=$id")
        return localRepo.getMealById(id)
    }

    fun updateMeal(
        mealId: String,
        timestampMillis: Long,
        mealType: String,
        totalCalories: Double,
        rawResponseJson: String
    ) {
        viewModelScope.launch {
            try {
                val existing = localRepo.getMealById(mealId)
                if (existing != null) {
                    val updated = MealEntryEntity(
                        id = mealId,
                        timestampMillis = timestampMillis,
                        createdAtMillis = existing.createdAtMillis,
                        foodText = existing.foodText,
                        mealType = mealType,
                        totalCalories = totalCalories,
                        rawResponseJson = rawResponseJson,
                        hasImage = existing.hasImage,
                        sourceSavedMealId = existing.sourceSavedMealId
                    )
                    localRepo.updateMeal(updated)
                    syncService.syncMealToCloud(updated)

                    // Also check if there's a linked favorite that needs updating
                    val favorites = favRepo.getAll()
                    val linked = favorites.find { it.sourceMealId == mealId }
                    if (linked != null) {
                        val updatedFav = linked.copy(
                            mealType = mealType,
                            totalCalories = totalCalories,
                            rawResponseJson = rawResponseJson,
                            updatedAtMillis = System.currentTimeMillis()
                        )
                        favRepo.save(updatedFav)
                        syncService.syncSavedMealsToCloud()
                    }
                    AnalyticsService.trackMealEdited()
                }
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [HistoryViewModel] updateMeal failed", e)
            }
        }
    }

    suspend fun getLinkedFavorite(mealId: String): SavedMealEntity? {
        val meal = localRepo.getMealById(mealId)
        if (meal?.sourceSavedMealId != null) {
            favRepo.getById(meal.sourceSavedMealId)?.let { return it }
        }
        val favorites = favRepo.getAll()
        return favorites.find { it.sourceMealId == mealId }
    }

    fun saveMealAsFavorite(mealId: String, suggestedTitle: String) {
        viewModelScope.launch {
            try {
                val meal = localRepo.getMealById(mealId) ?: return@launch
                val savedMeal = SavedMealEntity(
                    id = UUID.randomUUID().toString(),
                    title = suggestedTitle,
                    foodText = meal.foodText,
                    mealType = meal.mealType,
                    totalCalories = meal.totalCalories,
                    rawResponseJson = json.encodeToString(MealLogResponse.serializer(), meal.response),
                    sourceMealId = meal.id,
                    displayOrder = favRepo.getAll().size
                )
                favRepo.save(savedMeal)
                localRepo.updateSourceSavedMealId(mealId, savedMeal.id)
                syncService.syncSavedMealsToCloud()
                localRepo.getMealEntryById(mealId)?.let { syncService.syncMealToCloud(it) }
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [HistoryViewModel] saveMealAsFavorite failed", e)
            }
        }
    }

    fun deleteFavoriteMeal(id: String) {
        viewModelScope.launch {
            try {
                localRepo.clearSourceSavedMealId(id)
                favRepo.delete(id)
                syncService.syncSavedMealsToCloud()
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [HistoryViewModel] deleteFavoriteMeal failed", e)
            }
        }
    }
}
