package com.serene.logcal.data.repository

import com.serene.logcal.data.local.SavedMealDao
import com.serene.logcal.data.local.SavedMealEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext

class LocalSavedMealsRepository(private val dao: SavedMealDao) {
    fun observeAll(): Flow<List<SavedMealEntity>> = dao.observeAll()

    suspend fun getAll(): List<SavedMealEntity> = withContext(Dispatchers.IO) {
        dao.getAll()
    }

    suspend fun getById(id: String): SavedMealEntity? = withContext(Dispatchers.IO) {
        dao.getById(id)
    }

    suspend fun save(meal: SavedMealEntity) = withContext(Dispatchers.IO) {
        dao.insert(meal)
    }

    suspend fun saveAll(meals: List<SavedMealEntity>) = withContext(Dispatchers.IO) {
        dao.insertAll(meals)
    }

    suspend fun delete(id: String) = withContext(Dispatchers.IO) {
        dao.deleteById(id)
    }

    suspend fun deleteAll() = withContext(Dispatchers.IO) {
        dao.deleteAll()
    }
}
