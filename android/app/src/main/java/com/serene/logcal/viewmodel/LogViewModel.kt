package com.serene.logcal.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.service.FirebaseMealRepository
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneId

data class LogUiState(
    val isAuthReady: Boolean = false,
    val isLoading: Boolean = false,
    val selectedDate: LocalDate = LocalDate.now(),
    val selectedMealType: MealType = MealType.BREAKFAST,
    val foodText: String = "",
    val latestResult: MealLogResponse? = null,
    val errorMessage: String? = null,
)

class LogViewModel(application: Application) : AndroidViewModel(application) {
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    private val repo: FirebaseMealRepository = FirebaseMealRepository()
    private val localRepo = AppGraph.localMealRepository(application)

    private val _uiState = MutableStateFlow(LogUiState())
    val uiState: StateFlow<LogUiState> = _uiState

    init {
        DebugLogger.d("DEBUG: [LogViewModel] init() start")
        ensureAnonymousAuth()
    }

    private fun ensureAnonymousAuth() {
        val currentUser = auth.currentUser
        if (currentUser != null) {
            DebugLogger.d("DEBUG: [LogViewModel] Anonymous user already exists uid=${currentUser.uid}")
            _uiState.value = _uiState.value.copy(isAuthReady = true)
            return
        }

        _uiState.value = _uiState.value.copy(isAuthReady = false)
        DebugLogger.d("DEBUG: [LogViewModel] Signing in anonymously...")
        auth.signInAnonymously()
            .addOnSuccessListener { result ->
                DebugLogger.d("DEBUG: [LogViewModel] Anonymous sign-in success uid=${result.user?.uid}")
                _uiState.value = _uiState.value.copy(isAuthReady = true, errorMessage = null)
            }
            .addOnFailureListener { e ->
                DebugLogger.e("DEBUG: [LogViewModel] Anonymous sign-in failed", e)
                _uiState.value = _uiState.value.copy(
                    isAuthReady = false,
                    errorMessage = "Authentication failed. Please try again."
                )
            }
    }

    fun onFoodTextChanged(newText: String) {
        _uiState.value = _uiState.value.copy(
            foodText = newText,
            latestResult = null
        )
    }

    fun setMealType(newMealType: MealType) {
        _uiState.value = _uiState.value.copy(selectedMealType = newMealType, latestResult = null)
    }

    fun setSelectedDate(newDate: LocalDate) {
        _uiState.value = _uiState.value.copy(selectedDate = newDate, latestResult = null)
    }

    fun logMeal() {
        val state = _uiState.value
        if (!state.isAuthReady) {
            _uiState.value = state.copy(errorMessage = "Not signed in yet.")
            return
        }

        val trimmed = state.foodText.trim()
        if (trimmed.isEmpty()) {
            _uiState.value = state.copy(errorMessage = "Please enter what you ate.")
            return
        }

        DebugLogger.d("DEBUG: [LogViewModel] logMeal() tapped date=${state.selectedDate} mealType=${state.selectedMealType.rawValue}")
        _uiState.value = state.copy(isLoading = true, errorMessage = null, latestResult = null)

        viewModelScope.launch {
            val result = repo.logMeal(trimmed, state.selectedMealType)
            result.fold(
                onSuccess = { response ->
                    DebugLogger.d("DEBUG: [LogViewModel] logMeal() success totalCalories=${response.totalCalories}")
                    viewModelScope.launch {
                        try {
                            val timestampMillis = state.selectedDate
                                .atStartOfDay(ZoneId.systemDefault())
                                .toInstant()
                                .toEpochMilli()
                            localRepo.saveMeal(
                                timestampMillis = timestampMillis,
                                foodText = trimmed,
                                mealType = response.mealType,
                                response = response
                            )
                            DebugLogger.d("DEBUG: [LogViewModel] Meal saved to local DB")
                        } catch (t: Throwable) {
                            DebugLogger.e("DEBUG: [LogViewModel] Failed to save meal to local DB", t)
                        }
                    }
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        latestResult = response,
                        errorMessage = null
                    )
                },
                onFailure = { t ->
                    DebugLogger.e("DEBUG: [LogViewModel] logMeal() failed", t)
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        latestResult = null,
                        errorMessage = "Failed to log meal. Please try again."
                    )
                }
            )
        }
    }
}

