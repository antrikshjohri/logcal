package com.serene.logcal.data.local

import android.content.Context
import android.content.SharedPreferences

class PreferenceManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
    private val legacyDashboardPrefs: SharedPreferences = context.getSharedPreferences("logcal_dashboard_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_DAILY_GOAL = "dailyGoal"
        private const val KEY_PROTEIN_GOAL = "proteinGoal"
        private const val KEY_CARBS_GOAL = "carbsGoal"
        private const val KEY_FAT_GOAL = "fatGoal"
        private const val KEY_DIET_STYLE = "dietStyle"
        private const val KEY_CUSTOM_PROTEIN_PERCENT = "customProteinPercent"
        private const val KEY_CUSTOM_CARBS_PERCENT = "customCarbsPercent"
        private const val KEY_CUSTOM_FAT_PERCENT = "customFatPercent"
        private const val KEY_APP_THEME = "appTheme"
        private const val KEY_MEAL_REMINDERS_ENABLED = "mealRemindersEnabled"
        private const val KEY_USER_COUNTRY = "userCountry"
        private const val KEY_BREAKFAST_HOUR = "breakfastHour"
        private const val KEY_BREAKFAST_MINUTE = "breakfastMinute"
        private const val KEY_LUNCH_HOUR = "lunchHour"
        private const val KEY_LUNCH_MINUTE = "lunchMinute"
        private const val KEY_DINNER_HOUR = "dinnerHour"
        private const val KEY_DINNER_MINUTE = "dinnerMinute"
        private const val KEY_LAST_SYNCED_USER_ID = "lastSyncedUserId"
        private const val KEY_HAS_REQUESTED_NOTIFICATION_PERMISSION = "hasRequestedNotificationPermission"
    }

    var dailyGoal: Double
        get() {
            if (prefs.contains(KEY_DAILY_GOAL)) {
                return prefs.getFloat(KEY_DAILY_GOAL, 2000f).toDouble()
            }
            if (legacyDashboardPrefs.contains("daily_goal")) {
                val valInt = legacyDashboardPrefs.getInt("daily_goal", 2200)
                return valInt.toDouble()
            }
            return 2000.0
        }
        set(value) {
            prefs.edit().putFloat(KEY_DAILY_GOAL, value.toFloat()).apply()
            legacyDashboardPrefs.edit().putInt("daily_goal", value.toInt()).apply()
        }

    var proteinGoal: Double
        get() = prefs.getFloat(KEY_PROTEIN_GOAL, 150f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_PROTEIN_GOAL, value.toFloat()).apply()

    var carbsGoal: Double
        get() = prefs.getFloat(KEY_CARBS_GOAL, 200f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_CARBS_GOAL, value.toFloat()).apply()

    var fatGoal: Double
        get() = prefs.getFloat(KEY_FAT_GOAL, 65f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_FAT_GOAL, value.toFloat()).apply()

    var dietStyle: String
        get() = prefs.getString(KEY_DIET_STYLE, "Balanced") ?: "Balanced"
        set(value) = prefs.edit().putString(KEY_DIET_STYLE, value).apply()

    var customProteinPercent: Double
        get() = prefs.getFloat(KEY_CUSTOM_PROTEIN_PERCENT, 30f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_CUSTOM_PROTEIN_PERCENT, value.toFloat()).apply()

    var customCarbsPercent: Double
        get() = prefs.getFloat(KEY_CUSTOM_CARBS_PERCENT, 40f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_CUSTOM_CARBS_PERCENT, value.toFloat()).apply()

    var customFatPercent: Double
        get() = prefs.getFloat(KEY_CUSTOM_FAT_PERCENT, 30f).toDouble()
        set(value) = prefs.edit().putFloat(KEY_CUSTOM_FAT_PERCENT, value.toFloat()).apply()

    var appTheme: String
        get() = prefs.getString(KEY_APP_THEME, "system") ?: "system"
        set(value) = prefs.edit().putString(KEY_APP_THEME, value).apply()

    var mealRemindersEnabled: Boolean
        get() = prefs.getBoolean(KEY_MEAL_REMINDERS_ENABLED, true)
        set(value) = prefs.edit().putBoolean(KEY_MEAL_REMINDERS_ENABLED, value).apply()

    var userCountry: String
        get() = prefs.getString(KEY_USER_COUNTRY, "") ?: ""
        set(value) = prefs.edit().putString(KEY_USER_COUNTRY, value).apply()

    var breakfastHour: Int
        get() = prefs.getInt(KEY_BREAKFAST_HOUR, 8)
        set(value) = prefs.edit().putInt(KEY_BREAKFAST_HOUR, value).apply()

    var breakfastMinute: Int
        get() = prefs.getInt(KEY_BREAKFAST_MINUTE, 30)
        set(value) = prefs.edit().putInt(KEY_BREAKFAST_MINUTE, value).apply()

    var lunchHour: Int
        get() = prefs.getInt(KEY_LUNCH_HOUR, 13)
        set(value) = prefs.edit().putInt(KEY_LUNCH_HOUR, value).apply()

    var lunchMinute: Int
        get() = prefs.getInt(KEY_LUNCH_MINUTE, 0)
        set(value) = prefs.edit().putInt(KEY_LUNCH_MINUTE, value).apply()

    var dinnerHour: Int
        get() = prefs.getInt(KEY_DINNER_HOUR, 20)
        set(value) = prefs.edit().putInt(KEY_DINNER_HOUR, value).apply()

    var dinnerMinute: Int
        get() = prefs.getInt(KEY_DINNER_MINUTE, 0)
        set(value) = prefs.edit().putInt(KEY_DINNER_MINUTE, value).apply()

    var lastSyncedUserId: String?
        get() = prefs.getString(KEY_LAST_SYNCED_USER_ID, null)
        set(value) = prefs.edit().putString(KEY_LAST_SYNCED_USER_ID, value).apply()

    var hasRequestedNotificationPermission: Boolean
        get() = prefs.getBoolean(KEY_HAS_REQUESTED_NOTIFICATION_PERMISSION, false)
        set(value) = prefs.edit().putBoolean(KEY_HAS_REQUESTED_NOTIFICATION_PERMISSION, value).apply()

    fun hasStoredUserPreferences(): Boolean {
        return prefs.contains(KEY_DAILY_GOAL) ||
            prefs.contains(KEY_PROTEIN_GOAL) ||
            prefs.contains(KEY_CARBS_GOAL) ||
            prefs.contains(KEY_FAT_GOAL) ||
            prefs.contains(KEY_DIET_STYLE) ||
            legacyDashboardPrefs.contains("daily_goal")
    }

    fun hasStoredNotificationPreferences(): Boolean {
        return prefs.contains(KEY_MEAL_REMINDERS_ENABLED) ||
            prefs.contains(KEY_BREAKFAST_HOUR) ||
            prefs.contains(KEY_BREAKFAST_MINUTE) ||
            prefs.contains(KEY_LUNCH_HOUR) ||
            prefs.contains(KEY_LUNCH_MINUTE) ||
            prefs.contains(KEY_DINNER_HOUR) ||
            prefs.contains(KEY_DINNER_MINUTE)
    }

    fun hasStoredUserCountry(): Boolean {
        return prefs.contains(KEY_USER_COUNTRY) && userCountry.isNotBlank()
    }

    var lastActiveDateDashboard: String?
        get() = prefs.getString("lastActiveDateDashboard", null)
        set(value) = prefs.edit().putString("lastActiveDateDashboard", value).apply()

    var lastActiveDateLog: String?
        get() = prefs.getString("lastActiveDateLog", null)
        set(value) = prefs.edit().putString("lastActiveDateLog", value).apply()
}
