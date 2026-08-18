//
//  WatchSyncService.swift
//  logcal
//
//  Created by Antriksh Johri on 17/08/26.
//

import Foundation
import WatchConnectivity
import Combine
import SwiftData
import FirebaseAuth

/// Manages bidirectional synchronization between the iPhone app and the Apple Watch companion app.
@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()
    
    @Published var isWatchAppInstalled: Bool = false
    @Published var isPaired: Bool = false
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    /// Pushes the latest summary data (calories, macros, goals, favourites) to the Apple Watch.
    func syncToWatch(
        todayCalories: Double,
        dailyGoal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        savedMeals: [SavedMeal]
    ) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        let simplifiedSavedMeals: [[String: Any]] = savedMeals.prefix(8).map { meal in
            return [
                "id": meal.id.uuidString,
                "title": meal.title,
                "totalCalories": meal.totalCalories,
                "mealType": meal.mealType,
                "protein": meal.protein ?? 0,
                "carbs": meal.carbs ?? 0,
                "fat": meal.fat ?? 0
            ]
        }
        
        var payload: [String: Any] = [
            "todayCalories": todayCalories,
            "dailyGoal": dailyGoal,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "fiber": fiber,
            "savedMeals": simplifiedSavedMeals,
            "updatedAt": Date().timeIntervalSince1970
        ]
        
        if let user = Auth.auth().currentUser {
            payload["userId"] = user.uid
        }
        
        do {
            try session.updateApplicationContext(payload)
        } catch {
            print("WatchSyncService: Error updating application context: \(error.localizedDescription)")
            // Fallback to transferUserInfo if context is unchanged
            session.transferUserInfo(payload)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            let action = message["action"] as? String ?? ""
            
            switch action {
            case "requestSync":
                let defaults = UserDefaults(suiteName: "group.com.serene.logcal") ?? .standard
                let goal = defaults.double(forKey: "dailyCalorieGoal")
                let actualGoal = goal > 0 ? goal : 2000.0
                
                replyHandler([
                    "status": "ok",
                    "dailyGoal": actualGoal
                ])
                
            case "analyzeMeal":
                guard let text = message["text"] as? String, !text.isEmpty else {
                    replyHandler(["status": "error", "error": "Empty meal text"])
                    return
                }
                
                do {
                    let response = try await FirebaseService().logMeal(foodText: text, mealType: "meal", imageData: nil)
                    replyHandler([
                        "status": "success",
                        "totalCalories": response.totalCalories,
                        "protein": response.protein ?? 0,
                        "carbs": response.carbs ?? 0,
                        "fat": response.fat ?? 0,
                        "items": response.items.map(\.name)
                    ])
                } catch {
                    replyHandler(["status": "error", "error": error.localizedDescription])
                }
                
            case "logMealDirect":
                if let context = self.modelContext {
                    let text = message["foodText"] as? String ?? "Meal from Apple Watch"
                    let calories = message["calories"] as? Double ?? 0
                    let protein = message["protein"] as? Double ?? 0
                    let carbs = message["carbs"] as? Double ?? 0
                    let fat = message["fat"] as? Double ?? 0
                    let mealType = message["mealType"] as? String ?? "snack"
                    let timestamp = message["timestamp"] as? Double ?? Date().timeIntervalSince1970
                    
                    let dummyItem = MealItem(
                        name: text,
                        quantity: "1 serving",
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        fiber: nil,
                        assumptions: nil,
                        confidence: 1.0
                    )
                    let logResponse = MealLogResponse(
                        mealType: mealType,
                        totalCalories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        items: [dummyItem],
                        needsClarification: false,
                        clarifyingQuestion: nil,
                        sources: []
                    )
                    let rawJson = (try? String(data: JSONEncoder().encode(logResponse), encoding: .utf8)) ?? "{}"
                    
                    let entry = MealEntry(
                        id: UUID(),
                        timestamp: Date(timeIntervalSince1970: timestamp),
                        createdAt: Date(),
                        foodText: text,
                        mealType: mealType,
                        totalCalories: calories,
                        rawResponseJson: rawJson,
                        hasImage: false
                    )
                    
                    context.insert(entry)
                    try? context.save()
                    Task {
                        await CloudSyncService().syncMealToCloud(entry)
                    }
                }
                replyHandler(["status": "logged"])
                
            default:
                replyHandler(["status": "received"])
            }
        }
    }
}
