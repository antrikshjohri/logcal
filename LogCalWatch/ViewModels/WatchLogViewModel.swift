//
//  WatchLogViewModel.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI
import WatchConnectivity
import WatchKit
import Combine

/// Manages voice input, AI estimation, and meal logging workflows on Apple Watch.
@MainActor
final class WatchLogViewModel: ObservableObject {
    @Published var spokenText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var estimatedCalories: Double?
    @Published var estimatedProtein: Double?
    @Published var estimatedCarbs: Double?
    @Published var estimatedFat: Double?
    @Published var estimatedItems: [String] = []
    @Published var showConfirmation: Bool = false
    @Published var logSuccessMessage: String?
    
    private let connectivityManager = WatchConnectivityManager.shared
    
    /// Analyzes the dictated text by sending a request via WatchConnectivity or direct backend fallback.
    func analyzeSpokenMeal(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        spokenText = trimmed
        isLoading = true
        errorMessage = nil
        
        // If iPhone is reachable via WCSession, request analysis through iPhone
        if WCSession.default.isReachable {
            do {
                let reply = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any], Error>) in
                    WCSession.default.sendMessage(
                        ["action": "analyzeMeal", "text": trimmed],
                        replyHandler: { reply in
                            continuation.resume(returning: reply)
                        },
                        errorHandler: { error in
                            continuation.resume(throwing: error)
                        }
                    )
                }
                
                if let cal = reply["totalCalories"] as? Double {
                    self.estimatedCalories = cal
                    self.estimatedProtein = reply["protein"] as? Double ?? 0
                    self.estimatedCarbs = reply["carbs"] as? Double ?? 0
                    self.estimatedFat = reply["fat"] as? Double ?? 0
                    self.estimatedItems = reply["items"] as? [String] ?? []
                    self.showConfirmation = true
                    WKInterfaceDevice.current().play(.click)
                } else if let err = reply["error"] as? String {
                    self.errorMessage = err
                    WKInterfaceDevice.current().play(.failure)
                }
            } catch {
                await fallbackDirectEstimate(for: trimmed)
            }
        } else {
            await fallbackDirectEstimate(for: trimmed)
        }
        
        isLoading = false
    }
    
    /// Commits the estimated meal to the user's daily totals.
    func confirmAndLogMeal() {
        guard let cal = estimatedCalories else { return }
        
        let p = estimatedProtein ?? 0
        let c = estimatedCarbs ?? 0
        let f = estimatedFat ?? 0
        
        // 1. Update local Watch totals immediately
        connectivityManager.recordLocalLog(calories: cal, p: p, c: c, f: f)
        
        // 2. Play tactile success haptic
        WKInterfaceDevice.current().play(.success)
        
        // 3. Send log event to iPhone
        let payload: [String: Any] = [
            "action": "logMealDirect",
            "foodText": spokenText,
            "calories": cal,
            "protein": p,
            "carbs": c,
            "fat": f,
            "mealType": inferMealType(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        
        // 4. Show success toast and reset state
        logSuccessMessage = "\(Int(cal)) cal Logged!"
        showConfirmation = false
        resetInput()
    }
    
    /// 1-Tap Quick-Log for a saved favourite meal directly from the wrist.
    func quickLogSavedMeal(_ meal: WatchSavedMeal) {
        connectivityManager.recordLocalLog(
            calories: meal.totalCalories,
            p: meal.protein,
            c: meal.carbs,
            f: meal.fat
        )
        
        WKInterfaceDevice.current().play(.success)
        
        let payload: [String: Any] = [
            "action": "logSavedMeal",
            "savedMealId": meal.id,
            "title": meal.title,
            "calories": meal.totalCalories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fat": meal.fat,
            "mealType": meal.mealType,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        
        logSuccessMessage = "\(meal.title) Logged!"
    }
    
    func resetInput() {
        spokenText = ""
        estimatedCalories = nil
        estimatedProtein = nil
        estimatedCarbs = nil
        estimatedFat = nil
        estimatedItems = []
        errorMessage = nil
    }
    
    private func fallbackDirectEstimate(for text: String) async {
        // Simple heuristic fallback when offline from iPhone
        // In full connectivity, iPhone WCSession or Firebase handles LLM estimation
        let words = text.lowercased()
        var cal: Double = 250
        var p: Double = 10
        var c: Double = 30
        var f: Double = 8
        
        if words.contains("egg") { cal = 150; p = 12; c = 2; f = 10 }
        else if words.contains("salad") { cal = 180; p = 5; c = 15; f = 8 }
        else if words.contains("coffee") || words.contains("tea") { cal = 35; p = 1; c = 4; f = 1 }
        else if words.contains("chicken") || words.contains("rice") { cal = 450; p = 35; c = 45; f = 10 }
        else if words.contains("toast") || words.contains("bread") { cal = 200; p = 6; c = 35; f = 4 }
        
        self.estimatedCalories = cal
        self.estimatedProtein = p
        self.estimatedCarbs = c
        self.estimatedFat = f
        self.estimatedItems = [text]
        self.showConfirmation = true
        WKInterfaceDevice.current().play(.click)
    }
    
    private func inferMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "breakfast"
        case 11..<16: return "lunch"
        case 16..<22: return "dinner"
        default: return "snack"
        }
    }
}
