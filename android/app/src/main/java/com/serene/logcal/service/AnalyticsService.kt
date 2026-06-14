package com.serene.logcal.service

import android.content.Context
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.serene.logcal.util.DebugLogger

object AnalyticsService {
    private var firebaseAnalytics: FirebaseAnalytics? = null

    fun initialize(context: Context) {
        firebaseAnalytics = FirebaseAnalytics.getInstance(context.applicationContext)
    }

    // --- Authentication Events ---
    fun trackSignUp(method: String) {
        logEvent("user_signup", mapOf("method" to method))
    }

    fun trackLogin(method: String) {
        logEvent("user_login", mapOf("method" to method))
    }

    fun trackLogout() {
        logEvent("user_logout")
    }

    fun trackAccountDeleted() {
        logEvent("account_deleted")
    }

    // --- Meal Logging Events ---
    fun trackMealLogged(mealType: String, totalCalories: Double, itemCount: Int, hasImage: Boolean = false) {
        logEvent("meal_logged", mapOf(
            "meal_type" to mealType,
            "total_calories" to totalCalories,
            "item_count" to itemCount,
            "has_image" to hasImage
        ))
    }

    fun trackMealLogFailed(errorType: String) {
        logEvent("meal_log_failed", mapOf("error_type" to errorType))
        logMessage("Meal log failed with error: $errorType")
    }

    fun trackMealEdited() {
        logEvent("meal_edited")
    }

    fun trackMealDeleted() {
        logEvent("meal_deleted")
    }

    // --- Navigation Events ---
    fun trackTabChanged(tabName: String) {
        logEvent("tab_changed", mapOf("tab_name" to tabName))
    }

    fun trackViewOpened(viewName: String) {
        logEvent("view_opened", mapOf("view_name" to viewName))
    }

    // --- Feature Usage Events ---
    fun trackSpeechRecognitionStarted() {
        logEvent("speech_recognition_started")
    }

    fun trackSpeechRecognitionStopped() {
        logEvent("speech_recognition_stopped")
    }

    fun trackDatePickerOpened() {
        logEvent("date_picker_opened")
    }

    fun trackMealTypeChanged(mealType: String) {
        logEvent("meal_type_changed", mapOf("meal_type" to mealType))
    }

    fun trackDailyGoalChanged(newGoal: Double) {
        logEvent("daily_goal_changed", mapOf("new_goal" to newGoal))
    }

    fun trackImagePickerOpened() {
        logEvent("image_picker_opened")
    }

    fun trackCameraPickerOpened() {
        logEvent("camera_picker_opened")
    }

    fun trackImageSelected() {
        logEvent("image_selected")
    }

    fun trackImageRemoved() {
        logEvent("image_removed")
    }

    // --- User Engagement Events ---
    fun trackMealSummaryViewed() {
        logEvent("meal_summary_viewed")
    }

    fun trackHelpFAQOpened() {
        logEvent("help_faq_opened")
    }

    fun trackThemeChanged(themeName: String) {
        logEvent("theme_changed", mapOf("theme_name" to themeName))
    }

    // --- Notification Events ---
    fun trackNotificationPreferenceChanged(mealRemindersEnabled: Boolean) {
        logEvent("notification_preference_changed", mapOf("meal_reminders_enabled" to mealRemindersEnabled))
    }

    fun trackNotificationTapped(notificationType: String) {
        logEvent("notification_tapped", mapOf("notification_type" to notificationType))
    }

    fun trackNotificationPermissionRequested() {
        logEvent("notification_permission_requested")
    }

    fun trackNotificationPermissionGranted() {
        logEvent("notification_permission_granted")
    }

    fun trackNotificationPermissionDenied() {
        logEvent("notification_permission_denied")
    }

    fun trackNotificationTimesSaved(
        breakfastHour: Int, breakfastMinute: Int,
        lunchHour: Int, lunchMinute: Int,
        dinnerHour: Int, dinnerMinute: Int
    ) {
        logEvent("notification_times_saved", mapOf(
            "breakfast_hour" to breakfastHour,
            "breakfast_minute" to breakfastMinute,
            "lunch_hour" to lunchHour,
            "lunch_minute" to lunchMinute,
            "dinner_hour" to dinnerHour,
            "dinner_minute" to dinnerMinute
        ))
    }

    fun trackNotificationsScheduled(
        breakfastHour: Int, breakfastMinute: Int,
        lunchHour: Int, lunchMinute: Int,
        dinnerHour: Int, dinnerMinute: Int
    ) {
        logEvent("notifications_scheduled", mapOf(
            "breakfast_hour" to breakfastHour,
            "breakfast_minute" to breakfastMinute,
            "lunch_hour" to lunchHour,
            "lunch_minute" to lunchMinute,
            "dinner_hour" to dinnerHour,
            "dinner_minute" to dinnerMinute
        ))
    }

    // --- WhatsApp Integration Events ---
    fun trackWhatsAppLinkingStarted() {
        logEvent("whatsapp_linking_started")
    }

    fun trackWhatsAppOpened() {
        logEvent("whatsapp_opened")
    }

    fun trackWhatsAppUnlinked() {
        logEvent("whatsapp_unlinked")
    }

    // --- Diet & Goal Configuration Events ---
    fun trackDietStyleHelperOpened() {
        logEvent("diet_style_helper_opened")
    }

    fun trackDietStyleHelperCompleted(recommendedStyle: String) {
        logEvent("diet_style_helper_completed", mapOf("recommended_style" to recommendedStyle))
    }

    fun trackDietStyleChanged(styleName: String) {
        logEvent("diet_style_changed", mapOf("style_name" to styleName))
    }

    // --- Feedback Events ---
    fun trackFeedbackSubmitted() {
        logEvent("feedback_submitted")
    }

    // --- Detailed Interactive Tap Tracking ---
    fun trackWhatsAppCloseTapped() { logEvent("whatsapp_close_tapped") }
    fun trackWhatsAppCheckStatusTapped() { logEvent("whatsapp_check_status_tapped") }
    fun trackWhatsAppLinkTapped() { logEvent("whatsapp_link_tapped") }
    fun trackWhatsAppOpenWATapped() { logEvent("whatsapp_open_wa_tapped") }
    fun trackWhatsAppUnlinkTapped() { logEvent("whatsapp_unlink_tapped") }
    fun trackCalorieDecrementTapped(currentGoal: Double) { logEvent("daily_goal_calories_decremented", mapOf("current_goal" to currentGoal)) }
    fun trackCalorieIncrementTapped(currentGoal: Double) { logEvent("daily_goal_calories_incremented", mapOf("current_goal" to currentGoal)) }
    fun trackDietStyleSelectionTapped(styleName: String) { logEvent("daily_goal_style_tapped", mapOf("style_name" to styleName)) }
    fun trackHelpMeChooseTapped() { logEvent("daily_goal_help_me_choose_tapped") }
    fun trackCustomMacroStepperTapped(macroName: String, newValue: Double) {
        logEvent("daily_goal_custom_macro_stepper_tapped", mapOf("macro_name" to macroName, "new_value" to newValue))
    }
    fun trackSaveGoalTapped() { logEvent("daily_goal_save_tapped") }
    fun trackDietStyleHelperCancelTapped() { logEvent("diet_style_helper_cancel_tapped") }
    fun trackDietStyleHelperBackTapped(currentStep: Int) { logEvent("diet_style_helper_back_tapped", mapOf("current_step" to currentStep)) }
    fun trackDietStyleHelperNextTapped(currentStep: Int) { logEvent("diet_style_helper_next_tapped", mapOf("current_step" to currentStep)) }
    fun trackDietStyleHelperOptionSelected(optionName: String) { logEvent("diet_style_helper_option_selected", mapOf("option_name" to optionName)) }
    fun trackDietStyleHelperRetakeTapped() { logEvent("diet_style_helper_retake_tapped") }

    // --- Profile Screen Events ---
    fun trackProfileSignInToSyncTapped() { logEvent("profile_sign_in_to_sync_tapped") }
    fun trackProfileEditProfileTapped() { logEvent("profile_edit_profile_tapped") }
    fun trackProfileDailyGoalTapped() { logEvent("profile_daily_goal_tapped") }
    fun trackProfileFavouriteMealsTapped() { logEvent("profile_favourite_meals_tapped") }
    fun trackProfileThemeTapped() { logEvent("profile_theme_tapped") }
    fun trackProfileMealRemindersTapped() { logEvent("profile_meal_reminders_tapped") }
    fun trackProfileLogWhatsAppTapped() { logEvent("profile_log_whatsapp_tapped") }
    fun trackProfileHelpFAQTapped() { logEvent("profile_help_faq_tapped") }
    fun trackProfileSendFeedbackTapped() { logEvent("profile_send_feedback_tapped") }

    // --- Error Logging ---
    fun trackError(throwable: Throwable, additionalInfo: Map<String, Any>? = null) {
        DebugLogger.e("DEBUG: [Crashlytics] Recorded non-fatal error: ${throwable.localizedMessage}", throwable)
        try {
            val crashlytics = FirebaseCrashlytics.getInstance()
            additionalInfo?.forEach { (key, value) ->
                crashlytics.setCustomKey(key, value.toString())
            }
            crashlytics.recordException(throwable)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [Crashlytics] Failed to log exception to Crashlytics", e)
        }
    }

    fun logMessage(message: String) {
        DebugLogger.d("DEBUG: [Crashlytics] Log: $message")
        try {
            FirebaseCrashlytics.getInstance().log(message)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [Crashlytics] Failed to log message to Crashlytics", e)
        }
    }

    // --- Private Helper ---
    private fun logEvent(name: String, parameters: Map<String, Any>? = null) {
        DebugLogger.d("DEBUG: [Analytics] Event: $name")
        parameters?.let { DebugLogger.d("DEBUG: [Analytics] Parameters: $it") }

        val bundle = Bundle().apply {
            parameters?.forEach { (key, value) ->
                when (value) {
                    is String -> putString(key, value)
                    is Int -> putInt(key, value)
                    is Long -> putLong(key, value)
                    is Double -> putDouble(key, value)
                    is Float -> putFloat(key, value)
                    is Boolean -> putBoolean(key, value)
                    else -> putString(key, value.toString())
                }
            }
        }
        firebaseAnalytics?.logEvent(name, bundle)
    }
}
