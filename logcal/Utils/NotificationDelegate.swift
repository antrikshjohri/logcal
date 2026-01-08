//
//  NotificationDelegate.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    override init() {
        super.init()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let action = userInfo["action"] as? String, action == "openLog" {
            print("DEBUG: [NotificationDelegate] Opening Log tab from notification")
            // Post notification to trigger navigation
            NotificationCenter.default.post(name: NSNotification.Name("OpenLogTab"), object: nil)
            AnalyticsService.trackNotificationTapped(notificationType: "meal_reminder")
        }
        
        completionHandler()
    }
}
