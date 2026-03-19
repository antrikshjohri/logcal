package com.serene.logcal.data.repository;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000F\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0016\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\nH\u0086@\u00a2\u0006\u0002\u0010\u000bJ\u0012\u0010\f\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000f0\u000e0\rJ.\u0010\u0010\u001a\u00020\b2\u0006\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\n2\u0006\u0010\u0014\u001a\u00020\n2\u0006\u0010\u0015\u001a\u00020\u0016H\u0086@\u00a2\u0006\u0002\u0010\u0017R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0018"}, d2 = {"Lcom/serene/logcal/data/repository/LocalMealRepository;", "", "mealDao", "Lcom/serene/logcal/data/local/MealDao;", "(Lcom/serene/logcal/data/local/MealDao;)V", "json", "Lkotlinx/serialization/json/Json;", "deleteMeal", "", "id", "", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "observeHistoryMeals", "Lkotlinx/coroutines/flow/Flow;", "", "Lcom/serene/logcal/data/local/HistoryMeal;", "saveMeal", "timestampMillis", "", "foodText", "mealType", "response", "Lcom/serene/logcal/model/MealLogResponse;", "(JLjava/lang/String;Ljava/lang/String;Lcom/serene/logcal/model/MealLogResponse;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public final class LocalMealRepository {
    @org.jetbrains.annotations.NotNull()
    private final com.serene.logcal.data.local.MealDao mealDao = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.serialization.json.Json json = null;
    
    public LocalMealRepository(@org.jetbrains.annotations.NotNull()
    com.serene.logcal.data.local.MealDao mealDao) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.List<com.serene.logcal.data.local.HistoryMeal>> observeHistoryMeals() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object saveMeal(long timestampMillis, @org.jetbrains.annotations.NotNull()
    java.lang.String foodText, @org.jetbrains.annotations.NotNull()
    java.lang.String mealType, @org.jetbrains.annotations.NotNull()
    com.serene.logcal.model.MealLogResponse response, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object deleteMeal(@org.jetbrains.annotations.NotNull()
    java.lang.String id, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
}