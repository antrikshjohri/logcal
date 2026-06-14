package com.serene.logcal.viewmodel.dashboard

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.data.local.PreferenceManager
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.CloudSyncService
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.model.DietStyle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.roundToInt

private const val PREF_NAME = "logcal_dashboard_prefs"
private const val KEY_DAILY_GOAL = "daily_goal"
private const val DEFAULT_DAILY_GOAL = 2200

data class WeeklyDayStat(
    val date: LocalDate,
    val calories: Int,
)

data class DashboardUiState(
    val isLoading: Boolean = true,
    val todayCalories: Int = 0,
    val dailyGoal: Int = DEFAULT_DAILY_GOAL,
    val remainingCalories: Int = DEFAULT_DAILY_GOAL,
    val proteinGrams: Int = 0,
    val carbsGrams: Int = 0,
    val fatGrams: Int = 0,
    val macroProteinPercent: Int = 0,
    val macroCarbsPercent: Int = 0,
    val macroFatPercent: Int = 0,
    val weeklyStats: List<WeeklyDayStat> = emptyList(),
    val weeklyAverageCalories: Int = 0,
    val streakDays: Int = 0,
    val errorMessage: String? = null,
)

class DashboardViewModel(application: Application) : AndroidViewModel(application) {
    private val localRepo = AppGraph.localMealRepository(application)
    private val prefManager = AppGraph.preferenceManager(application)
    private val syncService = AppGraph.cloudSyncService(application)

    private val _selectedDate = MutableStateFlow(LocalDate.now())
    val selectedDate: StateFlow<LocalDate> = _selectedDate.asStateFlow()
    
    private val _uiState = MutableStateFlow(
        DashboardUiState(
            dailyGoal = prefManager.dailyGoal.roundToInt(),
            remainingCalories = prefManager.dailyGoal.roundToInt()
        )
    )
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    val isRefreshing: StateFlow<Boolean> = syncService.isSyncing

    fun refreshData() {
        viewModelScope.launch {
            syncService.syncFromCloud()
        }
    }

    init {
        DebugLogger.d("DEBUG: [DashboardViewModel] init()")
        observeMeals()
        
        // Initial setup of last active date
        if (prefManager.lastActiveDateDashboard.isNullOrBlank()) {
            prefManager.lastActiveDateDashboard = LocalDate.now().toString()
        }
    }

    fun changeDate(byDays: Int) {
        val next = _selectedDate.value.plusDays(byDays.toLong())
        DebugLogger.d("DEBUG: [DashboardViewModel] changeDate() from=${_selectedDate.value} to=$next")
        _selectedDate.value = next
    }

    fun setSelectedDate(date: LocalDate) {
        DebugLogger.d("DEBUG: [DashboardViewModel] setSelectedDate() to=$date")
        _selectedDate.value = date
    }

    fun checkAndResetSelectedDateIfNeeded() {
        val now = LocalDate.now()
        val lastActiveStr = prefManager.lastActiveDateDashboard
        val lastActive = if (!lastActiveStr.isNullOrBlank()) {
            try { LocalDate.parse(lastActiveStr) } catch (e: Exception) { now }
        } else {
            now
        }

        if (_selectedDate.value == lastActive) {
            if (_selectedDate.value != now) {
                DebugLogger.d("DEBUG: [DashboardViewModel] Day rolled over, resetting selectedDate to $now")
                _selectedDate.value = now
            }
        }
        prefManager.lastActiveDateDashboard = now.toString()
    }

    fun setDailyGoal(newGoal: Int) {
        val goal = newGoal.coerceIn(500, 10000)
        prefManager.dailyGoal = goal.toDouble()
        
        val style = DietStyle.fromRawValue(prefManager.dietStyle)
        if (style != DietStyle.CUSTOM) {
            val (pPercent, cPercent, fPercent) = style.macroPercentages
            val (pGrams, cGrams, fGrams) = DietStyle.calculateGrams(goal.toDouble(), pPercent, cPercent, fPercent)
            prefManager.proteinGoal = pGrams
            prefManager.carbsGoal = cGrams
            prefManager.fatGoal = fGrams
        }
        
        DebugLogger.d("DEBUG: [DashboardViewModel] setDailyGoal() goal=$goal")
        
        viewModelScope.launch {
            syncService.syncDailyGoalToCloud(goal.toDouble())
            val meals = localRepo.observeHistoryMeals().first()
            _uiState.update { computeDashboardStats(meals, goal, _selectedDate.value) }
        }
    }

    private fun observeMeals() {
        viewModelScope.launch {
            combine(localRepo.observeHistoryMeals(), _selectedDate) { meals, date ->
                Pair(meals, date)
            }.collect { (meals, date) ->
                val currentGoal = prefManager.dailyGoal.roundToInt()
                val dashboard = computeDashboardStats(meals, currentGoal, date)
                DebugLogger.d(
                    "DEBUG: [DashboardViewModel] observeMeals() count=${meals.size} date=$date todayCalories=${dashboard.todayCalories} goal=${dashboard.dailyGoal}"
                )
                _uiState.value = dashboard.copy(isLoading = false, errorMessage = null)
            }
        }
    }

    private fun computeDashboardStats(meals: List<HistoryMeal>, goal: Int, date: LocalDate): DashboardUiState {
        val zone = ZoneId.systemDefault()

        val mealsByDate: Map<LocalDate, List<HistoryMeal>> = meals.groupBy { meal ->
            Instant.ofEpochMilli(meal.timestampMillis).atZone(zone).toLocalDate()
        }

        val dayMeals = mealsByDate[date].orEmpty()
        val todayCalories = dayMeals.sumOf { it.totalCalories }.roundToInt()
        val protein = dayMeals.sumOf { it.response.protein ?: 0.0 }.roundToInt()
        val carbs = dayMeals.sumOf { it.response.carbs ?: 0.0 }.roundToInt()
        val fat = dayMeals.sumOf { it.response.fat ?: 0.0 }.roundToInt()
        val remainingCalories = (goal - todayCalories).coerceAtLeast(0)

        val today = LocalDate.now(zone)
        // Weekly stats: last 7 days ending today (inclusive)
        val weekly = (6 downTo 0).map { offset ->
            val d = today.minusDays(offset.toLong())
            val dayCalories = mealsByDate[d].orEmpty().sumOf { it.totalCalories }.roundToInt()
            WeeklyDayStat(date = d, calories = dayCalories)
        }
        val weeklyAverage = if (weekly.isNotEmpty()) weekly.map { it.calories }.average().roundToInt() else 0
        
        val streakDays = calculateStreakDays(today, mealsByDate)

        val proteinTarget = prefManager.proteinGoal.roundToInt().coerceAtLeast(1)
        val carbsTarget = prefManager.carbsGoal.roundToInt().coerceAtLeast(1)
        val fatTarget = prefManager.fatGoal.roundToInt().coerceAtLeast(1)

        return DashboardUiState(
            isLoading = false,
            todayCalories = todayCalories,
            dailyGoal = goal,
            remainingCalories = remainingCalories,
            proteinGrams = protein,
            carbsGrams = carbs,
            fatGrams = fat,
            macroProteinPercent = ((protein.toFloat() / proteinTarget.toFloat()) * 100f).roundToInt().coerceIn(0, 999),
            macroCarbsPercent = ((carbs.toFloat() / carbsTarget.toFloat()) * 100f).roundToInt().coerceIn(0, 999),
            macroFatPercent = ((fat.toFloat() / fatTarget.toFloat()) * 100f).roundToInt().coerceIn(0, 999),
            weeklyStats = weekly,
            weeklyAverageCalories = weeklyAverage,
            streakDays = streakDays,
        )
    }

    private fun calculateStreakDays(
        today: LocalDate,
        mealsByDate: Map<LocalDate, List<HistoryMeal>>
    ): Int {
        var streak = 0
        var cursor = today
        while (true) {
            val hasMeals = mealsByDate[cursor].orEmpty().isNotEmpty()
            if (!hasMeals) {
                // If it's today, it might be that they haven't logged today yet but had a streak yesterday.
                if (cursor == today) {
                    val yesterday = today.minusDays(1)
                    val yesterdayHasMeals = mealsByDate[yesterday].orEmpty().isNotEmpty()
                    if (yesterdayHasMeals) {
                        cursor = yesterday
                        continue
                    }
                }
                break
            }
            streak += 1
            cursor = cursor.minusDays(1)
        }
        return streak
    }
}

