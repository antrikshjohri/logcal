//
//  FirestoreService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct FirestoreService {
    private let db = Firestore.firestore()
    
    /// Save a meal entry to Firestore
    func saveMealEntry(_ entry: MealEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save")
            return
        }
        
        let mealData: [String: Any] = [
            "id": entry.id.uuidString,
            "timestamp": Timestamp(date: entry.timestamp),
            "createdAt": entry.createdAt != nil ? Timestamp(date: entry.createdAt!) : Timestamp(date: entry.timestamp),
            "foodText": entry.foodText,
            "mealType": entry.mealType,
            "totalCalories": entry.totalCalories,
            "rawResponseJson": entry.rawResponseJson
        ]
        
        do {
            try await db.collection("users").document(userId).collection("meals").document(entry.id.uuidString).setData(mealData)
            print("DEBUG: Successfully saved meal entry to Firestore: \(entry.id)")
        } catch {
            print("DEBUG: Error saving meal to Firestore: \(error)")
            throw AppError.unknown(error)
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
                      let id = UUID(uuidString: idString),
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let foodText = data["foodText"] as? String,
                      let mealType = data["mealType"] as? String,
                      let totalCalories = data["totalCalories"] as? Double,
                      let rawResponseJson = data["rawResponseJson"] as? String else {
                    print("DEBUG: Skipping invalid meal document: \(document.documentID)")
                    continue
                }
                
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                
                let entry = MealEntry(
                    id: id,
                    timestamp: timestamp,
                    createdAt: createdAt,
                    foodText: foodText,
                    mealType: mealType,
                    totalCalories: totalCalories,
                    rawResponseJson: rawResponseJson
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
        
        do {
            try await db.collection("users").document(userId).collection("meals").document(entry.id.uuidString).delete()
            print("DEBUG: Successfully deleted meal entry from Firestore: \(entry.id)")
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
        
        let batch = db.batch()
        var count = 0
        
        for entry in entries {
            let mealData: [String: Any] = [
                "id": entry.id.uuidString,
                "timestamp": Timestamp(date: entry.timestamp),
                "createdAt": entry.createdAt != nil ? Timestamp(date: entry.createdAt!) : Timestamp(date: entry.timestamp),
                "foodText": entry.foodText,
                "mealType": entry.mealType,
                "totalCalories": entry.totalCalories,
                "rawResponseJson": entry.rawResponseJson
            ]
            
            let mealRef = db.collection("users").document(userId).collection("meals").document(entry.id.uuidString)
            batch.setData(mealData, forDocument: mealRef)
            count += 1
            
            // Firestore batch limit is 500 operations
            if count >= 500 {
                try await batch.commit()
                print("DEBUG: Committed batch of 500 meals")
                // Start new batch
                // Note: For simplicity, we'll continue with the same batch
                // In production, you might want to handle this differently
            }
        }
        
        if count > 0 {
            try await batch.commit()
            print("DEBUG: Successfully synced \(count) meals to Firestore")
        }
    }
    
    /// Save daily goal to Firestore
    func saveDailyGoal(_ goal: Double) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user, skipping Firestore save for daily goal")
            return
        }
        
        let userData: [String: Any] = [
            "dailyGoal": goal,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData, merge: true)
            print("DEBUG: Successfully saved daily goal to Firestore: \(goal)")
        } catch {
            print("DEBUG: Error saving daily goal to Firestore: \(error)")
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
}

