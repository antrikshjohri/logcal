package com.serene.logcal.service

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.serene.logcal.MainActivity
import com.serene.logcal.R
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealType
import com.serene.logcal.util.DebugLogger
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

class MealReminderService(private val context: Context) {
    private val appContext = context.applicationContext
    private val prefManager = AppGraph.preferenceManager(appContext)
    private val localRepo = AppGraph.localMealRepository(appContext)
    private val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    suspend fun scheduleAll() {
        createNotificationChannel()

        if (!prefManager.mealRemindersEnabled) {
            cancelAll()
            return
        }

        if (!hasNotificationPermission()) {
            DebugLogger.w("DEBUG: [MealReminderService] Notification permission missing, skipping schedule")
            cancelAll()
            return
        }

        scheduleReminder(
            spec = ReminderSpec.BREAKFAST,
            hour = prefManager.breakfastHour,
            minute = prefManager.breakfastMinute,
            forceTomorrow = false
        )
        scheduleReminder(
            spec = ReminderSpec.LUNCH,
            hour = prefManager.lunchHour,
            minute = prefManager.lunchMinute,
            forceTomorrow = false
        )
        scheduleReminder(
            spec = ReminderSpec.DINNER,
            hour = prefManager.dinnerHour,
            minute = prefManager.dinnerMinute,
            forceTomorrow = false
        )
    }

    suspend fun rescheduleNotificationsIfNeeded() {
        scheduleAll()
    }

    suspend fun handleReminderAlarm(mealTypeRawValue: String?) {
        val spec = ReminderSpec.fromRawValue(mealTypeRawValue) ?: return

        if (!prefManager.mealRemindersEnabled) {
            cancel(spec)
            return
        }

        createNotificationChannel()

        if (hasNotificationPermission() && shouldSendNotification(spec.mealType)) {
            showNotification(spec)
        } else {
            DebugLogger.d("DEBUG: [MealReminderService] Skipping ${spec.mealType.rawValue} reminder")
        }

        scheduleReminder(
            spec = spec,
            hour = spec.hour(prefManager),
            minute = spec.minute(prefManager),
            forceTomorrow = true
        )
    }

    fun cancelAll() {
        ReminderSpec.entries.forEach { cancel(it) }
        DebugLogger.d("DEBUG: [MealReminderService] Cancelled all meal reminders")
    }

    private suspend fun scheduleReminder(
        spec: ReminderSpec,
        hour: Int,
        minute: Int,
        forceTomorrow: Boolean
    ) {
        val shouldScheduleToday = !forceTomorrow && !hasLoggedMealTypeToday(spec.mealType)
        val triggerAtMillis = nextTriggerMillis(
            hour = hour,
            minute = minute,
            forceTomorrow = forceTomorrow || !shouldScheduleToday
        )
        val pendingIntent = pendingIntentFor(spec)

        alarmManager.cancel(pendingIntent)
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)

        DebugLogger.d(
            "DEBUG: [MealReminderService] Scheduled ${spec.mealType.rawValue} reminder at $triggerAtMillis"
        )
    }

    private suspend fun shouldSendNotification(mealType: MealType): Boolean {
        if (hasLoggedMealTypeToday(mealType)) {
            DebugLogger.d("DEBUG: [MealReminderService] ${mealType.rawValue} already logged today")
            return false
        }

        val recentCutoffMillis = System.currentTimeMillis() - RECENT_ACTIVITY_WINDOW_MILLIS
        if (localRepo.hasMealCreatedSince(recentCutoffMillis)) {
            DebugLogger.d("DEBUG: [MealReminderService] Recent meal activity detected")
            return false
        }

        return true
    }

    private suspend fun hasLoggedMealTypeToday(mealType: MealType): Boolean {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        val startMillis = today.atStartOfDay(zone).toInstant().toEpochMilli()
        val endMillis = today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        return localRepo.hasMealTypeBetween(mealType.rawValue, startMillis, endMillis)
    }

    private fun showNotification(spec: ReminderSpec) {
        val logoBitmap = BitmapFactory.decodeResource(appContext.resources, R.mipmap.ic_launcher_foreground)
        val launchIntent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_OPEN_TAB, MainActivity.OPEN_TAB_LOG)
            putExtra(EXTRA_MEAL_TYPE, spec.mealType.rawValue)
        }
        val contentIntent = PendingIntent.getActivity(
            appContext,
            spec.requestCode + CONTENT_REQUEST_OFFSET,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher_foreground)
            .setLargeIcon(logoBitmap)
            .setContentTitle("Meal Reminder")
            .setContentText(notificationBody(spec.mealType))
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        NotificationManagerCompat.from(appContext).notify(spec.notificationId, notification)
        DebugLogger.d(
            "DEBUG: [MealReminderService] Posted ${spec.mealType.rawValue} reminder " +
                "with tap mealType=${spec.mealType.rawValue}"
        )
    }

    private fun notificationBody(mealType: MealType): String {
        return when (mealType) {
            MealType.BREAKFAST -> "Time for breakfast! Log your meal to track your calories"
            MealType.LUNCH -> "Lunch time! Don't forget to log your meal"
            MealType.DINNER -> "Dinner time! Log your meal to stay on track"
            MealType.SNACK -> "Time to log your snack!"
        }
    }

    private fun nextTriggerMillis(hour: Int, minute: Int, forceTomorrow: Boolean): Long {
        val zone = ZoneId.systemDefault()
        val now = ZonedDateTime.now(zone)
        var next = ZonedDateTime.of(LocalDate.now(zone), LocalTime.of(hour, minute), zone)

        if (forceTomorrow || !next.isAfter(now)) {
            next = next.plusDays(1)
        }

        return next.toInstant().toEpochMilli()
    }

    private fun pendingIntentFor(spec: ReminderSpec): PendingIntent {
        val intent = Intent(appContext, MealReminderReceiver::class.java).apply {
            action = ACTION_SHOW_MEAL_REMINDER
            putExtra(EXTRA_MEAL_TYPE, spec.mealType.rawValue)
        }
        return PendingIntent.getBroadcast(
            appContext,
            spec.requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun cancel(spec: ReminderSpec) {
        alarmManager.cancel(pendingIntentFor(spec))
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(appContext, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Meal reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Reminders to log breakfast, lunch, and dinner"
            enableVibration(true)
        }

        val manager = appContext.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private enum class ReminderSpec(
        val mealType: MealType,
        val requestCode: Int,
        val notificationId: Int
    ) {
        BREAKFAST(MealType.BREAKFAST, 4101, 5101),
        LUNCH(MealType.LUNCH, 4102, 5102),
        DINNER(MealType.DINNER, 4103, 5103);

        fun hour(prefManager: com.serene.logcal.data.local.PreferenceManager): Int {
            return when (this) {
                BREAKFAST -> prefManager.breakfastHour
                LUNCH -> prefManager.lunchHour
                DINNER -> prefManager.dinnerHour
            }
        }

        fun minute(prefManager: com.serene.logcal.data.local.PreferenceManager): Int {
            return when (this) {
                BREAKFAST -> prefManager.breakfastMinute
                LUNCH -> prefManager.lunchMinute
                DINNER -> prefManager.dinnerMinute
            }
        }

        companion object {
            fun fromRawValue(rawValue: String?): ReminderSpec? {
                return entries.firstOrNull { it.mealType.rawValue == rawValue }
            }
        }
    }

    companion object {
        const val ACTION_SHOW_MEAL_REMINDER = "com.serene.logcal.action.SHOW_MEAL_REMINDER"
        const val EXTRA_MEAL_TYPE = "meal_type"

        private const val CHANNEL_ID = "meal_reminders_alerts"
        private const val CONTENT_REQUEST_OFFSET = 100
        private const val RECENT_ACTIVITY_WINDOW_MILLIS = 30 * 60 * 1000L
    }
}
