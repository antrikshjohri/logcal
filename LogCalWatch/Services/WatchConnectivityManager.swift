//
//  WatchConnectivityManager.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import Foundation
import WatchConnectivity
import Combine
import WidgetKit

/// Manages data synchronization with the iPhone companion app.
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var todayCalories: Double = 0
    @Published var dailyGoal: Double = 2000
    @Published var protein: Double = 0
    @Published var carbs: Double = 0
    @Published var fat: Double = 0
    @Published var fiber: Double = 0
    @Published var savedMeals: [WatchSavedMeal] = []
    @Published var isReachable: Bool = false
    @Published var userId: String = ""
    
    private let defaults = UserDefaults(suiteName: "group.com.serene.logcal") ?? .standard
    
    override init() {
        super.init()
        loadCachedData()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    /// Requests the full initial sync payload (calories, goals, macros, and favourites) from the iPhone.
    func requestInitialSync() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        // 1. Check if applicationContext was already received
        if !session.receivedApplicationContext.isEmpty {
            self.updateFromPayload(session.receivedApplicationContext)
        }
        
        // 2. Request live sync message if reachable
        if session.isReachable {
            session.sendMessage(["action": "requestSync"], replyHandler: { reply in
                Task { @MainActor in
                    print("DEBUG: Watch received requestSync reply: \(reply.keys)")
                    self.updateFromPayload(reply)
                }
            }, errorHandler: { error in
                print("DEBUG: Watch requestSync message error: \(error.localizedDescription)")
            })
        }
    }
    
    private func loadCachedData() {
        todayCalories = defaults.double(forKey: "todayCalories")
        let storedGoal = defaults.double(forKey: "dailyCalorieGoal")
        dailyGoal = storedGoal > 0 ? storedGoal : 2000
        protein = defaults.double(forKey: "todayProtein")
        carbs = defaults.double(forKey: "todayCarbs")
        fat = defaults.double(forKey: "todayFat")
        fiber = defaults.double(forKey: "todayFiber")
        userId = defaults.string(forKey: "userId") ?? ""
        
        if let data = defaults.data(forKey: "savedMealsCache"),
           let decoded = try? JSONDecoder().decode([WatchSavedMeal].self, from: data) {
            savedMeals = decoded
        }
    }
    
    private func saveCachedData() {
        defaults.set(todayCalories, forKey: "todayCalories")
        defaults.set(dailyGoal, forKey: "dailyCalorieGoal")
        defaults.set(protein, forKey: "todayProtein")
        defaults.set(carbs, forKey: "todayCarbs")
        defaults.set(fat, forKey: "todayFat")
        defaults.set(fiber, forKey: "todayFiber")
        defaults.set(userId, forKey: "userId")
        
        if let encoded = try? JSONEncoder().encode(savedMeals) {
            defaults.set(encoded, forKey: "savedMealsCache")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateFromPayload(_ payload: [String: Any]) {
        if let cal = payload["todayCalories"] as? Double {
            todayCalories = cal
        }
        if let goal = payload["dailyGoal"] as? Double, goal > 0 {
            dailyGoal = goal
        }
        if let p = payload["protein"] as? Double {
            protein = p
        }
        if let c = payload["carbs"] as? Double {
            carbs = c
        }
        if let f = payload["fat"] as? Double {
            fat = f
        }
        if let fib = payload["fiber"] as? Double {
            fiber = fib
        }
        if let uid = payload["userId"] as? String {
            userId = uid
        }
        if let rawMeals = payload["savedMeals"] as? [[String: Any]] {
            savedMeals = rawMeals.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let title = dict["title"] as? String,
                      let totalCalories = dict["totalCalories"] as? Double else { return nil }
                let mealType = dict["mealType"] as? String ?? "meal"
                let p = dict["protein"] as? Double ?? 0
                let c = dict["carbs"] as? Double ?? 0
                let f = dict["fat"] as? Double ?? 0
                return WatchSavedMeal(id: id, title: title, totalCalories: totalCalories, mealType: mealType, protein: p, carbs: c, fat: f)
            }
        }
        saveCachedData()
    }
    
    /// Increments local calorie/macro totals upon logging a meal on the watch.
    func recordLocalLog(calories: Double, p: Double, c: Double, f: Double) {
        todayCalories += calories
        protein += p
        carbs += c
        fat += f
        saveCachedData()
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.requestInitialSync()
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                self.requestInitialSync()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.updateFromPayload(applicationContext)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.updateFromPayload(userInfo)
        }
    }
}
