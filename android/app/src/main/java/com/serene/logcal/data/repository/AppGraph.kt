package com.serene.logcal.data.repository

import android.content.Context
import com.serene.logcal.data.local.AppDatabase

object AppGraph {
    @Volatile
    private var localMealRepository: LocalMealRepository? = null

    fun localMealRepository(context: Context): LocalMealRepository {
        return localMealRepository ?: synchronized(this) {
            localMealRepository ?: LocalMealRepository(
                AppDatabase.getInstance(context).mealDao()
            ).also { repo ->
                localMealRepository = repo
            }
        }
    }
}

