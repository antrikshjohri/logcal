package com.serene.logcal.data.repository

import android.content.Context
import com.serene.logcal.data.local.AppDatabase
import com.serene.logcal.data.local.PreferenceManager
import com.serene.logcal.service.CloudSyncService
import com.serene.logcal.service.MealReminderService

object AppGraph {
    @Volatile
    private var localMealRepository: LocalMealRepository? = null

    @Volatile
    private var localSavedMealsRepository: LocalSavedMealsRepository? = null

    @Volatile
    private var preferenceManager: PreferenceManager? = null

    @Volatile
    private var cloudSyncService: CloudSyncService? = null

    @Volatile
    private var mealReminderService: MealReminderService? = null

    fun localMealRepository(context: Context): LocalMealRepository {
        return localMealRepository ?: synchronized(this) {
            localMealRepository ?: LocalMealRepository(
                AppDatabase.getInstance(context).mealDao()
            ).also { repo ->
                localMealRepository = repo
            }
        }
    }

    fun preferenceManager(context: Context): PreferenceManager {
        return preferenceManager ?: synchronized(this) {
            preferenceManager ?: PreferenceManager(context.applicationContext).also { manager ->
                preferenceManager = manager
            }
        }
    }

    fun cloudSyncService(context: Context): CloudSyncService {
        return cloudSyncService ?: synchronized(this) {
            cloudSyncService ?: CloudSyncService(context.applicationContext).also { service ->
                cloudSyncService = service
            }
        }
    }

    fun mealReminderService(context: Context): MealReminderService {
        return mealReminderService ?: synchronized(this) {
            mealReminderService ?: MealReminderService(context.applicationContext).also { service ->
                mealReminderService = service
            }
        }
    }

    fun localSavedMealsRepository(context: Context): LocalSavedMealsRepository {
        return localSavedMealsRepository ?: synchronized(this) {
            localSavedMealsRepository ?: LocalSavedMealsRepository(
                AppDatabase.getInstance(context).savedMealDao()
            ).also { repo ->
                localSavedMealsRepository = repo
            }
        }
    }
}
