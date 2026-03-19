package com.serene.logcal.viewmodel.dashboard;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000V\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010$\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J*\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u00142\u0018\u0010\u0015\u001a\u0014\u0012\u0004\u0012\u00020\u0014\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00180\u00170\u0016H\u0002J\u001e\u0010\u0019\u001a\u00020\u00072\f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\u00180\u00172\u0006\u0010\u001b\u001a\u00020\u0012H\u0002J\b\u0010\u001c\u001a\u00020\u001dH\u0002J\u000e\u0010\u001e\u001a\u00020\u001d2\u0006\u0010\u001f\u001a\u00020\u0012R\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0016\u0010\n\u001a\n \f*\u0004\u0018\u00010\u000b0\u000bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00070\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010\u00a8\u0006 "}, d2 = {"Lcom/serene/logcal/viewmodel/dashboard/DashboardViewModel;", "Landroidx/lifecycle/AndroidViewModel;", "application", "Landroid/app/Application;", "(Landroid/app/Application;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/serene/logcal/viewmodel/dashboard/DashboardUiState;", "localRepo", "Lcom/serene/logcal/data/repository/LocalMealRepository;", "prefs", "Landroid/content/SharedPreferences;", "kotlin.jvm.PlatformType", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "calculateStreakDays", "", "today", "Ljava/time/LocalDate;", "mealsByDate", "", "", "Lcom/serene/logcal/data/local/HistoryMeal;", "computeDashboardStats", "meals", "goal", "observeMeals", "", "setDailyGoal", "newGoal", "app_debug"})
public final class DashboardViewModel extends androidx.lifecycle.AndroidViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.serene.logcal.data.repository.LocalMealRepository localRepo = null;
    private final android.content.SharedPreferences prefs = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.serene.logcal.viewmodel.dashboard.DashboardUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.serene.logcal.viewmodel.dashboard.DashboardUiState> uiState = null;
    
    public DashboardViewModel(@org.jetbrains.annotations.NotNull()
    android.app.Application application) {
        super(null);
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.serene.logcal.viewmodel.dashboard.DashboardUiState> getUiState() {
        return null;
    }
    
    public final void setDailyGoal(int newGoal) {
    }
    
    private final void observeMeals() {
    }
    
    private final com.serene.logcal.viewmodel.dashboard.DashboardUiState computeDashboardStats(java.util.List<com.serene.logcal.data.local.HistoryMeal> meals, int goal) {
        return null;
    }
    
    private final int calculateStreakDays(java.time.LocalDate today, java.util.Map<java.time.LocalDate, ? extends java.util.List<com.serene.logcal.data.local.HistoryMeal>> mealsByDate) {
        return 0;
    }
}