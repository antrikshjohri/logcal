package com.serene.logcal.viewmodel.history

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class HistoryUiState(
    val isLoading: Boolean = true,
    val meals: List<HistoryMeal> = emptyList(),
    val errorMessage: String? = null,
)

class HistoryViewModel(application: Application) : AndroidViewModel(application) {
    private val localRepo = AppGraph.localMealRepository(application)
    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

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
                localRepo.deleteMeal(id)
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
                localRepo.deleteMeals(ids)
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
                localRepo.deleteAllMeals()
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
}

