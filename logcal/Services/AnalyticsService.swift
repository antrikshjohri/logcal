//
//  AnalyticsService.swift
//  logcal
//
//  Created for analytics tracking
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

/// Centralized service for tracking analytics events
struct AnalyticsService {
    
    // MARK: - Authentication Events
    
    /// Track user sign up
    static func trackSignUp(method: String) {
        logEvent("user_signup", parameters: [
            "method": method
        ])
    }
    
    /// Track user login
    static func trackLogin(method: String) {
        logEvent("user_login", parameters: [
            "method": method
        ])
    }
    
    /// Track user logout
    static func trackLogout() {
        logEvent("user_logout", parameters: nil)
    }
    
    /// Track account deletion
    static func trackAccountDeleted() {
        logEvent("account_deleted", parameters: nil)
    }
    
    // MARK: - Meal Logging Events
    
    /// Track successful meal log
    static func trackMealLogged(mealType: String, totalCalories: Double, itemCount: Int, hasImage: Bool = false) {
        logEvent("meal_logged", parameters: [
            "meal_type": mealType,
            "total_calories": totalCalories,
            "item_count": itemCount,
            "has_image": hasImage
        ])
    }
    
    /// Track failed meal log
    static func trackMealLogFailed(errorType: String) {
        logEvent("meal_log_failed", parameters: [
            "error_type": errorType
        ])
        logMessage("Meal log failed with error: \(errorType)")
    }
    
    /// Track meal edit
    static func trackMealEdited() {
        logEvent("meal_edited", parameters: nil)
    }
    
    /// Track meal deletion
    static func trackMealDeleted() {
        logEvent("meal_deleted", parameters: nil)
    }
    
    // MARK: - Navigation Events
    
    /// Track tab change
    static func trackTabChanged(tabName: String) {
        logEvent("tab_changed", parameters: [
            "tab_name": tabName
        ])
    }
    
    /// Track view opened
    static func trackViewOpened(viewName: String) {
        logEvent("view_opened", parameters: [
            "view_name": viewName
        ])
    }
    
    // MARK: - Feature Usage Events
    
    /// Track speech recognition started
    static func trackSpeechRecognitionStarted() {
        logEvent("speech_recognition_started", parameters: nil)
    }
    
    /// Track speech recognition stopped
    static func trackSpeechRecognitionStopped() {
        logEvent("speech_recognition_stopped", parameters: nil)
    }
    
    /// Track date picker opened
    static func trackDatePickerOpened() {
        logEvent("date_picker_opened", parameters: nil)
    }
    
    /// Track meal type changed
    static func trackMealTypeChanged(mealType: String) {
        logEvent("meal_type_changed", parameters: [
            "meal_type": mealType
        ])
    }
    
    /// Track daily goal changed
    static func trackDailyGoalChanged(newGoal: Double) {
        logEvent("daily_goal_changed", parameters: [
            "new_goal": newGoal
        ])
    }
    
    /// Track image picker opened (gallery)
    static func trackImagePickerOpened() {
        logEvent("image_picker_opened", parameters: nil)
    }
    
    /// Track camera picker opened
    static func trackCameraPickerOpened() {
        logEvent("camera_picker_opened", parameters: nil)
    }
    
    /// Track image selected
    static func trackImageSelected() {
        logEvent("image_selected", parameters: nil)
    }
    
    /// Track image removed
    static func trackImageRemoved() {
        logEvent("image_removed", parameters: nil)
    }
    
    // MARK: - User Engagement Events
    
    /// Track meal summary viewed
    static func trackMealSummaryViewed() {
        logEvent("meal_summary_viewed", parameters: nil)
    }
    
    /// Track help/FAQ opened
    static func trackHelpFAQOpened() {
        logEvent("help_faq_opened", parameters: nil)
    }
    
    /// Track theme changed
    static func trackThemeChanged(themeName: String) {
        logEvent("theme_changed", parameters: [
            "theme_name": themeName
        ])
    }
    
    // MARK: - Notification Events
    
    /// Track notification preference changed
    static func trackNotificationPreferenceChanged(mealRemindersEnabled: Bool) {
        logEvent("notification_preference_changed", parameters: [
            "meal_reminders_enabled": mealRemindersEnabled
        ])
    }
    
    /// Track notification tapped
    static func trackNotificationTapped(notificationType: String) {
        logEvent("notification_tapped", parameters: [
            "notification_type": notificationType
        ])
    }
    
    /// Track notification permission requested
    static func trackNotificationPermissionRequested() {
        logEvent("notification_permission_requested", parameters: nil)
    }
    
    /// Track notification permission granted
    static func trackNotificationPermissionGranted() {
        logEvent("notification_permission_granted", parameters: nil)
    }
    
    /// Track notification permission denied
    static func trackNotificationPermissionDenied() {
        logEvent("notification_permission_denied", parameters: nil)
    }
    
    /// Track notification times saved
    static func trackNotificationTimesSaved(breakfastHour: Int, breakfastMinute: Int, lunchHour: Int, lunchMinute: Int, dinnerHour: Int, dinnerMinute: Int) {
        logEvent("notification_times_saved", parameters: [
            "breakfast_hour": breakfastHour,
            "breakfast_minute": breakfastMinute,
            "lunch_hour": lunchHour,
            "lunch_minute": lunchMinute,
            "dinner_hour": dinnerHour,
            "dinner_minute": dinnerMinute
        ])
    }
    
    /// Track notifications scheduled
    static func trackNotificationsScheduled(breakfastHour: Int, breakfastMinute: Int, lunchHour: Int, lunchMinute: Int, dinnerHour: Int, dinnerMinute: Int) {
        logEvent("notifications_scheduled", parameters: [
            "breakfast_hour": breakfastHour,
            "breakfast_minute": breakfastMinute,
            "lunch_hour": lunchHour,
            "lunch_minute": lunchMinute,
            "dinner_hour": dinnerHour,
            "dinner_minute": dinnerMinute
        ])
    }
    
    // MARK: - Error Logging (Crashlytics)
    
    /// Record a non-fatal error in Crashlytics
    static func trackError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        let crashlytics = Crashlytics.crashlytics()
        
        if let additionalInfo = additionalInfo {
            for (key, value) in additionalInfo {
                crashlytics.setCustomValue(value, forKey: key)
            }
        }
        
        crashlytics.record(error: error)
        
        #if DEBUG
        print("DEBUG: [Crashlytics] Recorded non-fatal error: \(error.localizedDescription)")
        if let info = additionalInfo {
            print("DEBUG: [Crashlytics] Additional Info: \(info)")
        }
        #endif
    }
    
    /// Write custom log message to Crashlytics
    static func logMessage(_ message: String) {
        Crashlytics.crashlytics().log(message)
        
        #if DEBUG
        print("DEBUG: [Crashlytics] Log: \(message)")
        #endif
    }
    
    // MARK: - WhatsApp Integration Events
    
    /// Track when user starts the WhatsApp linking flow (generates code)
    static func trackWhatsAppLinkingStarted() {
        logEvent("whatsapp_linking_started", parameters: nil)
    }
    
    /// Track when user deep links to WhatsApp
    static func trackWhatsAppOpened() {
        logEvent("whatsapp_opened", parameters: nil)
    }
    
    /// Track when user unlinks their WhatsApp account
    static func trackWhatsAppUnlinked() {
        logEvent("whatsapp_unlinked", parameters: nil)
    }
    
    // MARK: - Diet & Goal Configuration Events
    
    /// Track when user opens the Diet Style Helper onboarding flow
    static func trackDietStyleHelperOpened() {
        logEvent("diet_style_helper_opened", parameters: nil)
    }
    
    /// Track when user completes the Diet Style Helper and selects a style
    static func trackDietStyleHelperCompleted(recommendedStyle: String) {
        logEvent("diet_style_helper_completed", parameters: [
            "recommended_style": recommendedStyle
        ])
    }
    
    /// Track when user changes their target diet style
    static func trackDietStyleChanged(styleName: String) {
        logEvent("diet_style_changed", parameters: [
            "style_name": styleName
        ])
    }
    
    // MARK: - Feedback Events
    
    /// Track when user successfully submits app feedback
    static func trackFeedbackSubmitted() {
        logEvent("feedback_submitted", parameters: nil)
    }
    
    // MARK: - Detailed Interactive Tap Tracking (100% Coverage)
    
    /// Track user tapping "Close" on the WhatsApp linking view
    static func trackWhatsAppCloseTapped() {
        logEvent("whatsapp_close_tapped", parameters: nil)
    }
    
    /// Track user tapping "Check Linkage Status"
    static func trackWhatsAppCheckStatusTapped() {
        logEvent("whatsapp_check_status_tapped", parameters: nil)
    }
    
    /// Track user tapping "Link with WhatsApp"
    static func trackWhatsAppLinkTapped() {
        logEvent("whatsapp_link_tapped", parameters: nil)
    }
    
    /// Track user tapping "Open WhatsApp to Link"
    static func trackWhatsAppOpenWATapped() {
        logEvent("whatsapp_open_wa_tapped", parameters: nil)
    }
    
    /// Track user tapping "Unlink Account"
    static func trackWhatsAppUnlinkTapped() {
        logEvent("whatsapp_unlink_tapped", parameters: nil)
    }
    
    /// Track user tapping the minus button to decrement calorie goal
    static func trackCalorieDecrementTapped(currentGoal: Double) {
        logEvent("daily_goal_calories_decremented", parameters: ["current_goal": currentGoal])
    }
    
    /// Track user tapping the plus button to increment calorie goal
    static func trackCalorieIncrementTapped(currentGoal: Double) {
        logEvent("daily_goal_calories_incremented", parameters: ["current_goal": currentGoal])
    }
    
    /// Track user tapping a diet style macro split option
    static func trackDietStyleSelectionTapped(styleName: String) {
        logEvent("daily_goal_style_tapped", parameters: ["style_name": styleName])
    }
    
    /// Track user tapping "Help Me Choose"
    static func trackHelpMeChooseTapped() {
        logEvent("daily_goal_help_me_choose_tapped", parameters: nil)
    }
    
    /// Track user stepping macros in Custom split mode
    static func trackCustomMacroStepperTapped(macroName: String, newValue: Double) {
        logEvent("daily_goal_custom_macro_stepper_tapped", parameters: [
            "macro_name": macroName,
            "new_value": newValue
        ])
    }
    
    /// Track user tapping "Save Goal"
    static func trackSaveGoalTapped() {
        logEvent("daily_goal_save_tapped", parameters: nil)
    }
    
    /// Track user tapping "Cancel" on the Diet Style Helper
    static func trackDietStyleHelperCancelTapped() {
        logEvent("diet_style_helper_cancel_tapped", parameters: nil)
    }
    
    /// Track user tapping "Back" in the Diet Style Helper steps
    static func trackDietStyleHelperBackTapped(currentStep: Int) {
        logEvent("diet_style_helper_back_tapped", parameters: ["current_step": currentStep])
    }
    
    /// Track user tapping "Next" in the Diet Style Helper steps
    static func trackDietStyleHelperNextTapped(currentStep: Int) {
        logEvent("diet_style_helper_next_tapped", parameters: ["current_step": currentStep])
    }
    
    /// Track user selecting an option row in the Diet Style Helper questionnaire
    static func trackDietStyleHelperOptionSelected(optionName: String) {
        logEvent("diet_style_helper_option_selected", parameters: ["option_name": optionName])
    }
    
    /// Track user tapping "Retake Questionnaire" in the Diet Style Helper
    static func trackDietStyleHelperRetakeTapped() {
        logEvent("diet_style_helper_retake_tapped", parameters: nil)
    }
    
    // MARK: - Profile Screen Events
    
    /// Track user tapping "Sign In to Sync" on the guest banner
    static func trackProfileSignInToSyncTapped() {
        logEvent("profile_sign_in_to_sync_tapped", parameters: nil)
    }
    
    /// Track user tapping "Edit Profile" on the profile card
    static func trackProfileEditProfileTapped() {
        logEvent("profile_edit_profile_tapped", parameters: nil)
    }
    
    /// Track user tapping "Daily Goal" settings row
    static func trackProfileDailyGoalTapped() {
        logEvent("profile_daily_goal_tapped", parameters: nil)
    }
    
    /// Track user tapping "Favourite Meals" settings row
    static func trackProfileFavouriteMealsTapped() {
        logEvent("profile_favourite_meals_tapped", parameters: nil)
    }
    
    /// Track user tapping "Theme" settings row
    static func trackProfileThemeTapped() {
        logEvent("profile_theme_tapped", parameters: nil)
    }
    
    /// Track user tapping "Meal Reminders" settings row
    static func trackProfileMealRemindersTapped() {
        logEvent("profile_meal_reminders_tapped", parameters: nil)
    }
    
    /// Track user tapping "Log using WhatsApp" settings row
    static func trackProfileLogWhatsAppTapped() {
        logEvent("profile_log_whatsapp_tapped", parameters: nil)
    }
    
    /// Track user tapping "Help & FAQ" settings row
    static func trackProfileHelpFAQTapped() {
        logEvent("profile_help_faq_tapped", parameters: nil)
    }
    
    /// Track user tapping "Send Feedback" settings row
    static func trackProfileSendFeedbackTapped() {
        logEvent("profile_send_feedback_tapped", parameters: nil)
    }
    
    // MARK: - Deep Link Events
    
    /// Track when app is opened via deep link
    static func trackDeepLinkOpened(host: String, action: String?) {
        var params: [String: Any] = ["host": host]
        if let action = action {
            params["action"] = action
        }
        logEvent("deep_link_opened", parameters: params)
    }
    
    // MARK: - Private Helper
    
    /// Internal method to log events with Firebase Analytics
    private static func logEvent(_ name: String, parameters: [String: Any]?) {
        #if DEBUG
        print("DEBUG: [Analytics] Event: \(name)")
        if let params = parameters {
            print("DEBUG: [Analytics] Parameters: \(params)")
        }
        #endif
        
        // Log to Firebase Analytics
        Analytics.logEvent(name, parameters: parameters)
    }
}

