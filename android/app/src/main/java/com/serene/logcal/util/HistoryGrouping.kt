package com.serene.logcal.util

import com.serene.logcal.data.local.HistoryMeal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Groups meals by calendar day (device zone). Today is always included when there is at least one meal
 * (parity with iOS History): future meals first, then today, then past days.
 */
data class HistoryDaySection(
    val date: LocalDate,
    val meals: List<HistoryMeal>,
    val totalCalories: Double,
    val isToday: Boolean,
)

fun buildDaySections(
    meals: List<HistoryMeal>,
    zone: ZoneId = ZoneId.systemDefault(),
): List<HistoryDaySection> {
    if (meals.isEmpty()) {
        DebugLogger.d("DEBUG: [HistoryGrouping] buildDaySections() empty input")
        return emptyList()
    }
    val today = LocalDate.now(zone)
    val byDay = meals.groupBy { Instant.ofEpochMilli(it.timestampMillis).atZone(zone).toLocalDate() }
    val dates = (byDay.keys + today).distinct()
    val sortedDates = dates.sortedWith { a, b ->
        when {
            a == today && b == today -> 0
            a.isAfter(today) && b.isAfter(today) -> b.compareTo(a)
            a.isAfter(today) -> -1
            b.isAfter(today) -> 1
            a == today -> -1
            b == today -> 1
            else -> b.compareTo(a)
        }
    }
    val sections = sortedDates.map { date ->
        val dayMeals = byDay[date].orEmpty().sortedByDescending { it.createdAtMillis }
        val total = dayMeals.sumOf { it.totalCalories }
        HistoryDaySection(
            date = date,
            meals = dayMeals,
            totalCalories = total,
            isToday = date == today,
        )
    }
    DebugLogger.d("DEBUG: [HistoryGrouping] buildDaySections() sections=${sections.size} sorted correctly")
    return sections
}
