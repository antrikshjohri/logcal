package com.serene.logcal.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MealReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                AppGraph.mealReminderService(context).scheduleAll()
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [MealReminderBootReceiver] Failed to reschedule reminders", e)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
