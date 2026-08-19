//
//  HealthKitService.swift
//  logcal
//
//  Created by Antriksh Johri on 20/08/26.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

/// Represents an individual workout session imported from Apple Health.
struct HealthWorkoutItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let durationMinutes: Int
    let caloriesBurned: Double
    let startDate: Date
    let iconName: String
}

/// Manages all two-way interactions with Apple Health (HealthKit).
@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    
    // MARK: - Published State
    @Published var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized: Bool = false
    @Published var activeCaloriesBurned: Double = 0.0
    @Published var stepCount: Int = 0
    @Published var isSyncing: Bool = false
    @Published var syncError: String? = nil
    
    // MARK: - User Preferences Keys
    static let healthKitEnabledKey = "isHealthKitSyncEnabled"
    static let activeBurnEnabledKey = "isHealthKitActiveBurnEnabled"
    static let adjustGoalWithActiveBurnKey = "adjustGoalWithActiveBurn"
    
    @AppStorage(HealthKitService.healthKitEnabledKey) var isHealthKitSyncEnabled: Bool = false
    @AppStorage(HealthKitService.activeBurnEnabledKey) var isHealthKitActiveBurnEnabled: Bool = false
    @AppStorage(HealthKitService.adjustGoalWithActiveBurnKey) var adjustGoalWithActiveBurn: Bool = false
    
    private var observerQuery: HKObserverQuery?
    
    // MARK: - HealthKit Types
    
    /// Nutrition types written to Apple Health
    private var typesToWrite: Set<HKSampleType> {
        guard let energy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let protein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
              let carbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
              let fiber = HKObjectType.quantityType(forIdentifier: .dietaryFiber) else {
            return []
        }
        return [energy, protein, carbs, fat, fiber]
    }
    
    /// Activity types read from Apple Health
    private var typesToRead: Set<HKObjectType> {
        var set: Set<HKObjectType> = [HKObjectType.workoutType()]
        
        if let activeBurn = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            set.insert(activeBurn)
        }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            set.insert(steps)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            set.insert(distance)
        }
        if let basal = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            set.insert(basal)
        }
        return set
    }
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Checks current authorization status for dietary energy.
    func checkAuthorizationStatus() {
        guard let store = healthStore,
              let energyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            isAuthorized = false
            return
        }
        
        let status = store.authorizationStatus(for: energyType)
        isAuthorized = (status == .sharingAuthorized)
    }
    
    /// Requests user authorization for reading activity & writing dietary nutrition.
    func requestAuthorization() async -> Bool {
        guard let store = healthStore else {
            isAuthorized = false
            return false
        }
        
        do {
            try await store.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            checkAuthorizationStatus()
            if isAuthorized || isHealthKitActiveBurnEnabled {
                isHealthKitSyncEnabled = true
                isHealthKitActiveBurnEnabled = true
                await refreshTodayActivity()
                startObservingHealthChanges()
            }
            return isAuthorized
        } catch {
            print("DEBUG: [HealthKitService] Authorization failed: \(error.localizedDescription)")
            syncError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Export (Write) Dietary Nutrition to Apple Health
    
    /// Saves a meal entry's calories, protein, carbs, fat, and fiber to Apple Health.
    func saveMealEntry(_ meal: MealEntry) async {
        guard isHealthKitSyncEnabled, let store = healthStore else { return }
        
        let timestamp = meal.timestamp
        let mealIdString = meal.id.uuidString
        let mealType = meal.mealType
        
        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: mealType.capitalized,
            "LogCalMealId": mealIdString,
            HKMetadataKeySyncIdentifier: mealIdString,
            HKMetadataKeySyncVersion: 1
        ]
        
        var samples: [HKQuantitySample] = []
        
        // 1. Dietary Energy (Calories)
        if meal.totalCalories > 0, let energyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: meal.totalCalories)
            let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: timestamp, end: timestamp, metadata: metadata)
            samples.append(energySample)
        }
        
        // 2. Protein
        if let p = meal.response?.protein, p > 0, let proteinType = HKObjectType.quantityType(forIdentifier: .dietaryProtein) {
            let pQuantity = HKQuantity(unit: .gram(), doubleValue: p)
            let pSample = HKQuantitySample(type: proteinType, quantity: pQuantity, start: timestamp, end: timestamp, metadata: metadata)
            samples.append(pSample)
        }
        
        // 3. Carbs
        if let c = meal.response?.carbs, c > 0, let carbsType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let cQuantity = HKQuantity(unit: .gram(), doubleValue: c)
            let cSample = HKQuantitySample(type: carbsType, quantity: cQuantity, start: timestamp, end: timestamp, metadata: metadata)
            samples.append(cSample)
        }
        
        // 4. Fat
        if let f = meal.response?.fat, f > 0, let fatType = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) {
            let fQuantity = HKQuantity(unit: .gram(), doubleValue: f)
            let fSample = HKQuantitySample(type: fatType, quantity: fQuantity, start: timestamp, end: timestamp, metadata: metadata)
            samples.append(fSample)
        }
        
        // 5. Dietary Fiber
        if let fib = meal.response?.fiber, fib > 0, let fiberType = HKObjectType.quantityType(forIdentifier: .dietaryFiber) {
            let fibQuantity = HKQuantity(unit: .gram(), doubleValue: fib)
            let fibSample = HKQuantitySample(type: fiberType, quantity: fibQuantity, start: timestamp, end: timestamp, metadata: metadata)
            samples.append(fibSample)
        }
        
        guard !samples.isEmpty else { return }
        
        do {
            try await store.save(samples)
            print("DEBUG: [HealthKitService] Saved \(samples.count) samples for meal '\(meal.foodText)' to Apple Health")
        } catch {
            print("DEBUG: [HealthKitService] Error saving meal to HealthKit: \(error.localizedDescription)")
        }
    }
    
    /// Deletes all HealthKit nutrition samples associated with a LogCal meal ID.
    func deleteMealEntry(mealId: UUID) async {
        guard let store = healthStore else { return }
        
        let mealIdString = mealId.uuidString
        let predicate = HKQuery.predicateForObjects(withMetadataKey: "LogCalMealId", operatorType: .equalTo, value: mealIdString)
        
        for sampleType in typesToWrite {
            guard let quantityType = sampleType as? HKQuantityType else { continue }
            
            do {
                let samplesToDelete = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: samples ?? [])
                        }
                    }
                    store.execute(query)
                }
                
                if !samplesToDelete.isEmpty {
                    try await store.delete(samplesToDelete)
                    print("DEBUG: [HealthKitService] Deleted \(samplesToDelete.count) \(quantityType.identifier) samples from HealthKit for meal \(mealIdString)")
                }
            } catch {
                print("DEBUG: [HealthKitService] Error deleting samples for \(quantityType.identifier): \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates an existing meal in HealthKit by deleting past samples and writing new ones.
    func updateMealEntry(_ meal: MealEntry) async {
        await deleteMealEntry(mealId: meal.id)
        if !meal.deleted {
            await saveMealEntry(meal)
        }
    }
    
    /// Syncs all existing active meals from the local diary into Apple Health.
    func syncHistoricalMeals(_ meals: [MealEntry]) async {
        guard isHealthKitSyncEnabled, let _ = healthStore else { return }
        
        isSyncing = true
        syncError = nil
        
        let activeMeals = meals.filter { !$0.deleted }
        for meal in activeMeals {
            await updateMealEntry(meal)
        }
        
        isSyncing = false
    }
    
    // MARK: - Import (Read) Activity & Energy from Apple Health
    
    /// Fetches active calories burned for a specific date (00:00 to 23:59:59).
    func fetchActiveCalories(for date: Date) async -> Double {
        guard isHealthKitActiveBurnEnabled, let store = healthStore,
              let activeBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0.0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: [])
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: activeBurnType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                guard let sum = stats?.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let calories = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            store.execute(query)
        }
    }
    
    /// Fetches step count for a specific date.
    func fetchStepCount(for date: Date) async -> Int {
        guard isHealthKitActiveBurnEnabled, let store = healthStore,
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: [])
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                guard let sum = stats?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let count = Int(sum.doubleValue(for: .count()))
                continuation.resume(returning: count)
            }
            store.execute(query)
        }
    }
    
    /// Fetches basal (resting) energy burned for a specific date.
    /// If querying today, projects full-day resting burn so TDEE is actionable all day.
    func fetchBasalCalories(for date: Date) async -> Double {
        guard isHealthKitActiveBurnEnabled, let store = healthStore,
              let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0.0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: [])
        
        let accumulated: Double = await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                guard let sum = stats?.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let calories = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            store.execute(query)
        }
        
        guard accumulated > 0 else { return 0.0 }
        
        // If it's today and part of the day has elapsed, project the 24-hour basal burn
        if calendar.isDateInToday(date) {
            let hour = calendar.component(.hour, from: Date())
            let minute = calendar.component(.minute, from: Date())
            let totalMinutes = max(1, hour * 60 + minute)
            let dayFraction = Double(totalMinutes) / 1440.0
            
            if dayFraction > 0.05 && dayFraction < 0.95 {
                let projected = accumulated / dayFraction
                return projected
            }
        }
        
        return accumulated
    }
    
    /// Fetches workouts recorded on a specific date.
    func fetchWorkouts(for date: Date) async -> [HealthWorkoutItem] {
        guard isHealthKitActiveBurnEnabled, let store = healthStore else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("DEBUG: [HealthKitService] fetchWorkouts error: \(error.localizedDescription)")
                }
                guard let workouts = samples as? [HKWorkout], error == nil else {
                    print("DEBUG: [HealthKitService] fetchWorkouts: no workouts found or error")
                    continuation.resume(returning: [])
                    return
                }
                
                print("DEBUG: [HealthKitService] fetchWorkouts: found \(workouts.count) workouts for \(date)")
                
                let items: [HealthWorkoutItem] = workouts.map { workout in
                    let durationMins = Int(workout.duration / 60)
                    let calories: Double
                    if #available(iOS 16.0, *) {
                        if let energy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() {
                            calories = energy.doubleValue(for: .kilocalorie())
                        } else if let total = workout.totalEnergyBurned {
                            calories = total.doubleValue(for: .kilocalorie())
                        } else {
                            calories = 0.0
                        }
                    } else {
                        calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0
                    }
                    
                    return HealthWorkoutItem(
                        id: workout.uuid,
                        title: workout.workoutActivityType.displayName,
                        durationMinutes: max(1, durationMins),
                        caloriesBurned: calories,
                        startDate: workout.startDate,
                        iconName: workout.workoutActivityType.iconName
                    )
                }
                
                continuation.resume(returning: items)
            }
            store.execute(query)
        }
    }
    
    /// Refreshes today's active calories burned and step count.
    func refreshTodayActivity() async {
        let burn = await fetchActiveCalories(for: Date())
        let steps = await fetchStepCount(for: Date())
        
        self.activeCaloriesBurned = burn
        self.stepCount = steps
    }
    
    /// Starts observing background HealthKit changes to update burned calories in real-time.
    func startObservingHealthChanges() {
        guard isHealthKitActiveBurnEnabled, let store = healthStore,
              let activeBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        if let existing = observerQuery {
            store.stop(existing)
        }
        
        let query = HKObserverQuery(sampleType: activeBurnType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor [weak self] in
                await self?.refreshTodayActivity()
            }
        }
        
        self.observerQuery = query
        store.execute(query)
        store.enableBackgroundDelivery(for: activeBurnType, frequency: .immediate) { _, _ in }
    }
}

// MARK: - Workout Display Extensions
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .badminton: return "Badminton"
        case .tennis: return "Tennis"
        case .tableTennis: return "Table Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .cricket: return "Cricket"
        case .golf: return "Golf"
        case .martialArts: return "Martial Arts"
        default: return "Workout"
        }
    }
    
    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .highIntensityIntervalTraining: return "figure.hiit"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .hiking: return "figure.hiking"
        case .dance: return "figure.dance"
        case .coreTraining: return "figure.core.training"
        case .crossTraining: return "figure.cross.training"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairClimbing: return "figure.stair.stepper"
        case .badminton: return "figure.badminton"
        case .tennis: return "figure.tennis"
        case .tableTennis: return "figure.table.tennis"
        case .basketball: return "figure.basketball"
        case .soccer: return "figure.soccer"
        case .cricket: return "figure.cricket"
        case .golf: return "figure.golf"
        case .martialArts: return "figure.martial.arts"
        default: return "figure.run"
        }
    }
}
