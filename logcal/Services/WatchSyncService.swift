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
        print("DEBUG: WatchSyncService modelContext configured")
        syncInitialState()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    /// Queries the latest state (daily goals, today's calories/macros, active favourites) and constructs a complete sync dictionary.
    func buildFullSyncPayload() -> [String: Any] {
        let defaults = UserDefaults(suiteName: "group.com.serene.logcal") ?? .standard
        let goal = defaults.double(forKey: "dailyCalorieGoal")
        let actualGoal = goal > 0 ? goal : 2000.0
        
        var simplifiedSavedMeals: [[String: Any]] = []
        var todayCalories: Double = 0
        var todayProtein: Double = 0
        var todayCarbs: Double = 0
        var todayFat: Double = 0
        var todayFiber: Double = 0
        
        if let context = self.modelContext {
            // 1. Fetch Favourites
            let savedDescriptor = FetchDescriptor<SavedMeal>(
                sortBy: [SortDescriptor(\SavedMeal.displayOrder, order: .forward)]
            )
            if let fetched = try? context.fetch(savedDescriptor) {
                simplifiedSavedMeals = fetched.map { meal in
                    let p: Double = meal.protein ?? 0.0
                    let c: Double = meal.carbs ?? 0.0
                    let f: Double = meal.fat ?? 0.0
                    return [
                        "id": meal.id.uuidString,
                        "title": meal.title,
                        "totalCalories": meal.totalCalories,
                        "mealType": meal.mealType,
                        "protein": p,
                        "carbs": c,
                        "fat": f
                    ]
                }
            }
            
            // 2. Fetch Today's Meals
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            let mealDescriptor = FetchDescriptor<MealEntry>(
                predicate: #Predicate<MealEntry> { !$0.deleted && $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
            )
            if let todayEntries = try? context.fetch(mealDescriptor) {
                for entry in todayEntries {
                    todayCalories += entry.totalCalories
                    if let resp = entry.response {
                        todayProtein += resp.protein ?? 0.0
                        todayCarbs += resp.carbs ?? 0.0
                        todayFat += resp.fat ?? 0.0
                        todayFiber += resp.fiber ?? 0.0
                    }
                }
            }
        }
        
        var payload: [String: Any] = [
            "status": "ok",
            "todayCalories": todayCalories,
            "dailyGoal": actualGoal,
            "protein": todayProtein,
            "carbs": todayCarbs,
            "fat": todayFat,
            "fiber": todayFiber,
            "savedMeals": simplifiedSavedMeals,
            "updatedAt": Date().timeIntervalSince1970
        ]
        
        if let user = Auth.auth().currentUser {
            payload["userId"] = user.uid
        }
        
        return payload
    }
    
    /// Proactively pushes the full initial state to Apple Watch.
    func syncInitialState() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        let payload = buildFullSyncPayload()
        do {
            try session.updateApplicationContext(payload)
            print("WatchSyncService: Successfully synced initial state with \(payload["savedMeals"] as? [[String: Any]] ?? []) favourites")
        } catch {
            print("WatchSyncService: Error updating context on init: \(error.localizedDescription)")
            session.transferUserInfo(payload)
        }
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
        
        let simplifiedSavedMeals: [[String: Any]] = savedMeals.map { meal in
            let p: Double = meal.protein ?? 0.0
            let c: Double = meal.carbs ?? 0.0
            let f: Double = meal.fat ?? 0.0
            return [
                "id": meal.id.uuidString,
                "title": meal.title,
                "totalCalories": meal.totalCalories,
                "mealType": meal.mealType,
                "protein": p,
                "carbs": c,
                "fat": f
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
            session.transferUserInfo(payload)
        }
    }
    
    /// Inserts and commits a meal entry logged from Apple Watch.
    func processLogMeal(payload: [String: Any]) {
        guard let context = self.modelContext else {
            print("WatchSyncService: modelContext is nil, cannot save meal entry from Apple Watch")
            return
        }
        
        var text = payload["title"] as? String ?? payload["foodText"] as? String ?? "Meal from Apple Watch"
        let calories = payload["calories"] as? Double ?? 0
        let protein = payload["protein"] as? Double ?? 0
        let carbs = payload["carbs"] as? Double ?? 0
        let fat = payload["fat"] as? Double ?? 0
        let mealType = payload["mealType"] as? String ?? "snack"
        let timestamp = payload["timestamp"] as? Double ?? Date().timeIntervalSince1970
        let savedMealIdStr = payload["savedMealId"] as? String
        let savedMealId = savedMealIdStr.flatMap { UUID(uuidString: $0) }
        
        var rawJson = payload["rawResponseJson"] as? String ?? ""
        
        // If rawJson wasn't provided directly, check if this came from a SavedMeal
        if rawJson.isEmpty || rawJson == "{}" {
            if let sId = savedMealId {
                let descriptor = FetchDescriptor<SavedMeal>(
                    predicate: #Predicate<SavedMeal> { $0.id == sId }
                )
                if let saved = try? context.fetch(descriptor).first {
                    rawJson = saved.rawResponseJson
                    if !saved.title.isEmpty {
                        text = saved.title
                    }
                }
            }
        }
        
        // Fallback: If still empty, construct valid MealLogResponse
        if rawJson.isEmpty || rawJson == "{}" {
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
            rawJson = (try? String(data: JSONEncoder().encode(logResponse), encoding: .utf8)) ?? "{}"
        }
        
        let entry = MealEntry(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: timestamp),
            createdAt: Date(),
            foodText: text,
            mealType: mealType,
            totalCalories: calories,
            rawResponseJson: rawJson,
            hasImage: false,
            sourceSavedMealId: savedMealId
        )
        
        context.insert(entry)
        do {
            try context.save()
            print("WatchSyncService: Successfully inserted and saved meal from Apple Watch: \(text) (\(Int(calories)) cal)")
        } catch {
            print("WatchSyncService: Error saving context after watch meal insert: \(error)")
        }
        
        Task {
            await CloudSyncService().syncMealToCloud(entry)
            await HealthKitService.shared.saveMealEntry(entry)
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
            print("DEBUG: WatchSyncService activated. Paired: \(session.isPaired), WatchAppInstalled: \(session.isWatchAppInstalled)")
            self.syncInitialState()
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
            self.syncInitialState()
        }
    }
    
    // 1. Two-way Request-Reply Messages
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            let action = message["action"] as? String ?? ""
            print("DEBUG: WatchSyncService didReceiveMessage (with reply): \(action)")
            
            switch action {
            case "requestSync":
                let fullPayload = self.buildFullSyncPayload()
                replyHandler(fullPayload)
                
            case "analyzeMeal":
                guard let text = message["text"] as? String, !text.isEmpty else {
                    replyHandler(["status": "error", "error": "Empty meal text"])
                    return
                }
                
                do {
                    let response = try await FirebaseService().logMeal(foodText: text, mealType: "meal", imageData: nil)
                    let rawJson = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? "{}"
                    
                    let itemsArray: [[String: Any]] = response.items.map { item in
                        [
                            "name": item.name,
                            "quantity": item.quantity,
                            "calories": item.calories,
                            "protein": item.protein ?? 0.0,
                            "carbs": item.carbs ?? 0.0,
                            "fat": item.fat ?? 0.0
                        ]
                    }
                    
                    replyHandler([
                        "status": "success",
                        "totalCalories": response.totalCalories,
                        "protein": response.protein ?? 0.0,
                        "carbs": response.carbs ?? 0.0,
                        "fat": response.fat ?? 0.0,
                        "items": itemsArray,
                        "rawResponseJson": rawJson
                    ])
                } catch {
                    replyHandler(["status": "error", "error": error.localizedDescription])
                }
                
            case "logMealDirect", "logSavedMeal":
                self.processLogMeal(payload: message)
                replyHandler(["status": "logged"])
                
            default:
                replyHandler(["status": "received"])
            }
        }
    }
    
    // 2. One-way Direct Messages
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            let action = message["action"] as? String ?? ""
            print("DEBUG: WatchSyncService didReceiveMessage (fire-and-forget): \(action)")
            if action == "logMealDirect" || action == "logSavedMeal" {
                self.processLogMeal(payload: message)
            }
        }
    }
    
    // 3. Background Queued UserInfo
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            let action = userInfo["action"] as? String ?? ""
            print("DEBUG: WatchSyncService didReceiveUserInfo: \(action)")
            if action == "logMealDirect" || action == "logSavedMeal" {
                self.processLogMeal(payload: userInfo)
            }
        }
    }
}
