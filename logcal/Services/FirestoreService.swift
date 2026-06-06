//
//  FirestoreService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

@MainActor
struct FirestoreService {
    private let db = Firestore.firestore()
    
    private func getUUIDFromString(_ string: String) -> UUID {
        if let uuid = UUID(uuidString: string) {
            return uuid
        }
        // Fallback: Hash the string deterministically to a UUID.
        // MD5 produces 16 bytes (128 bits), which is exactly the size of a UUID.
        let inputData = Data(string.utf8)
        let hashed = Insecure.MD5.hash(data: inputData)
        let bytes = Array(hashed)
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
    
    /// Save a meal entry to Firestore
    func saveMealEntry(_ entry: MealEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save")
            return
        }
        
        var mealData: [String: Any] = [
            "id": entry.id.uuidString,
            "timestamp": Timestamp(date: entry.timestamp),
            "createdAt": entry.createdAt != nil ? Timestamp(date: entry.createdAt!) : Timestamp(date: entry.timestamp),
            "foodText": entry.foodText,
            "mealType": entry.mealType,
            "totalCalories": entry.totalCalories,
            "rawResponseJson": entry.rawResponseJson,
            "hasImage": entry.hasImageValue
        ]
        if let sourceSavedMealId = entry.sourceSavedMealId {
            mealData["sourceSavedMealId"] = sourceSavedMealId.uuidString
        }
        
        do {
            try await db.collection("users").document(userId).collection("meals").document(entry.id.uuidString).setData(mealData)
            print("DEBUG: Successfully saved meal entry to Firestore: \(entry.id)")
            // Also write to mealLogs so all meals (with or without images) appear there
            try await saveMealToMealLogs(entry: entry, userId: userId)
        } catch {
            print("DEBUG: Error saving meal to Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Write to mealLogs collection so it stays in sync with users/meals (for viewing all logs in one place).
    private func saveMealToMealLogs(entry: MealEntry, userId: String) async throws {
        let mealLogData: [String: Any] = [
            "uid": userId,
            "foodText": entry.foodText,
            "mealType": entry.mealType,
            "totalCalories": entry.totalCalories,
            "hasImage": entry.hasImageValue,
            "timestamp": Timestamp(date: entry.timestamp)
        ]
        let mealLogRef = db.collection("mealLogs").document(entry.id.uuidString)
        do {
            try await mealLogRef.setData(mealLogData)
            print("DEBUG: Successfully saved meal to mealLogs: \(entry.id)")
        } catch {
            print("DEBUG: Warning - Failed to save to mealLogs (non-critical): \(error.localizedDescription)")
        }
    }
    
    /// Fetch all meal entries from Firestore for the current user
    func fetchMealEntries() async throws -> [MealEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch from Firestore")
            return []
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId).collection("meals").getDocuments()
            
            var entries: [MealEntry] = []
            for document in snapshot.documents {
                let data = document.data()
                
                guard let idString = data["id"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let foodText = data["foodText"] as? String,
                      let mealType = data["mealType"] as? String,
                      let totalCalories = data["totalCalories"] as? Double,
                      let rawResponseJson = data["rawResponseJson"] as? String else {
                    print("DEBUG: Skipping invalid meal document: \(document.documentID)")
                    continue
                }
                
                let id = getUUIDFromString(idString)
                
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                let hasImage = data["hasImage"] as? Bool // Optional - nil if not present
                
                let sourceSavedMealIdString = data["sourceSavedMealId"] as? String
                let sourceSavedMealId = sourceSavedMealIdString != nil ? UUID(uuidString: sourceSavedMealIdString!) : nil
                
                let entry = MealEntry(
                    id: id,
                    timestamp: timestamp,
                    createdAt: createdAt,
                    foodText: foodText,
                    mealType: mealType,
                    totalCalories: totalCalories,
                    rawResponseJson: rawResponseJson,
                    hasImage: hasImage,
                    sourceSavedMealId: sourceSavedMealId
                )
                
                entries.append(entry)
            }
            
            print("DEBUG: Fetched \(entries.count) meal entries from Firestore")
            return entries
        } catch {
            print("DEBUG: Error fetching meals from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Delete a meal entry from Firestore
    func deleteMealEntry(_ entry: MealEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore delete")
            return
        }
        
        let idStringUpper = entry.id.uuidString
        let idStringLower = entry.id.uuidString.lowercased()
        
        do {
            // Delete both uppercase and lowercase document IDs to be robust (e.g. client vs backend UUID generation)
            try await db.collection("users").document(userId).collection("meals").document(idStringUpper).delete()
            try await db.collection("users").document(userId).collection("meals").document(idStringLower).delete()
            print("DEBUG: Successfully deleted meal entry from Firestore: \(entry.id)")
            
            try? await db.collection("mealLogs").document(idStringUpper).delete()
            try? await db.collection("mealLogs").document(idStringLower).delete()
        } catch {
            print("DEBUG: Error deleting meal from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Sync local meal entries to Firestore (for migration)
    func syncLocalMealsToCloud(entries: [MealEntry]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot sync to Firestore")
            return
        }
        
        print("DEBUG: Starting sync of \(entries.count) local meals to Firestore")
        
        var batch = db.batch()
        var ops = 0
        
        for entry in entries {
            let mealData: [String: Any] = [
                "id": entry.id.uuidString,
                "timestamp": Timestamp(date: entry.timestamp),
                "createdAt": entry.createdAt != nil ? Timestamp(date: entry.createdAt!) : Timestamp(date: entry.timestamp),
                "foodText": entry.foodText,
                "mealType": entry.mealType,
                "totalCalories": entry.totalCalories,
                "rawResponseJson": entry.rawResponseJson,
                "hasImage": entry.hasImageValue
            ]
            let mealRef = db.collection("users").document(userId).collection("meals").document(entry.id.uuidString)
            batch.setData(mealData, forDocument: mealRef)
            ops += 1
            
            let mealLogData: [String: Any] = [
                "uid": userId,
                "foodText": entry.foodText,
                "mealType": entry.mealType,
                "totalCalories": entry.totalCalories,
                "hasImage": entry.hasImageValue,
                "timestamp": Timestamp(date: entry.timestamp)
            ]
            let mealLogRef = db.collection("mealLogs").document(entry.id.uuidString)
            batch.setData(mealLogData, forDocument: mealLogRef)
            ops += 1
            
            // Firestore batch limit is 500 operations (2 per meal → 250 meals per batch)
            if ops >= 500 {
                try await batch.commit()
                print("DEBUG: Committed batch of \(ops) operations")
                batch = db.batch()
                ops = 0
            }
        }
        
        if ops > 0 {
            try await batch.commit()
            print("DEBUG: Successfully synced \(entries.count) meals to Firestore (users/meals + mealLogs)")
        }
    }
    
    /// Save daily goal and macro targets to Firestore
    func saveDailyGoal(
        _ goal: Double,
        proteinGoal: Double? = nil,
        carbsGoal: Double? = nil,
        fatGoal: Double? = nil,
        dietStyle: String? = nil
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save for daily goal")
            return
        }
        
        var userData: [String: Any] = [
            "dailyGoal": goal,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let proteinGoal = proteinGoal {
            userData["proteinGoal"] = proteinGoal
        }
        if let carbsGoal = carbsGoal {
            userData["carbsGoal"] = carbsGoal
        }
        if let fatGoal = fatGoal {
            userData["fatGoal"] = fatGoal
        }
        if let dietStyle = dietStyle {
            userData["dietStyle"] = dietStyle
        }
        
        do {
            try await db.collection("users").document(userId).setData(userData, merge: true)
            print("DEBUG: Successfully saved daily goal and preferences to Firestore: \(goal) kcal")
        } catch {
            print("DEBUG: Error saving daily goal to Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Save notification preferences to Firestore
    func saveNotificationPreferences(
        mealRemindersEnabled: Bool,
        breakfastTime: (hour: Int, minute: Int)? = nil,
        lunchTime: (hour: Int, minute: Int)? = nil,
        dinnerTime: (hour: Int, minute: Int)? = nil
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save for notification preferences")
            return
        }
        
        var notificationPrefs: [String: Any] = [
            "mealRemindersEnabled": mealRemindersEnabled
        ]
        
        // Add custom times if provided
        if let breakfast = breakfastTime {
            notificationPrefs["breakfastTime"] = [
                "hour": breakfast.hour,
                "minute": breakfast.minute
            ]
        }
        if let lunch = lunchTime {
            notificationPrefs["lunchTime"] = [
                "hour": lunch.hour,
                "minute": lunch.minute
            ]
        }
        if let dinner = dinnerTime {
            notificationPrefs["dinnerTime"] = [
                "hour": dinner.hour,
                "minute": dinner.minute
            ]
        }
        
        let userData: [String: Any] = [
            "notificationPreferences": notificationPrefs,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData, merge: true)
            print("DEBUG: Successfully saved notification preferences to Firestore: mealRemindersEnabled=\(mealRemindersEnabled)")
        } catch {
            print("DEBUG: Error saving notification preferences to Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Notification preferences structure
    struct NotificationPreferences {
        let mealRemindersEnabled: Bool
        let breakfastTime: (hour: Int, minute: Int)?
        let lunchTime: (hour: Int, minute: Int)?
        let dinnerTime: (hour: Int, minute: Int)?
    }
    
    /// Fetch notification preferences from Firestore
    func fetchNotificationPreferences() async throws -> NotificationPreferences? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch notification preferences from Firestore")
            return nil
        }
        
        print("DEBUG: Fetching notification preferences from Firestore for user: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists {
                let data = document.data()
                
                // Check for notification preferences
                if let notificationPrefs = data?["notificationPreferences"] as? [String: Any],
                   let mealRemindersEnabled = notificationPrefs["mealRemindersEnabled"] as? Bool {
                    
                    // Parse custom times
                    var breakfastTime: (hour: Int, minute: Int)? = nil
                    var lunchTime: (hour: Int, minute: Int)? = nil
                    var dinnerTime: (hour: Int, minute: Int)? = nil
                    
                    if let breakfastDict = notificationPrefs["breakfastTime"] as? [String: Any],
                       let hour = breakfastDict["hour"] as? Int,
                       let minute = breakfastDict["minute"] as? Int {
                        breakfastTime = (hour: hour, minute: minute)
                    }
                    
                    if let lunchDict = notificationPrefs["lunchTime"] as? [String: Any],
                       let hour = lunchDict["hour"] as? Int,
                       let minute = lunchDict["minute"] as? Int {
                        lunchTime = (hour: hour, minute: minute)
                    }
                    
                    if let dinnerDict = notificationPrefs["dinnerTime"] as? [String: Any],
                       let hour = dinnerDict["hour"] as? Int,
                       let minute = dinnerDict["minute"] as? Int {
                        dinnerTime = (hour: hour, minute: minute)
                    }
                    
                    let prefs = NotificationPreferences(
                        mealRemindersEnabled: mealRemindersEnabled,
                        breakfastTime: breakfastTime,
                        lunchTime: lunchTime,
                        dinnerTime: dinnerTime
                    )
                    
                    print("DEBUG: Fetched notification preferences from Firestore: mealRemindersEnabled=\(mealRemindersEnabled)")
                    return prefs
                }
                
                print("DEBUG: Notification preferences not found in Firestore document")
                return nil
            } else {
                print("DEBUG: User document does not exist in Firestore")
                return nil
            }
        } catch {
            print("DEBUG: Error fetching notification preferences from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Save user country to Firestore
    func saveUserCountry(_ countryCode: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save for country")
            return
        }
        
        let userData: [String: Any] = [
            "country": countryCode,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData, merge: true)
            print("DEBUG: Successfully saved user country to Firestore: \(countryCode)")
        } catch {
            print("DEBUG: Error saving user country to Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Fetch user country from Firestore
    func fetchUserCountry() async throws -> String? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch user country from Firestore")
            return nil
        }
        
        print("DEBUG: Fetching user country from Firestore for user: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists {
                let data = document.data()
                if let countryCode = data?["country"] as? String {
                    print("DEBUG: Fetched user country from Firestore: \(countryCode)")
                    return countryCode
                }
                print("DEBUG: Country not found in Firestore document")
                return nil
            } else {
                print("DEBUG: User document does not exist in Firestore")
                return nil
            }
        } catch {
            print("DEBUG: Error fetching user country from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Fetch daily goal from Firestore
    func fetchDailyGoal() async throws -> Double? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch daily goal from Firestore")
            return nil
        }
        
        print("DEBUG: Fetching daily goal from Firestore for user: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            print("DEBUG: Firestore document exists: \(document.exists)")
            if document.exists {
                let data = document.data()
                print("DEBUG: Firestore document data keys: \(data?.keys.joined(separator: ", ") ?? "nil")")
                
                // Try Double first
                if let goal = data?["dailyGoal"] as? Double {
                    print("DEBUG: Fetched daily goal from Firestore (as Double): \(goal)")
                    return goal
                }
                // Try Int (Firestore might store as Int)
                else if let goalInt = data?["dailyGoal"] as? Int {
                    let goal = Double(goalInt)
                    print("DEBUG: Fetched daily goal from Firestore (as Int, converted): \(goal)")
                    return goal
                }
                // Try NSNumber (another possible format)
                else if let goalNumber = data?["dailyGoal"] as? NSNumber {
                    let goal = goalNumber.doubleValue
                    print("DEBUG: Fetched daily goal from Firestore (as NSNumber, converted): \(goal)")
                    return goal
                }
                else {
                    print("DEBUG: Daily goal not found in Firestore document or wrong type. Data: \(String(describing: data?["dailyGoal"]))")
                    return nil
                }
            } else {
                print("DEBUG: User document does not exist in Firestore")
                return nil
            }
        } catch {
            print("DEBUG: Error fetching daily goal from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// User preferences structure
    struct UserPreferences {
        let dailyGoal: Double
        let proteinGoal: Double?
        let carbsGoal: Double?
        let fatGoal: Double?
        let dietStyle: String?
    }
    
    /// Fetch user preferences (daily goals & macros) from Firestore
    func fetchUserPreferences() async throws -> UserPreferences? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch preferences from Firestore")
            return nil
        }
        
        print("DEBUG: Fetching user preferences from Firestore for user: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists {
                let data = document.data()
                
                // Parse daily goal (try Double first, then Int)
                var dailyGoal: Double = 2000
                if let goalDouble = data?["dailyGoal"] as? Double {
                    dailyGoal = goalDouble
                } else if let goalInt = data?["dailyGoal"] as? Int {
                    dailyGoal = Double(goalInt)
                } else if let goalNumber = data?["dailyGoal"] as? NSNumber {
                    dailyGoal = goalNumber.doubleValue
                }
                
                // Parse proteinGoal (try Double first, then Int)
                var proteinGoal: Double? = nil
                if let proteinDouble = data?["proteinGoal"] as? Double {
                    proteinGoal = proteinDouble
                } else if let proteinInt = data?["proteinGoal"] as? Int {
                    proteinGoal = Double(proteinInt)
                } else if let proteinNumber = data?["proteinGoal"] as? NSNumber {
                    proteinGoal = proteinNumber.doubleValue
                }
                
                // Parse carbsGoal (try Double first, then Int)
                var carbsGoal: Double? = nil
                if let carbsDouble = data?["carbsGoal"] as? Double {
                    carbsGoal = carbsDouble
                } else if let carbsInt = data?["carbsGoal"] as? Int {
                    carbsGoal = Double(carbsInt)
                } else if let carbsNumber = data?["carbsGoal"] as? NSNumber {
                    carbsGoal = carbsNumber.doubleValue
                }
                
                // Parse fatGoal (try Double first, then Int)
                var fatGoal: Double? = nil
                if let fatDouble = data?["fatGoal"] as? Double {
                    fatGoal = fatDouble
                } else if let fatInt = data?["fatGoal"] as? Int {
                    fatGoal = Double(fatInt)
                } else if let fatNumber = data?["fatGoal"] as? NSNumber {
                    fatGoal = fatNumber.doubleValue
                }
                
                let dietStyle = data?["dietStyle"] as? String
                
                return UserPreferences(
                    dailyGoal: dailyGoal,
                    proteinGoal: proteinGoal,
                    carbsGoal: carbsGoal,
                    fatGoal: fatGoal,
                    dietStyle: dietStyle
                )
            } else {
                print("DEBUG: User document does not exist in Firestore")
                return nil
            }
        } catch {
            print("DEBUG: Error fetching user preferences from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Delete all user data from Firestore
    func deleteUserData() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot delete user data")
            throw AppError.unknown(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
        }
        
        print("DEBUG: Starting deletion of all user data for: \(userId)")
        
        do {
            // Delete all meals (handle batch size limit of 500)
            let mealsRef = db.collection("users").document(userId).collection("meals")
            var mealsSnapshot = try await mealsRef.limit(to: 500).getDocuments()
            var totalDeleted = 0
            
            // Keep deleting in batches until all meals are deleted
            while !mealsSnapshot.documents.isEmpty {
                let batch = db.batch()
                
                for document in mealsSnapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                try await batch.commit()
                totalDeleted += mealsSnapshot.documents.count
                print("DEBUG: Deleted batch of \(mealsSnapshot.documents.count) meals (total: \(totalDeleted))")
                
                // Get next batch if there are more meals
                if mealsSnapshot.documents.count == 500 {
                    mealsSnapshot = try await mealsRef.limit(to: 500).getDocuments()
                } else {
                    break // No more meals to delete
                }
            }
            
            print("DEBUG: Deleted \(totalDeleted) meals total")
            
            // Also check and delete from old mealLogs collection (backward compatibility)
            let mealLogsSnapshot = try await db.collection("mealLogs")
                .whereField("uid", isEqualTo: userId)
                .limit(to: 500)
                .getDocuments()
            
            if !mealLogsSnapshot.documents.isEmpty {
                let batch = db.batch()
                for document in mealLogsSnapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                try await batch.commit()
                print("DEBUG: Deleted \(mealLogsSnapshot.documents.count) meals from old mealLogs collection")
            }
            
            // Finally, delete user document (this should be done last)
            try await db.collection("users").document(userId).delete()
            print("DEBUG: Deleted user document")
            
            print("DEBUG: Successfully deleted all user data from Firestore")
        } catch {
            print("DEBUG: Error deleting user data from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Save all favorites/saved meals to the user's document in Firestore
    func saveSavedMealsToCloud(_ meals: [SavedMeal]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping favorites save")
            return
        }
        
        let mealsData = meals.map { meal -> [String: Any] in
            var dict: [String: Any] = [
                "id": meal.id.uuidString,
                "title": meal.title,
                "foodText": meal.foodText,
                "mealType": meal.mealType,
                "totalCalories": meal.totalCalories,
                "rawResponseJson": meal.rawResponseJson,
                "displayOrder": meal.displayOrder ?? 0
            ]
            if let sourceId = meal.sourceMealId {
                dict["sourceMealId"] = sourceId.uuidString
            }
            return dict
        }
        
        let userData: [String: Any] = [
            "savedMeals": mealsData,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData, merge: true)
            print("DEBUG: Successfully saved \(meals.count) favorites to cloud")
        } catch {
            print("DEBUG: Error saving favorites to cloud: \(error)")
            throw AppError.unknown(error)
        }
    }
    
    /// Fetch all favorites/saved meals from the user's document in Firestore
    func fetchSavedMealsFromCloud() async throws -> [SavedMeal] {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, cannot fetch favorites")
            return []
        }
        
        print("DEBUG: Fetching favorites from Firestore for user: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists {
                let data = document.data()
                if let mealsArray = data?["savedMeals"] as? [[String: Any]] {
                    var savedMeals: [SavedMeal] = []
                    for (index, dict) in mealsArray.enumerated() {
                        guard let idString = dict["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let title = dict["title"] as? String,
                              let foodText = dict["foodText"] as? String,
                              let mealType = dict["mealType"] as? String,
                              let totalCalories = dict["totalCalories"] as? Double,
                              let rawResponseJson = dict["rawResponseJson"] as? String else {
                            continue
                        }
                        
                        let sourceMealId = (dict["sourceMealId"] as? String).flatMap { UUID(uuidString: $0) }
                        let displayOrder = dict["displayOrder"] as? Int ?? index
                        
                        let meal = SavedMeal(
                            id: id,
                            title: title,
                            foodText: foodText,
                            mealType: mealType,
                            totalCalories: totalCalories,
                            rawResponseJson: rawResponseJson,
                            sourceMealId: sourceMealId,
                            displayOrder: displayOrder
                        )
                        savedMeals.append(meal)
                    }
                    print("DEBUG: Fetched \(savedMeals.count) favorites from cloud")
                    return savedMeals
                }
                print("DEBUG: No favorites found in user document")
                return []
            } else {
                print("DEBUG: User document does not exist, no favorites to fetch")
                return []
            }
        } catch {
            print("DEBUG: Error fetching favorites from Firestore: \(error)")
            throw AppError.unknown(error)
        }
    }

    // MARK: - WhatsApp Linkage Helpers
    
    struct WhatsAppLinkageInfo {
        let phoneNumber: String?
        let linkageCode: String?
        let linkageExpiry: Date?
    }
    
    func saveWhatsAppLinkageCode(_ code: String, expiry: Date) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AppError.unknown(NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
        }
        
        let userData: [String: Any] = [
            "whatsappLinkageCode": code.uppercased(),
            "whatsappLinkageExpiry": Timestamp(date: expiry)
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
    }
    
    func fetchWhatsAppLinkageInfo() async throws -> WhatsAppLinkageInfo {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AppError.unknown(NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        guard document.exists else {
            return WhatsAppLinkageInfo(phoneNumber: nil, linkageCode: nil, linkageExpiry: nil)
        }
        
        let data = document.data() ?? [:]
        let phoneNumber = data["whatsappPhoneNumber"] as? String
        let linkageCode = data["whatsappLinkageCode"] as? String
        let linkageExpiry = (data["whatsappLinkageExpiry"] as? Timestamp)?.dateValue()
        
        return WhatsAppLinkageInfo(phoneNumber: phoneNumber, linkageCode: linkageCode, linkageExpiry: linkageExpiry)
    }
    
    func unlinkWhatsApp() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AppError.unknown(NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
        }
        
        let updates: [String: Any] = [
            "whatsappPhoneNumber": FieldValue.delete(),
            "whatsappLinkageCode": FieldValue.delete(),
            "whatsappLinkageExpiry": FieldValue.delete()
        ]
        
        try await db.collection("users").document(userId).updateData(updates)
    }
}

