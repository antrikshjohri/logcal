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

