package com.serene.logcal.viewmodel

import android.app.Application
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.google.gson.Gson
import com.serene.logcal.data.local.SavedMealEntity
import kotlinx.serialization.json.Json
import com.serene.logcal.data.local.PreferenceManager
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.service.FirebaseMealRepository
import com.serene.logcal.service.CloudSyncService
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.util.MealImageEncoder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import java.util.UUID

enum class SpeechTarget {
    MAIN, QUICK_EDIT
}

data class LogUiState(
    val isAuthReady: Boolean = false,
    val isLoading: Boolean = false,
    val isRefiningMeal: Boolean = false,
    val selectedDate: LocalDate = LocalDate.now(),
    val selectedMealType: MealType = MealType.BREAKFAST,
    val isMealTypeManuallySet: Boolean = false,
    val foodText: String = "",
    val quickEditFoodText: String = "",
    val attachedImageUris: List<String> = emptyList(),
    val latestResult: MealLogResponse? = null,
    val lastLoggedMealId: String? = null,
    val sourceSavedMealId: String? = null,
    val errorMessage: String? = null,
    val isListening: Boolean = false,
    val isTranscribingSpeech: Boolean = false,
    val speechErrorMessage: String? = null,
    val speechTarget: SpeechTarget = SpeechTarget.MAIN,
    val waveformSamples: List<Float> = List(64) { 0.08f }
)

class LogViewModel(application: Application) : AndroidViewModel(application) {
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    private val repo: FirebaseMealRepository = FirebaseMealRepository()
    private val localRepo = AppGraph.localMealRepository(application)
    private val favRepo = AppGraph.localSavedMealsRepository(application)
    private val syncService = AppGraph.cloudSyncService(application)
    private val reminderService = AppGraph.mealReminderService(application)
    private val prefManager = AppGraph.preferenceManager(application)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private val _uiState = MutableStateFlow(LogUiState())
    val uiState: StateFlow<LogUiState> = _uiState

    // Observe saved meals from local db for favorites carousel
    val savedMeals: StateFlow<List<SavedMealEntity>> = favRepo.observeAll()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    private var speechRecognizer: SpeechRecognizer? = null

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

    fun refreshAuth() {
        ensureAnonymousAuth()
    }

    fun onFoodTextChanged(newText: String) {
        _uiState.value = _uiState.value.copy(
            foodText = newText,
            latestResult = null,
            sourceSavedMealId = null
        )
        if (!_uiState.value.isMealTypeManuallySet) {
            updateInferredMealType(newText)
        }
    }

    private fun updateInferredMealType(text: String) {
        val lowercase = text.lowercase()
        val inferred = when {
            lowercase.contains("egg") || lowercase.contains("toast") || lowercase.contains("oat") || lowercase.contains("pancake") || lowercase.contains("breakfast") -> MealType.BREAKFAST
            lowercase.contains("sandwich") || lowercase.contains("salad") || lowercase.contains("soup") || lowercase.contains("lunch") -> MealType.LUNCH
            lowercase.contains("dinner") || lowercase.contains("steak") || lowercase.contains("salmon") || lowercase.contains("chicken") || lowercase.contains("roti") || lowercase.contains("rice") -> MealType.DINNER
            else -> MealType.SNACK
        }
        if (inferred != _uiState.value.selectedMealType) {
            _uiState.value = _uiState.value.copy(selectedMealType = inferred)
        }
    }

    fun appendFoodText(recognizedText: String) {
        val incoming = recognizedText.trim()
        if (incoming.isEmpty()) {
            return
        }
        val current = _uiState.value.foodText.trim()
        val next = if (current.isEmpty()) incoming else "$current $incoming"
        _uiState.value = _uiState.value.copy(foodText = next, latestResult = null, sourceSavedMealId = null)
        if (!_uiState.value.isMealTypeManuallySet) {
            updateInferredMealType(next)
        }
    }

    fun addAttachedImageUri(uri: String) {
        val current = _uiState.value.attachedImageUris
        if (current.size < 3) {
            _uiState.value = _uiState.value.copy(
                attachedImageUris = current + uri,
                latestResult = null,
                sourceSavedMealId = null
            )
            AnalyticsService.trackImageSelected()
        }
    }

    fun removeAttachedImageUri(uri: String) {
        _uiState.value = _uiState.value.copy(
            attachedImageUris = _uiState.value.attachedImageUris.filter { it != uri },
            latestResult = null,
            sourceSavedMealId = null
        )
        AnalyticsService.trackImageRemoved()
    }

    fun clearAttachedImages() {
        _uiState.value = _uiState.value.copy(
            attachedImageUris = emptyList(),
            latestResult = null,
            sourceSavedMealId = null
        )
    }

    fun setMealType(newMealType: MealType, isManual: Boolean = true) {
        _uiState.value = _uiState.value.copy(
            selectedMealType = newMealType,
            isMealTypeManuallySet = isManual,
            latestResult = null,
            sourceSavedMealId = null
        )
        if (isManual) {
            AnalyticsService.trackMealTypeChanged(newMealType.rawValue)
        }
    }

    fun setSelectedDate(newDate: LocalDate) {
        _uiState.value = _uiState.value.copy(
            selectedDate = newDate,
            latestResult = null,
            sourceSavedMealId = null
        )
    }

    fun applyNotificationTarget(mealType: MealType) {
        val today = LocalDate.now()
        DebugLogger.d("DEBUG: [LogViewModel] Applying notification target date=$today mealType=${mealType.rawValue}")
        _uiState.value = _uiState.value.copy(
            selectedDate = today,
            selectedMealType = mealType,
            isMealTypeManuallySet = true,
            latestResult = null,
            sourceSavedMealId = null
        )
    }

    fun clearLatestResult() {
        _uiState.value = _uiState.value.copy(latestResult = null, sourceSavedMealId = null)
    }

    // --- Favourites/Saved Meals ---

    fun saveLatestMealAsFavorite(renameTitle: String? = null): SavedMealEntity? {
        val result = _uiState.value.latestResult ?: return null
        val foodText = _uiState.value.foodText.ifBlank {
            result.items.firstOrNull()?.name ?: "Photo meal"
        }
        val suggestedTitle = renameTitle?.trim()?.ifBlank { null }
            ?: result.items.firstOrNull()?.name ?: "Fav Meal"

        val savedMeal = SavedMealEntity(
            id = UUID.randomUUID().toString(),
            title = suggestedTitle,
            foodText = foodText,
            mealType = result.mealType,
            totalCalories = result.totalCalories,
            rawResponseJson = json.encodeToString(MealLogResponse.serializer(), result),
            sourceMealId = _uiState.value.lastLoggedMealId,
            displayOrder = savedMeals.value.size
        )

        viewModelScope.launch {
            favRepo.save(savedMeal)
            _uiState.value.lastLoggedMealId?.let { mealId ->
                localRepo.updateSourceSavedMealId(mealId, savedMeal.id)
                localRepo.getMealEntryById(mealId)?.let { syncService.syncMealToCloud(it) }
            }
            syncService.syncSavedMealsToCloud()
        }
        _uiState.value = _uiState.value.copy(sourceSavedMealId = savedMeal.id)
        return savedMeal
    }

    fun logSavedMealAsIs(savedMeal: SavedMealEntity, servingMultiplier: Double = 1.0) {
        val rawJson = savedMeal.rawResponseJson
        val response = try {
            val decoded = json.decodeFromString(MealLogResponse.serializer(), rawJson)
            if (servingMultiplier != 1.0) {
                // Scale protein, carbs, fat, items calories
                val scaledItems = decoded.items.map {
                    it.copy(calories = it.calories * servingMultiplier)
                }
                decoded.copy(
                    totalCalories = decoded.totalCalories * servingMultiplier,
                    protein = decoded.protein?.let { it * servingMultiplier },
                    carbs = decoded.carbs?.let { it * servingMultiplier },
                    fat = decoded.fat?.let { it * servingMultiplier },
                    items = scaledItems
                )
            } else {
                decoded
            }
        } catch (e: Exception) {
            null
        }

        val totalCalories = response?.totalCalories ?: (savedMeal.totalCalories * servingMultiplier)
        val logFoodText = if (servingMultiplier == 1.0) {
            savedMeal.foodText
        } else {
            "${savedMeal.foodText} (${if (servingMultiplier % 1.0 == 0.0) servingMultiplier.toInt().toString() else String.format(Locale.US, "%.1f", servingMultiplier)}x serving)"
        }

        val entryId = UUID.randomUUID().toString()
        val timestamp = _uiState.value.selectedDate
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()

        viewModelScope.launch {
            try {
                localRepo.saveMeal(
                    timestampMillis = timestamp,
                    foodText = logFoodText,
                    mealType = savedMeal.mealType,
                    response = response ?: MealLogResponse(
                        mealType = savedMeal.mealType,
                        totalCalories = totalCalories,
                        protein = response?.protein,
                        carbs = response?.carbs,
                        fat = response?.fat,
                        items = emptyList(),
                        needsClarification = false,
                        clarifyingQuestion = null
                    ),
                    hasImage = false,
                    id = entryId,
                    sourceSavedMealId = savedMeal.id
                )
                // Sync to Cloud
                val mealEntry = localRepo.getMealEntryById(entryId)
                if (mealEntry != null) {
                    syncService.syncMealToCloud(mealEntry)
                }
                reminderService.rescheduleNotificationsIfNeeded()

                _uiState.value = _uiState.value.copy(
                    latestResult = response,
                    lastLoggedMealId = entryId,
                    sourceSavedMealId = savedMeal.id,
                    foodText = "",
                    attachedImageUris = emptyList()
                )
                AnalyticsService.trackMealLogged(
                    mealType = savedMeal.mealType,
                    totalCalories = totalCalories,
                    itemCount = response?.items?.size ?: 0,
                    hasImage = false
                )
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [LogViewModel] logSavedMealAsIs failed", e)
                _uiState.value = _uiState.value.copy(errorMessage = "Failed to log favorite meal.")
            }
        }
    }

    fun deleteFavoriteMeal(id: String) {
        viewModelScope.launch {
            favRepo.delete(id)
            localRepo.clearSourceSavedMealId(id)
            syncService.syncSavedMealsToCloud()
        }
    }

    fun renameFavoriteMeal(id: String, newName: String) {
        viewModelScope.launch {
            val item = favRepo.getById(id)
            if (item != null) {
                favRepo.save(item.copy(title = newName, updatedAtMillis = System.currentTimeMillis()))
                syncService.syncSavedMealsToCloud()
            }
        }
    }

    fun prepareSavedMealForEditing(savedMeal: SavedMealEntity) {
        _uiState.value = _uiState.value.copy(
            foodText = savedMeal.foodText,
            selectedMealType = try { MealType.valueOf(savedMeal.mealType.uppercase()) } catch(e: Exception) { MealType.BREAKFAST },
            isMealTypeManuallySet = true,
            attachedImageUris = emptyList(),
            latestResult = null,
            lastLoggedMealId = null,
            sourceSavedMealId = null
        )
    }

    // --- Speech Recognition ---

    fun toggleSpeechRecognition(target: SpeechTarget = SpeechTarget.MAIN) {
        if (_uiState.value.isTranscribingSpeech) return

        if (_uiState.value.isListening) {
            stopSpeechRecognition()
        } else {
            startSpeechRecognition(target)
        }
    }

    private fun startSpeechRecognition(target: SpeechTarget = SpeechTarget.MAIN) {
        AnalyticsService.trackSpeechRecognitionStarted()
        _uiState.value = _uiState.value.copy(
            isListening = true,
            speechTarget = target,
            speechErrorMessage = null,
            waveformSamples = List(64) { 0.08f }
        )

        val context = getApplication<Application>()
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }

        try {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
                setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {
                        val amplitude = ((rmsdB + 2f) / 12f).coerceIn(0.08f, 1.0f)
                        val current = _uiState.value.waveformSamples
                        val next = current.drop(1) + amplitude
                        _uiState.value = _uiState.value.copy(waveformSamples = next)
                    }
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {
                        _uiState.value = _uiState.value.copy(isTranscribingSpeech = true, isListening = false)
                    }
                    override fun onError(error: Int) {
                        val message = when (error) {
                            SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected."
                            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error."
                            SpeechRecognizer.ERROR_NETWORK -> "Network error."
                            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout."
                            else -> "Voice input failed."
                        }
                        _uiState.value = _uiState.value.copy(
                            isListening = false,
                            isTranscribingSpeech = false,
                            speechErrorMessage = message
                        )
                    }
                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull().orEmpty()
                        if (text.isNotBlank()) {
                            if (_uiState.value.speechTarget == SpeechTarget.QUICK_EDIT) {
                                appendQuickEditFoodText(text)
                            } else {
                                appendFoodText(text)
                            }
                        }
                        _uiState.value = _uiState.value.copy(isTranscribingSpeech = false)
                    }
                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
                startListening(intent)
            }
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isListening = false,
                speechErrorMessage = "Could not initialize voice input."
            )
        }
    }

    fun stopSpeechRecognition() {
        if (!_uiState.value.isListening) return
        AnalyticsService.trackSpeechRecognitionStopped()
        speechRecognizer?.stopListening()
        _uiState.value = _uiState.value.copy(isListening = false, isTranscribingSpeech = true)
    }

    fun cancelSpeechRecognition() {
        if (!_uiState.value.isListening) return
        AnalyticsService.trackSpeechRecognitionStopped()
        speechRecognizer?.cancel()
        speechRecognizer?.destroy()
        speechRecognizer = null
        _uiState.value = _uiState.value.copy(
            isListening = false,
            isTranscribingSpeech = false,
            waveformSamples = List(64) { 0.08f }
        )
    }

    fun onQuickEditFoodTextChanged(newText: String) {
        _uiState.value = _uiState.value.copy(quickEditFoodText = newText)
    }

    private fun appendQuickEditFoodText(recognizedText: String) {
        val incoming = recognizedText.trim()
        if (incoming.isEmpty()) return
        val current = _uiState.value.quickEditFoodText.trim()
        val next = if (current.isEmpty()) incoming else "$current $incoming"
        _uiState.value = _uiState.value.copy(quickEditFoodText = next)
    }

    // --- Logging ---

    fun logMeal() {
        val state = _uiState.value
        if (!state.isAuthReady) {
            _uiState.value = state.copy(errorMessage = "Not signed in yet.")
            return
        }

        // Cancel and merge voice in progress if any
        if (state.isListening) {
            stopSpeechRecognition()
        }

        val trimmed = state.foodText.trim()
        val hasImages = state.attachedImageUris.isNotEmpty()
        if (trimmed.isEmpty() && !hasImages) {
            _uiState.value = state.copy(errorMessage = "Please enter what you ate or attach a photo.")
            return
        }

        DebugLogger.d("DEBUG: [LogViewModel] logMeal() tapped date=${state.selectedDate} mealType=${state.selectedMealType.rawValue} hasImages=$hasImages imageCount=${state.attachedImageUris.size}")
        _uiState.value = state.copy(
            isLoading = true,
            errorMessage = null,
            latestResult = null,
            sourceSavedMealId = null
        )

        viewModelScope.launch {
            val imageBase64s = if (hasImages) {
                withContext(Dispatchers.IO) {
                    state.attachedImageUris.mapNotNull { uri ->
                        MealImageEncoder.encodeUriToJpegBase64(getApplication(), uri)
                    }
                }
            } else {
                emptyList()
            }
            if (hasImages && imageBase64s.isEmpty()) {
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
                imageBase64s = imageBase64s,
                country = prefManager.userCountry.takeIf { it.isNotBlank() }
            )
            result.fold(
                onSuccess = { response ->
                    DebugLogger.d("DEBUG: [LogViewModel] logMeal() success totalCalories=${response.totalCalories}")
                    val storedLabel = trimmed.ifBlank {
                        response.items.firstOrNull()?.name?.takeIf { it.isNotBlank() } ?: "Photo meal"
                    }
                    val timestampMillis = state.selectedDate
                        .atStartOfDay(ZoneId.systemDefault())
                        .toInstant()
                        .toEpochMilli()
                    val entryId = UUID.randomUUID().toString()

                    try {
                        localRepo.saveMeal(
                            timestampMillis = timestampMillis,
                            foodText = storedLabel,
                            mealType = response.mealType,
                            response = response,
                            hasImage = imageBase64s.isNotEmpty(),
                            id = entryId
                        )
                        val mealEntry = localRepo.getMealEntryById(entryId)
                        if (mealEntry != null) {
                            syncService.syncMealToCloud(mealEntry)
                        }
                        reminderService.rescheduleNotificationsIfNeeded()
                        DebugLogger.d("DEBUG: [LogViewModel] Meal saved to local DB foodTextLen=${storedLabel.length}")
                    } catch (t: Throwable) {
                        DebugLogger.e("DEBUG: [LogViewModel] Failed to save meal to local DB", t)
                    }

                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        latestResult = response,
                        lastLoggedMealId = entryId,
                        sourceSavedMealId = null,
                        errorMessage = null,
                        foodText = "",
                        quickEditFoodText = "",
                        attachedImageUris = emptyList()
                    )
                    AnalyticsService.trackMealLogged(
                        mealType = response.mealType,
                        totalCalories = response.totalCalories,
                        itemCount = response.items.size,
                        hasImage = imageBase64s.isNotEmpty()
                    )
                },
                onFailure = { t ->
                    DebugLogger.e("DEBUG: [LogViewModel] logMeal() failed", t)
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        latestResult = null,
                        errorMessage = "Failed to log meal. Please try again."
                    )
                    AnalyticsService.trackMealLogFailed(
                        errorType = t.localizedMessage ?: "Unknown error"
                    )
                }
            )
        }
    }

    fun quickRefineLoggedMeal(prompt: String) {
        val state = _uiState.value
        val mealId = state.lastLoggedMealId
        val prevResult = state.latestResult
        if (mealId == null || prevResult == null) {
            _uiState.value = state.copy(errorMessage = "Could not find the logged meal to update.")
            return
        }

        _uiState.value = state.copy(isRefiningMeal = true, errorMessage = null)

        viewModelScope.launch {
            val result = repo.refineMealLog(
                foodText = state.foodText,
                mealType = state.selectedMealType,
                previousEstimate = prevResult,
                correctionPrompt = prompt,
                country = prefManager.userCountry.takeIf { it.isNotBlank() }
            )
            result.fold(
                onSuccess = { response ->
                    try {
                        val mealEntry = localRepo.getMealById(mealId)
                        if (mealEntry != null) {
                            localRepo.saveMeal(
                                timestampMillis = mealEntry.timestampMillis,
                                foodText = mealEntry.foodText,
                                mealType = response.mealType,
                                response = response,
                                hasImage = mealEntry.hasImage,
                                id = mealId,
                                sourceSavedMealId = mealEntry.sourceSavedMealId
                            )
                            val updated = localRepo.getMealEntryById(mealId)
                            if (updated != null) {
                                syncService.syncMealToCloud(updated)
                            }
                        }
                    } catch (e: Exception) {
                        DebugLogger.e("DEBUG: [LogViewModel] Failed to update refined meal in DB", e)
                    }

                    _uiState.value = _uiState.value.copy(
                        isRefiningMeal = false,
                        latestResult = response,
                        quickEditFoodText = "",
                        errorMessage = null
                    )
                },
                onFailure = { t ->
                    _uiState.value = _uiState.value.copy(
                        isRefiningMeal = false,
                        errorMessage = "Failed to update meal. Please try again."
                    )
                }
            )
        }
    }

    fun checkAndResetSelectedDateIfNeeded() {
        val now = LocalDate.now()
        val lastActiveStr = prefManager.lastActiveDateLog
        val lastActive = if (!lastActiveStr.isNullOrBlank()) {
            try { LocalDate.parse(lastActiveStr) } catch (e: Exception) { now }
        } else {
            now
        }

        // If the selectedDate matches the lastActiveDate, check if date has rolled over
        if (_uiState.value.selectedDate == lastActive) {
            if (_uiState.value.selectedDate != now) {
                _uiState.value = _uiState.value.copy(selectedDate = now, latestResult = null)
            }
        }
        prefManager.lastActiveDateLog = now.toString()
    }

    override fun onCleared() {
        super.onCleared()
        speechRecognizer?.destroy()
    }
}
