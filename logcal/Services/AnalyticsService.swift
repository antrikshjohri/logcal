//
//  AnalyticsService.swift
//  logcal
//
//  Created for analytics tracking
//

import Foundation
import FirebaseAnalytics

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
    
    /// Track meal detail viewed
    static func trackMealDetailViewed() {
        logEvent("meal_detail_viewed", parameters: nil)
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

