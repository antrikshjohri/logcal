package com.serene.logcal.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MealReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != MealReminderService.ACTION_SHOW_MEAL_REMINDER) return

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                AppGraph.mealReminderService(context).handleReminderAlarm(
                    intent.getStringExtra(MealReminderService.EXTRA_MEAL_TYPE)
                )
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [MealReminderReceiver] Failed to handle reminder", e)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
