package com.serene.logcal.service

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory
import java.util.concurrent.TimeUnit

object RatingService {
    private const val KEY_MEAL_LOG_COUNT = "mealLogCount"
    private const val KEY_LAST_RATING_REQUEST = "lastRatingRequestDate"
    private const val KEY_HAS_RATED = "hasRatedApp"
    private const val KEY_RATING_REQUEST_COUNT = "ratingRequestCount"

    private val ratingMilestones = listOf(1, 3, 5)
    private const val MIN_DAYS_BETWEEN_REQUESTS = 1
    private const val MAX_RATING_REQUESTS = 3

    fun incrementMealLogCount(context: Context) {
        val prefs = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
        val currentCount = prefs.getInt(KEY_MEAL_LOG_COUNT, 0)
        val newCount = currentCount + 1
        prefs.edit().putInt(KEY_MEAL_LOG_COUNT, newCount).apply()
        android.util.Log.d("RatingService", "Meal log count incremented to: $newCount")
    }

    fun shouldShowRatingDialog(context: Context): Boolean {
        val prefs = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
        
        // Don't show if user already rated
        if (prefs.getBoolean(KEY_HAS_RATED, false)) {
            android.util.Log.d("RatingService", "User has already rated, skipping")
            return false
        }

        // Check if we've exceeded max requests
        val requestCount = prefs.getInt(KEY_RATING_REQUEST_COUNT, 0)
        if (requestCount >= MAX_RATING_REQUESTS) {
            android.util.Log.d("RatingService", "Maximum rating requests ($MAX_RATING_REQUESTS) reached, skipping")
            return false
        }

        // Get current meal log count
        val mealLogCount = prefs.getInt(KEY_MEAL_LOG_COUNT, 0)

        // Check if current count is a milestone
        if (!ratingMilestones.contains(mealLogCount)) {
            return false
        }

        // Check time since last request (if any)
        val lastRequestTime = prefs.getLong(KEY_LAST_RATING_REQUEST, 0L)
        if (lastRequestTime > 0L) {
            val diffMs = System.currentTimeMillis() - lastRequestTime
            val diffDays = TimeUnit.MILLISECONDS.toDays(diffMs)
            if (diffDays < MIN_DAYS_BETWEEN_REQUESTS) {
                android.util.Log.d("RatingService", "Too soon since last request ($diffDays days), skipping")
                return false
            }
        }

        android.util.Log.d("RatingService", "Should show rating dialog - meal log count: $mealLogCount, milestone reached")
        return true
    }

    fun requestRating(activity: Activity) {
        val context = activity.applicationContext
        if (!shouldShowRatingDialog(context)) {
            android.util.Log.d("RatingService", "Conditions not met for rating dialog")
            return
        }

        val prefs = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
        val requestCount = prefs.getInt(KEY_RATING_REQUEST_COUNT, 0)
        
        // Update tracking immediately before starting request
        prefs.edit()
            .putLong(KEY_LAST_RATING_REQUEST, System.currentTimeMillis())
            .putInt(KEY_RATING_REQUEST_COUNT, requestCount + 1)
            .apply()

        val mealLogCount = prefs.getInt(KEY_MEAL_LOG_COUNT, 0)
        android.util.Log.d("RatingService", "Requesting rating dialog - meal log count: $mealLogCount, request count: ${requestCount + 1}")

        val manager = ReviewManagerFactory.create(activity)
        val request = manager.requestReviewFlow()
        request.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val reviewInfo = task.result
                val flow = manager.launchReviewFlow(activity, reviewInfo)
                flow.addOnCompleteListener {
                    android.util.Log.d("RatingService", "In-app review flow completed")
                }
            } else {
                android.util.Log.e("RatingService", "In-app review request failed", task.exception)
            }
        }
    }

    fun markAsRated(context: Context) {
        val prefs = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_HAS_RATED, true).apply()
        android.util.Log.d("RatingService", "User marked as having rated the app")
    }

    fun resetForTesting(context: Context) {
        val prefs = context.getSharedPreferences("logcal_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .remove(KEY_MEAL_LOG_COUNT)
            .remove(KEY_LAST_RATING_REQUEST)
            .remove(KEY_HAS_RATED)
            .remove(KEY_RATING_REQUEST_COUNT)
            .apply()
        android.util.Log.d("RatingService", "Rating state reset for testing")
    }
}
