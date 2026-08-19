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

/// Represents an individual parsed food item shown on Apple Watch.
struct WatchParsedItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let quantity: String
    let calories: Double
}

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
    @Published var parsedItems: [WatchParsedItem] = []
    @Published var showConfirmation: Bool = false
    @Published var logSuccessMessage: String?
    
    private var currentRawJson: String? = nil
    private let connectivityManager = WatchConnectivityManager.shared
    
    /// Analyzes the dictated text and immediately auto-logs the meal, then displays the result with an update option.
    func analyzeAndAutoLogMeal(_ text: String) async {
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
                    self.currentRawJson = reply["rawResponseJson"] as? String
                    
                    // Parse individual items
                    if let rawItems = reply["items"] as? [[String: Any]] {
                        self.parsedItems = rawItems.compactMap { itemDict in
                            guard let name = itemDict["name"] as? String else { return nil }
                            let qty = itemDict["quantity"] as? String ?? "1 serving"
                            let itemCal = itemDict["calories"] as? Double ?? 0
                            return WatchParsedItem(name: name, quantity: qty, calories: itemCal)
                        }
                    } else if let stringItems = reply["items"] as? [String] {
                        self.parsedItems = stringItems.map { WatchParsedItem(name: $0, quantity: "1 serving", calories: cal / Double(max(stringItems.count, 1))) }
                    }
                    
                    self.showConfirmation = true
                    
                    // Immediately auto-commit
                    self.commitCurrentMeal()
                } else if let err = reply["error"] as? String {
                    self.errorMessage = err
                    WKInterfaceDevice.current().play(.failure)
                }
            } catch {
                await fallbackDirectEstimateAndCommit(for: trimmed)
            }
        } else {
            await fallbackDirectEstimateAndCommit(for: trimmed)
        }
        
        isLoading = false
    }
    
    /// Re-analyzes and updates the previously logged meal.
    func updateLoggedMeal(newText: String) async {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Revert previous meal from local watch totals
        if let prevCal = estimatedCalories {
            let prevP = estimatedProtein ?? 0
            let prevC = estimatedCarbs ?? 0
            let prevF = estimatedFat ?? 0
            connectivityManager.recordLocalLog(calories: -prevCal, p: -prevP, c: -prevC, f: -prevF)
        }
        
        await analyzeAndAutoLogMeal(trimmed)
    }
    
    /// Commits the estimated meal to the user's daily totals.
    private func commitCurrentMeal() {
        guard let cal = estimatedCalories else { return }
        
        let p = estimatedProtein ?? 0
        let c = estimatedCarbs ?? 0
        let f = estimatedFat ?? 0
        
        // 1. Update local Watch totals immediately
        connectivityManager.recordLocalLog(calories: cal, p: p, c: c, f: f)
        
        // 2. Play tactile success haptic
        WKInterfaceDevice.current().play(.success)
        
        // 3. Send log event to iPhone
        var payload: [String: Any] = [
            "action": "logMealDirect",
            "foodText": spokenText,
            "calories": cal,
            "protein": p,
            "carbs": c,
            "fat": f,
            "mealType": inferMealType(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let rawJson = currentRawJson, !rawJson.isEmpty {
            payload["rawResponseJson"] = rawJson
        }
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: { _ in
                print("DEBUG: iPhone acknowledged logMealDirect")
            }, errorHandler: { error in
                print("DEBUG: WCSession sendMessage error: \(error.localizedDescription), using transferUserInfo fallback")
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        
        logSuccessMessage = "\(Int(cal)) cal Logged!"
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
            WCSession.default.sendMessage(payload, replyHandler: { _ in
                print("DEBUG: iPhone acknowledged logSavedMeal")
            }, errorHandler: { error in
                print("DEBUG: WCSession logSavedMeal error: \(error.localizedDescription), using transferUserInfo fallback")
                WCSession.default.transferUserInfo(payload)
            })
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
        parsedItems = []
        currentRawJson = nil
        errorMessage = nil
    }
    
    private func fallbackDirectEstimateAndCommit(for text: String) async {
        // Simple heuristic fallback when offline from iPhone
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
        self.parsedItems = [WatchParsedItem(name: text, quantity: "1 serving", calories: cal)]
        self.showConfirmation = true
        self.commitCurrentMeal()
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
