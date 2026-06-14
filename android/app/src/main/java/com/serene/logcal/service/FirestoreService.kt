package com.serene.logcal.service

import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.serene.logcal.data.local.MealEntryEntity
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.tasks.await
import java.util.Date

class FirestoreService {
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    data class UserPreferences(
        val dailyGoal: Double? = null,
        val proteinGoal: Double? = null,
        val carbsGoal: Double? = null,
        val fatGoal: Double? = null,
        val dietStyle: String? = null,
    )

    data class WhatsAppLinkageInfo(
        val phoneNumber: String? = null,
        val linkageCode: String? = null,
        val linkageExpiryMillis: Long? = null,
    )

    data class ReminderTime(
        val hour: Int,
        val minute: Int,
    )

    data class NotificationPreferences(
        val mealRemindersEnabled: Boolean,
        val breakfastTime: ReminderTime? = null,
        val lunchTime: ReminderTime? = null,
        val dinnerTime: ReminderTime? = null,
    )

    private val currentUserId: String?
        get() = auth.currentUser?.uid

    suspend fun saveMealEntry(entry: MealEntryEntity) {
        val userId = currentUserId ?: return
        val mealData = hashMapOf(
            "id" to entry.id,
            "timestamp" to Timestamp(Date(entry.timestampMillis)),
            "createdAt" to Timestamp(Date(entry.createdAtMillis)),
            "foodText" to entry.foodText,
            "mealType" to entry.mealType,
            "totalCalories" to entry.totalCalories,
            "rawResponseJson" to entry.rawResponseJson,
            "hasImage" to entry.hasImage
        )

        try {
            db.collection("users").document(userId)
                .collection("meals").document(entry.id)
                .set(mealData).await()
            DebugLogger.d("DEBUG: [FirestoreService] Successfully saved meal entry: ${entry.id}")
            saveMealToMealLogs(entry, userId)
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error saving meal to Firestore", e)
            throw e
        }
    }

    private suspend fun saveMealToMealLogs(entry: MealEntryEntity, userId: String) {
        val mealLogData = hashMapOf(
            "uid" to userId,
            "foodText" to entry.foodText,
            "mealType" to entry.mealType,
            "totalCalories" to entry.totalCalories,
            "hasImage" to entry.hasImage,
            "timestamp" to Timestamp(Date(entry.timestampMillis))
        )
        try {
            db.collection("mealLogs").document(entry.id).set(mealLogData).await()
            DebugLogger.d("DEBUG: [FirestoreService] Saved to mealLogs: ${entry.id}")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Warning - Failed to save to mealLogs: ${e.localizedMessage}")
        }
    }

    suspend fun fetchMealEntries(): List<MealEntryEntity> {
        val userId = currentUserId ?: return emptyList()
        try {
            val snapshot = db.collection("users").document(userId)
                .collection("meals").get().await()

            val entries = mutableListOf<MealEntryEntity>()
            for (doc in snapshot.documents) {
                val data = doc.data ?: continue
                val id = data["id"] as? String ?: continue
                val timestamp = (data["timestamp"] as? Timestamp)?.toDate()?.time ?: continue
                val createdAt = (data["createdAt"] as? Timestamp)?.toDate()?.time ?: timestamp
                val foodText = data["foodText"] as? String ?: continue
                val mealType = data["mealType"] as? String ?: continue
                val totalCalories = (data["totalCalories"] as? Number)?.toDouble() ?: continue
                val rawResponseJson = data["rawResponseJson"] as? String ?: continue
                val hasImage = data["hasImage"] as? Boolean ?: false

                entries.add(
                    MealEntryEntity(
                        id = id,
                        timestampMillis = timestamp,
                        createdAtMillis = createdAt,
                        foodText = foodText,
                        mealType = mealType,
                        totalCalories = totalCalories,
                        rawResponseJson = rawResponseJson,
                        hasImage = hasImage
                    )
                )
            }
            DebugLogger.d("DEBUG: [FirestoreService] Fetched ${entries.size} meals from Firestore")
            return entries
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error fetching meals from Firestore", e)
            throw e
        }
    }

    suspend fun deleteMealEntry(id: String) {
        val userId = currentUserId ?: return
        val idUpper = id
        val idLower = id.lowercase()

        try {
            // Delete both uppercase and lowercase keys like iOS for robustness
            db.collection("users").document(userId).collection("meals").document(idUpper).delete().await()
            db.collection("users").document(userId).collection("meals").document(idLower).delete().await()
            DebugLogger.d("DEBUG: [FirestoreService] Deleted meal entry: $id")

            db.collection("mealLogs").document(idUpper).delete().await()
            db.collection("mealLogs").document(idLower).delete().await()
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error deleting meal from Firestore", e)
            throw e
        }
    }

    suspend fun syncLocalMealsToCloud(entries: List<MealEntryEntity>) {
        val userId = currentUserId ?: return
        DebugLogger.d("DEBUG: [FirestoreService] Starting batch migration of ${entries.size} meals")

        var batch = db.batch()
        var ops = 0

        for (entry in entries) {
            val mealRef = db.collection("users").document(userId).collection("meals").document(entry.id)
            val mealData = hashMapOf(
                "id" to entry.id,
                "timestamp" to Timestamp(Date(entry.timestampMillis)),
                "createdAt" to Timestamp(Date(entry.createdAtMillis)),
                "foodText" to entry.foodText,
                "mealType" to entry.mealType,
                "totalCalories" to entry.totalCalories,
                "rawResponseJson" to entry.rawResponseJson,
                "hasImage" to entry.hasImage
            )
            batch.set(mealRef, mealData)
            ops++

            val logRef = db.collection("mealLogs").document(entry.id)
            val logData = hashMapOf(
                "uid" to userId,
                "foodText" to entry.foodText,
                "mealType" to entry.mealType,
                "totalCalories" to entry.totalCalories,
                "hasImage" to entry.hasImage,
                "timestamp" to Timestamp(Date(entry.timestampMillis))
            )
            batch.set(logRef, logData)
            ops++

            if (ops >= 500) {
                batch.commit().await()
                batch = db.batch()
                ops = 0
            }
        }

        if (ops > 0) {
            batch.commit().await()
        }
        DebugLogger.d("DEBUG: [FirestoreService] Completed migration of ${entries.size} meals")
    }

    suspend fun saveDailyGoal(
        goal: Double,
        proteinGoal: Double? = null,
        carbsGoal: Double? = null,
        fatGoal: Double? = null,
        dietStyle: String? = null
    ) {
        val userId = currentUserId ?: return
        val userData = hashMapOf<String, Any>(
            "dailyGoal" to goal,
            "updatedAt" to Timestamp(Date())
        )
        if (proteinGoal != null) userData["proteinGoal"] = proteinGoal
        if (carbsGoal != null) userData["carbsGoal"] = carbsGoal
        if (fatGoal != null) userData["fatGoal"] = fatGoal
        if (dietStyle != null) userData["dietStyle"] = dietStyle

        try {
            db.collection("users").document(userId).set(userData, SetOptions.merge()).await()
            DebugLogger.d("DEBUG: [FirestoreService] Successfully saved preferences: goal=$goal")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error saving preferences to Firestore", e)
            throw e
        }
    }

    suspend fun fetchUserPreferences(): UserPreferences? {
        val userId = currentUserId ?: return null
        try {
            val doc = db.collection("users").document(userId).get().await()
            if (doc.exists()) {
                val data = doc.data ?: return null
                val hasPreferences = data.containsKey("dailyGoal") ||
                    data.containsKey("proteinGoal") ||
                    data.containsKey("carbsGoal") ||
                    data.containsKey("fatGoal") ||
                    data.containsKey("dietStyle")
                if (!hasPreferences) return null

                val dailyGoal = (data["dailyGoal"] as? Number)?.toDouble()
                val proteinGoal = (data["proteinGoal"] as? Number)?.toDouble()
                val carbsGoal = (data["carbsGoal"] as? Number)?.toDouble()
                val fatGoal = (data["fatGoal"] as? Number)?.toDouble()
                val dietStyle = data["dietStyle"] as? String

                return UserPreferences(
                    dailyGoal = dailyGoal,
                    proteinGoal = proteinGoal,
                    carbsGoal = carbsGoal,
                    fatGoal = fatGoal,
                    dietStyle = dietStyle
                )
            }
            return null
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error fetching preferences from Firestore", e)
            return null
        }
    }

    suspend fun fetchDailyGoal(): Double? {
        return fetchUserPreferences()?.dailyGoal
    }

    suspend fun saveNotificationPreferences(
        mealRemindersEnabled: Boolean,
        breakfastTime: ReminderTime,
        lunchTime: ReminderTime,
        dinnerTime: ReminderTime,
    ) {
        val userId = currentUserId ?: return
        val notificationPrefs = hashMapOf<String, Any>(
            "mealRemindersEnabled" to mealRemindersEnabled,
            "breakfastTime" to mapOf(
                "hour" to breakfastTime.hour,
                "minute" to breakfastTime.minute
            ),
            "lunchTime" to mapOf(
                "hour" to lunchTime.hour,
                "minute" to lunchTime.minute
            ),
            "dinnerTime" to mapOf(
                "hour" to dinnerTime.hour,
                "minute" to dinnerTime.minute
            )
        )
        val userData = hashMapOf<String, Any>(
            "notificationPreferences" to notificationPrefs,
            "updatedAt" to Timestamp(Date())
        )

        try {
            db.collection("users").document(userId).set(userData, SetOptions.merge()).await()
            DebugLogger.d("DEBUG: [FirestoreService] Saved notification preferences")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error saving notification preferences", e)
            throw e
        }
    }

    suspend fun fetchNotificationPreferences(): NotificationPreferences? {
        val userId = currentUserId ?: return null
        return try {
            val doc = db.collection("users").document(userId).get().await()
            val prefs = doc.data?.get("notificationPreferences") as? Map<*, *> ?: return null
            val enabled = prefs["mealRemindersEnabled"] as? Boolean ?: return null

            NotificationPreferences(
                mealRemindersEnabled = enabled,
                breakfastTime = parseReminderTime(prefs["breakfastTime"]),
                lunchTime = parseReminderTime(prefs["lunchTime"]),
                dinnerTime = parseReminderTime(prefs["dinnerTime"])
            )
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error fetching notification preferences", e)
            null
        }
    }

    private fun parseReminderTime(value: Any?): ReminderTime? {
        val time = value as? Map<*, *> ?: return null
        val hour = (time["hour"] as? Number)?.toInt() ?: return null
        val minute = (time["minute"] as? Number)?.toInt() ?: return null
        return ReminderTime(hour, minute)
    }

    suspend fun saveUserCountry(countryCode: String) {
        val userId = currentUserId ?: return
        val userData = hashMapOf(
            "country" to countryCode,
            "updatedAt" to Timestamp(Date())
        )
        try {
            db.collection("users").document(userId).set(userData, SetOptions.merge()).await()
            DebugLogger.d("DEBUG: [FirestoreService] Saved user country: $countryCode")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error saving country to Firestore", e)
        }
    }

    suspend fun fetchUserCountry(): String? {
        val userId = currentUserId ?: return null
        try {
            val doc = db.collection("users").document(userId).get().await()
            if (doc.exists()) {
                return doc.data?.get("country") as? String
            }
            return null
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error fetching country from Firestore", e)
            return null
        }
    }

    suspend fun saveSavedMealsToCloud(meals: List<SavedMealEntity>) {
        val userId = currentUserId ?: return
        val mealsData = meals.map { meal ->
            val dict = hashMapOf<String, Any>(
                "id" to meal.id,
                "title" to meal.title,
                "foodText" to meal.foodText,
                "mealType" to meal.mealType,
                "totalCalories" to meal.totalCalories,
                "rawResponseJson" to meal.rawResponseJson,
                "displayOrder" to meal.displayOrder
            )
            if (meal.sourceMealId != null) {
                dict["sourceMealId"] = meal.sourceMealId
            }
            dict
        }

        val userData = hashMapOf(
            "savedMeals" to mealsData,
            "updatedAt" to Timestamp(Date())
        )

        try {
            db.collection("users").document(userId).set(userData, SetOptions.merge()).await()
            DebugLogger.d("DEBUG: [FirestoreService] Saved ${meals.size} favorites to cloud")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error saving favorites to cloud", e)
            throw e
        }
    }

    suspend fun fetchSavedMealsFromCloud(): List<SavedMealEntity> {
        val userId = currentUserId ?: return emptyList()
        try {
            val doc = db.collection("users").document(userId).get().await()
            if (doc.exists()) {
                val mealsArray = doc.data?.get("savedMeals") as? List<Map<String, Any>> ?: return emptyList()
                val savedMeals = mutableListOf<SavedMealEntity>()
                for ((index, dict) in mealsArray.withIndex()) {
                    val id = dict["id"] as? String ?: continue
                    val title = dict["title"] as? String ?: continue
                    val foodText = dict["foodText"] as? String ?: continue
                    val mealType = dict["mealType"] as? String ?: continue
                    val totalCalories = (dict["totalCalories"] as? Number)?.toDouble() ?: continue
                    val rawResponseJson = dict["rawResponseJson"] as? String ?: continue
                    val sourceMealId = dict["sourceMealId"] as? String
                    val displayOrder = (dict["displayOrder"] as? Number)?.toInt() ?: index

                    savedMeals.add(
                        SavedMealEntity(
                            id = id,
                            title = title,
                            foodText = foodText,
                            mealType = mealType,
                            totalCalories = totalCalories,
                            rawResponseJson = rawResponseJson,
                            sourceMealId = sourceMealId,
                            displayOrder = displayOrder
                        )
                    )
                }
                DebugLogger.d("DEBUG: [FirestoreService] Fetched ${savedMeals.size} favorites from cloud")
                return savedMeals
            }
            return emptyList()
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error fetching favorites from Firestore", e)
            return emptyList()
        }
    }

    suspend fun saveWhatsAppLinkageCode(code: String, expiryMillis: Long) {
        val userId = currentUserId ?: throw IllegalStateException("Not authenticated")
        val userData = hashMapOf(
            "whatsappLinkageCode" to code.uppercase(),
            "whatsappLinkageExpiry" to Timestamp(Date(expiryMillis))
        )
        db.collection("users").document(userId).set(userData, SetOptions.merge()).await()
        DebugLogger.d("DEBUG: [FirestoreService] Saved WhatsApp linkage code: $code")
    }

    suspend fun fetchWhatsAppLinkageInfo(): WhatsAppLinkageInfo {
        val userId = currentUserId ?: throw IllegalStateException("Not authenticated")
        val doc = db.collection("users").document(userId).get().await()
        if (!doc.exists()) return WhatsAppLinkageInfo()

        val data = doc.data ?: return WhatsAppLinkageInfo()
        val phoneNumber = data["whatsappPhoneNumber"] as? String
        val linkageCode = data["whatsappLinkageCode"] as? String
        val linkageExpiry = (data["whatsappLinkageExpiry"] as? Timestamp)?.toDate()?.time

        return WhatsAppLinkageInfo(phoneNumber, linkageCode, linkageExpiry)
    }

    suspend fun unlinkWhatsApp() {
        val userId = currentUserId ?: throw IllegalStateException("Not authenticated")
        val updates = hashMapOf<String, Any>(
            "whatsappPhoneNumber" to FieldValue.delete(),
            "whatsappLinkageCode" to FieldValue.delete(),
            "whatsappLinkageExpiry" to FieldValue.delete()
        )
        db.collection("users").document(userId).update(updates).await()
        DebugLogger.d("DEBUG: [FirestoreService] Unlinked WhatsApp for user: $userId")
    }

    suspend fun submitFeedback(text: String, email: String?) {
        val userId = currentUserId ?: throw IllegalStateException("Not authenticated")
        val feedbackData = hashMapOf(
            "userId" to userId,
            "feedbackText" to text,
            "contactEmail" to (email ?: ""),
            "timestamp" to FieldValue.serverTimestamp(),
            "device" to "Android",
            "appVersion" to "1.0"
        )
        db.collection("feedback").add(feedbackData).await()
        DebugLogger.d("DEBUG: [FirestoreService] Feedback submitted successfully")
    }

    suspend fun deleteUserData() {
        val userId = currentUserId ?: throw IllegalStateException("Not authenticated")
        DebugLogger.d("DEBUG: [FirestoreService] Starting deletion of all user data for: $userId")
        
        try {
            // Delete all meals
            val mealsRef = db.collection("users").document(userId).collection("meals")
            var mealsSnapshot = mealsRef.limit(500).get().await()
            var totalDeleted = 0
            
            while (!mealsSnapshot.isEmpty) {
                val batch = db.batch()
                for (document in mealsSnapshot.documents) {
                    batch.delete(document.reference)
                }
                batch.commit().await()
                totalDeleted += mealsSnapshot.size()
                DebugLogger.d("DEBUG: [FirestoreService] Deleted batch of ${mealsSnapshot.size()} meals (total: $totalDeleted)")
                
                if (mealsSnapshot.size() == 500) {
                    mealsSnapshot = mealsRef.limit(500).get().await()
                } else {
                    break
                }
            }
            
            // Delete from mealLogs collection (where uid == userId)
            val mealLogsSnapshot = db.collection("mealLogs")
                .whereEqualTo("uid", userId)
                .limit(500)
                .get()
                .await()
                
            if (!mealLogsSnapshot.isEmpty) {
                val batch = db.batch()
                for (document in mealLogsSnapshot.documents) {
                    batch.delete(document.reference)
                }
                batch.commit().await()
                DebugLogger.d("DEBUG: [FirestoreService] Deleted ${mealLogsSnapshot.size()} meals from old mealLogs collection")
            }
            
            // Finally delete user document
            db.collection("users").document(userId).delete().await()
            DebugLogger.d("DEBUG: [FirestoreService] Deleted user document and data successfully")
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: [FirestoreService] Error deleting user data", e)
            throw e
        }
    }
}
