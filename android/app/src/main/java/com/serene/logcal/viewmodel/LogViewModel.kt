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
import com.serene.logcal.util.MealImageEncoder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.ZoneId

data class LogUiState(
    val isAuthReady: Boolean = false,
    val isLoading: Boolean = false,
    val selectedDate: LocalDate = LocalDate.now(),
    val selectedMealType: MealType = MealType.BREAKFAST,
    val foodText: String = "",
    val attachedImageUri: String? = null,
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

    fun appendFoodText(recognizedText: String) {
        val incoming = recognizedText.trim()
        if (incoming.isEmpty()) {
            DebugLogger.w("DEBUG: [LogViewModel] appendFoodText skipped because recognized text is empty")
            return
        }
        val current = _uiState.value.foodText.trim()
        val next = if (current.isEmpty()) incoming else "$current $incoming"
        DebugLogger.d("DEBUG: [LogViewModel] appendFoodText appendedLength=${incoming.length} newTotalLength=${next.length}")
        _uiState.value = _uiState.value.copy(foodText = next, latestResult = null)
    }

    fun setAttachedImageUri(uri: String?) {
        DebugLogger.d("DEBUG: [LogViewModel] setAttachedImageUri uriPresent=${!uri.isNullOrBlank()}")
        _uiState.value = _uiState.value.copy(attachedImageUri = uri, latestResult = null)
    }

    fun clearAttachedImage() {
        DebugLogger.d("DEBUG: [LogViewModel] clearAttachedImage")
        _uiState.value = _uiState.value.copy(attachedImageUri = null, latestResult = null)
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
        val hasImage = !state.attachedImageUri.isNullOrBlank()
        if (trimmed.isEmpty() && !hasImage) {
            _uiState.value = state.copy(errorMessage = "Please enter what you ate or attach a photo.")
            return
        }

        DebugLogger.d("DEBUG: [LogViewModel] logMeal() tapped date=${state.selectedDate} mealType=${state.selectedMealType.rawValue} hasImage=$hasImage")
        _uiState.value = state.copy(isLoading = true, errorMessage = null, latestResult = null)

        viewModelScope.launch {
            val imageBase64: String? = if (hasImage) {
                withContext(Dispatchers.IO) {
                    MealImageEncoder.encodeUriToJpegBase64(getApplication(), state.attachedImageUri!!)
                }
            } else {
                null
            }
            if (hasImage && imageBase64.isNullOrBlank()) {
                DebugLogger.e("DEBUG: [LogViewModel] logMeal() image encode failed")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Could not read the photo. Please try again."
                )
                return@launch
            }

            val result = repo.logMeal(
                foodText = trimmed,
                mealType = state.selectedMealType,
                imageBase64 = imageBase64
            )
            result.fold(
                onSuccess = { response ->
                    DebugLogger.d("DEBUG: [LogViewModel] logMeal() success totalCalories=${response.totalCalories}")
                    val storedLabel = trimmed.ifBlank {
                        response.items.firstOrNull()?.name?.takeIf { it.isNotBlank() } ?: "Photo meal"
                    }
                    viewModelScope.launch {
                        try {
                            val timestampMillis = state.selectedDate
                                .atStartOfDay(ZoneId.systemDefault())
                                .toInstant()
                                .toEpochMilli()
                            localRepo.saveMeal(
                                timestampMillis = timestampMillis,
                                foodText = storedLabel,
                                mealType = response.mealType,
                                response = response,
                                hasImage = imageBase64 != null,
                            )
                            DebugLogger.d("DEBUG: [LogViewModel] Meal saved to local DB foodTextLen=${storedLabel.length}")
                        } catch (t: Throwable) {
                            DebugLogger.e("DEBUG: [LogViewModel] Failed to save meal to local DB", t)
                        }
                    }
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        latestResult = response,
                        errorMessage = null,
                        foodText = "",
                        attachedImageUri = null
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

