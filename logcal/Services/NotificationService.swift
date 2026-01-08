//
//  NotificationService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    // Notification identifiers
    private enum NotificationIdentifier {
        static let breakfast = "meal_reminder_breakfast"
        static let lunch = "meal_reminder_lunch"
        static let dinner = "meal_reminder_dinner"
    }
    
    // Notification times (in user's local timezone)
    private enum NotificationTimes {
        static let breakfast = (hour: 8, minute: 0)   // 8:00 AM
        static let lunch = (hour: 13, minute: 0)      // 1:00 PM
        static let dinner = (hour: 20, minute: 0)     // 8:00 PM
    }
    
    private init() {}
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        print("DEBUG: [NotificationService] Requesting notification authorization")
        AnalyticsService.trackNotificationPermissionRequested()
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("DEBUG: [NotificationService] Notification authorization granted: \(granted)")
            if granted {
                AnalyticsService.trackNotificationPermissionGranted()
            } else {
                AnalyticsService.trackNotificationPermissionDenied()
            }
            return granted
        } catch {
            print("DEBUG: [NotificationService] Error requesting notification authorization: \(error)")
            AnalyticsService.trackNotificationPermissionDenied()
            return false
        }
    }
    
    /// Check if notifications are authorized
    func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    /// Schedule all meal reminder notifications
    func scheduleMealReminders(modelContext: ModelContext) async {
        print("DEBUG: [NotificationService] ===== Scheduling meal reminders =====")
        
        // Check authorization first
        let isAuthorized = await checkAuthorizationStatus()
        print("DEBUG: [NotificationService] Authorization status: \(isAuthorized)")
        if !isAuthorized {
            print("DEBUG: [NotificationService] Notifications not authorized, requesting...")
            let granted = await requestAuthorization()
            if !granted {
                print("DEBUG: [NotificationService] ❌ Notification permission denied - cannot schedule")
                return
            }
            print("DEBUG: [NotificationService] ✅ Notification permission granted")
        }
        
        // Cancel existing notifications first
        cancelAllMealReminders()
        
        // Schedule breakfast reminder
        await scheduleMealReminder(
            mealType: .breakfast,
            hour: NotificationTimes.breakfast.hour,
            minute: NotificationTimes.breakfast.minute,
            identifier: NotificationIdentifier.breakfast,
            modelContext: modelContext
        )
        
        // Schedule lunch reminder
        await scheduleMealReminder(
            mealType: .lunch,
            hour: NotificationTimes.lunch.hour,
            minute: NotificationTimes.lunch.minute,
            identifier: NotificationIdentifier.lunch,
            modelContext: modelContext
        )
        
        // Schedule dinner reminder
        await scheduleMealReminder(
            mealType: .dinner,
            hour: NotificationTimes.dinner.hour,
            minute: NotificationTimes.dinner.minute,
            identifier: NotificationIdentifier.dinner,
            modelContext: modelContext
        )
        
        print("DEBUG: [NotificationService] All meal reminders scheduled")
        
        // Debug: List all pending notifications
        await listPendingNotifications()
    }
    
    /// Debug helper: List all pending notifications
    func listPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("DEBUG: [NotificationService] Total pending notifications: \(requests.count)")
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                let dateComponents = trigger.dateComponents
                print("DEBUG: [NotificationService] - \(request.identifier): \(request.content.body) at \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0) on \(dateComponents.day ?? 0)/\(dateComponents.month ?? 0)")
            } else {
                print("DEBUG: [NotificationService] - \(request.identifier): \(request.content.body) (trigger: \(String(describing: request.trigger)))")
            }
        }
    }
    
    /// Schedule a single meal reminder notification
    private func scheduleMealReminder(
        mealType: MealType,
        hour: Int,
        minute: Int,
        identifier: String,
        modelContext: ModelContext
    ) async {
        // Check if we should send this notification
        let shouldSend = await shouldSendNotification(for: mealType, modelContext: modelContext)
        print("DEBUG: [NotificationService] Should send \(mealType.rawValue) reminder: \(shouldSend)")
        
        if !shouldSend {
            print("DEBUG: [NotificationService] ⏭️ Skipping \(mealType.rawValue) reminder - meal already logged or recent activity")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Meal Reminder"
        content.body = getNotificationBody(for: mealType)
        content.sound = .default
        content.categoryIdentifier = "MEAL_REMINDER"
        content.userInfo = [
            "mealType": mealType.rawValue,
            "action": "openLog"
        ]
        
        // Schedule for today at specified time
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        guard let scheduledDate = calendar.date(from: dateComponents) else {
            print("DEBUG: [NotificationService] Failed to create date for \(mealType.rawValue)")
            return
        }
        
        // If the time has already passed today, schedule for tomorrow
        let finalDate = scheduledDate > Date() ? scheduledDate : calendar.date(byAdding: .day, value: 1, to: scheduledDate) ?? scheduledDate
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("DEBUG: [NotificationService] ✅ Scheduled \(mealType.rawValue) reminder for \(formatter.string(from: finalDate))")
            print("DEBUG: [NotificationService]    Trigger date components: \(triggerDate)")
        } catch {
            print("DEBUG: [NotificationService] ❌ Error scheduling \(mealType.rawValue) reminder: \(error)")
        }
    }
    
    /// Check if notification should be sent (smart logic)
    private func shouldSendNotification(for mealType: MealType, modelContext: ModelContext) async -> Bool {
        // Check 1: Has user logged this specific meal type today?
        let hasLoggedMealType = await hasLoggedMealType(mealType, today: Date(), modelContext: modelContext)
        if hasLoggedMealType {
            print("DEBUG: [NotificationService] User already logged \(mealType.rawValue) today")
            return false
        }
        
        // Check 2: Has user logged anything in the last 2 hours?
        let hasRecentActivity = await hasRecentMealActivity(withinHours: 2, modelContext: modelContext)
        if hasRecentActivity {
            print("DEBUG: [NotificationService] User logged a meal in last 2 hours")
            return false
        }
        
        return true
    }
    
    /// Check if user has logged a specific meal type today
    private func hasLoggedMealType(_ mealType: MealType, today: Date, modelContext: ModelContext) async -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let mealTypeString = mealType.rawValue
        
        let predicate = #Predicate<MealEntry> { entry in
            entry.timestamp >= startOfDay &&
            entry.timestamp < endOfDay &&
            entry.mealType == mealTypeString
        }
        
        let descriptor = FetchDescriptor<MealEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return !entries.isEmpty
        } catch {
            print("DEBUG: [NotificationService] Error checking meal type: \(error)")
            return false
        }
    }
    
    /// Check if user has logged any meal within specified hours
    private func hasRecentMealActivity(withinHours: Int, modelContext: ModelContext) async -> Bool {
        let cutoffTime = Date().addingTimeInterval(-Double(withinHours * 60 * 60))
        
        let predicate = #Predicate<MealEntry> { entry in
            entry.timestamp >= cutoffTime
        }
        
        let descriptor = FetchDescriptor<MealEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return !entries.isEmpty
        } catch {
            print("DEBUG: [NotificationService] Error checking recent activity: \(error)")
            return false
        }
    }
    
    /// Get notification body text for meal type
    private func getNotificationBody(for mealType: MealType) -> String {
        switch mealType {
        case .breakfast:
            return "Time for breakfast! Log your meal to track your calories"
        case .lunch:
            return "Lunch time! Don't forget to log your meal"
        case .dinner:
            return "Dinner time! Log your meal to stay on track"
        case .snack:
            return "Time to log your snack!"
        }
    }
    
    /// Cancel all meal reminder notifications
    func cancelAllMealReminders() {
        let identifiers = [
            NotificationIdentifier.breakfast,
            NotificationIdentifier.lunch,
            NotificationIdentifier.dinner
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("DEBUG: [NotificationService] Cancelled all meal reminders")
    }
    
    /// Reschedule notifications (call after meal is logged)
    func rescheduleNotificationsIfNeeded(modelContext: ModelContext) async {
        // Re-check and reschedule if needed
        await scheduleMealReminders(modelContext: modelContext)
    }
}
