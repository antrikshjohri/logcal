//
//  RatingService.swift
//  logcal
//
//  Created for iOS Rating Dialog integration
//

import Foundation
import StoreKit
import UIKit

class RatingService {
    static let shared = RatingService()
    
    private let userDefaults = UserDefaults.standard
    private let mealLogCountKey = "mealLogCount"
    private let lastRatingRequestKey = "lastRatingRequestDate"
    private let hasRatedKey = "hasRatedApp"
    private let ratingRequestCountKey = "ratingRequestCount"
    
    // Milestone meal logs when rating should be shown
    private let ratingMilestones: [Int] = [2, 5, 10]
    
    // Minimum days between rating requests (to avoid spamming)
    private let minDaysBetweenRequests = 1 // Allow at least 1 day between requests
    
    // Maximum rating requests (Apple's limit is 3 per year)
    private let maxRatingRequests = 3
    
    private init() {}
    
    /// Increment meal log count (call after successful meal log)
    func incrementMealLogCount() {
        let currentCount = userDefaults.integer(forKey: mealLogCountKey)
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: mealLogCountKey)
        print("DEBUG: [RatingService] Meal log count incremented to: \(newCount)")
    }
    
    /// Check if rating dialog should be shown for current meal log count
    func shouldShowRatingDialog() -> Bool {
        // Don't show if user already rated
        if userDefaults.bool(forKey: hasRatedKey) {
            print("DEBUG: [RatingService] User has already rated, skipping")
            return false
        }
        
        // Check if we've exceeded max requests
        let requestCount = userDefaults.integer(forKey: ratingRequestCountKey)
        if requestCount >= maxRatingRequests {
            print("DEBUG: [RatingService] Maximum rating requests (\(maxRatingRequests)) reached, skipping")
            return false
        }
        
        // Get current meal log count
        let mealLogCount = userDefaults.integer(forKey: mealLogCountKey)
        
        // Check if current count is a milestone
        guard ratingMilestones.contains(mealLogCount) else {
            return false
        }
        
        // Check time since last request (if any)
        if let lastRequestDate = userDefaults.object(forKey: lastRatingRequestKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            if daysSince < minDaysBetweenRequests {
                print("DEBUG: [RatingService] Too soon since last request (\(daysSince) days), skipping")
                return false
            }
        }
        
        print("DEBUG: [RatingService] Should show rating dialog - meal log count: \(mealLogCount), milestone reached")
        return true
    }
    
    /// Request app rating (call when conditions are met)
    func requestRating() {
        guard shouldShowRatingDialog() else {
            print("DEBUG: [RatingService] Conditions not met for rating dialog")
            return
        }
        
        // Update tracking
        userDefaults.set(Date(), forKey: lastRatingRequestKey)
        let requestCount = userDefaults.integer(forKey: ratingRequestCountKey)
        userDefaults.set(requestCount + 1, forKey: ratingRequestCountKey)
        
        let mealLogCount = userDefaults.integer(forKey: mealLogCountKey)
        print("DEBUG: [RatingService] Requesting rating dialog - meal log count: \(mealLogCount), request count: \(requestCount + 1)")
        
        // Request review (only works on real devices, not simulator)
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                print("DEBUG: [RatingService] Rating dialog requested")
            } else {
                print("DEBUG: [RatingService] Could not get window scene for rating dialog")
            }
        }
    }
    
    /// Mark that user has rated (call if you detect they rated)
    func markAsRated() {
        userDefaults.set(true, forKey: hasRatedKey)
        print("DEBUG: [RatingService] User marked as having rated the app")
    }
    
    /// Get current meal log count (for debugging)
    func getMealLogCount() -> Int {
        return userDefaults.integer(forKey: mealLogCountKey)
    }
    
    /// Reset for testing (remove in production or make conditional)
    func resetForTesting() {
        userDefaults.removeObject(forKey: mealLogCountKey)
        userDefaults.removeObject(forKey: lastRatingRequestKey)
        userDefaults.removeObject(forKey: hasRatedKey)
        userDefaults.removeObject(forKey: ratingRequestCountKey)
        print("DEBUG: [RatingService] Rating state reset for testing")
    }
}
