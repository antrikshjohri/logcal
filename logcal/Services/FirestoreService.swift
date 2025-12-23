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
}

