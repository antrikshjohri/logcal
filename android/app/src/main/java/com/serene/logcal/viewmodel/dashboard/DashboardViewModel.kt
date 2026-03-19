package com.serene.logcal.viewmodel.dashboard

import android.app.Application
import android.content.Context
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
    private val prefs = application.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    private val _uiState = MutableStateFlow(
        DashboardUiState(dailyGoal = prefs.getInt(KEY_DAILY_GOAL, DEFAULT_DAILY_GOAL))
    )
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        DebugLogger.d("DEBUG: [DashboardViewModel] init()")
        observeMeals()
    }

    fun setDailyGoal(newGoal: Int) {
        val goal = newGoal.coerceIn(500, 10000)
        prefs.edit().putInt(KEY_DAILY_GOAL, goal).apply()
        DebugLogger.d("DEBUG: [DashboardViewModel] setDailyGoal() goal=$goal")
        _uiState.update { it.copy(dailyGoal = goal) }
    }

    private fun observeMeals() {
        viewModelScope.launch {
            localRepo.observeHistoryMeals().collect { meals ->
                val dashboard = computeDashboardStats(meals, _uiState.value.dailyGoal)
                DebugLogger.d(
                    "DEBUG: [DashboardViewModel] observeMeals() count=${meals.size} todayCalories=${dashboard.todayCalories} goal=${dashboard.dailyGoal}"
                )
                _uiState.value = dashboard.copy(isLoading = false, errorMessage = null)
            }
        }
    }

    private fun computeDashboardStats(meals: List<HistoryMeal>, goal: Int): DashboardUiState {
        val today = LocalDate.now()
        val zone = ZoneId.systemDefault()

        val mealsByDate: Map<LocalDate, List<HistoryMeal>> = meals.groupBy { meal ->
            Instant.ofEpochMilli(meal.timestampMillis).atZone(zone).toLocalDate()
        }

        val todayMeals = mealsByDate[today].orEmpty()
        val todayCalories = todayMeals.sumOf { it.totalCalories }.roundToInt()
        val protein = todayMeals.sumOf { it.response.protein ?: 0.0 }.roundToInt()
        val carbs = todayMeals.sumOf { it.response.carbs ?: 0.0 }.roundToInt()
        val fat = todayMeals.sumOf { it.response.fat ?: 0.0 }.roundToInt()
        val remainingCalories = (goal - todayCalories).coerceAtLeast(0)

        val weekly = (6 downTo 0).map { offset ->
            val date = today.minusDays(offset.toLong())
            val dayCalories = mealsByDate[date].orEmpty().sumOf { it.totalCalories }.roundToInt()
            WeeklyDayStat(date = date, calories = dayCalories)
        }
        val weeklyAverage = if (weekly.isNotEmpty()) weekly.map { it.calories }.average().roundToInt() else 0
        val streakDays = calculateStreakDays(today, mealsByDate)

        // Target macros based on a basic 30/40/30 split of daily goal.
        val proteinTarget = ((goal * 0.30) / 4.0).roundToInt().coerceAtLeast(1)
        val carbsTarget = ((goal * 0.40) / 4.0).roundToInt().coerceAtLeast(1)
        val fatTarget = ((goal * 0.30) / 9.0).roundToInt().coerceAtLeast(1)

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
            if (!hasMeals) break
            streak += 1
            cursor = cursor.minusDays(1)
        }
        return streak
    }
}

