package com.serene.logcal.viewmodel.dashboard;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\b\n\u0002\b\t\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b&\b\u0087\b\u0018\u00002\u00020\u0001B\u0099\u0001\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u0007\u001a\u00020\u0005\u0012\b\b\u0002\u0010\b\u001a\u00020\u0005\u0012\b\b\u0002\u0010\t\u001a\u00020\u0005\u0012\b\b\u0002\u0010\n\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u000b\u001a\u00020\u0005\u0012\b\b\u0002\u0010\f\u001a\u00020\u0005\u0012\b\b\u0002\u0010\r\u001a\u00020\u0005\u0012\u000e\b\u0002\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00100\u000f\u0012\b\b\u0002\u0010\u0011\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u0012\u001a\u00020\u0005\u0012\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\u0014\u00a2\u0006\u0002\u0010\u0015J\t\u0010\'\u001a\u00020\u0003H\u00c6\u0003J\t\u0010(\u001a\u00020\u0005H\u00c6\u0003J\u000f\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00100\u000fH\u00c6\u0003J\t\u0010*\u001a\u00020\u0005H\u00c6\u0003J\t\u0010+\u001a\u00020\u0005H\u00c6\u0003J\u000b\u0010,\u001a\u0004\u0018\u00010\u0014H\u00c6\u0003J\t\u0010-\u001a\u00020\u0005H\u00c6\u0003J\t\u0010.\u001a\u00020\u0005H\u00c6\u0003J\t\u0010/\u001a\u00020\u0005H\u00c6\u0003J\t\u00100\u001a\u00020\u0005H\u00c6\u0003J\t\u00101\u001a\u00020\u0005H\u00c6\u0003J\t\u00102\u001a\u00020\u0005H\u00c6\u0003J\t\u00103\u001a\u00020\u0005H\u00c6\u0003J\t\u00104\u001a\u00020\u0005H\u00c6\u0003J\u009d\u0001\u00105\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00052\b\b\u0002\u0010\u0007\u001a\u00020\u00052\b\b\u0002\u0010\b\u001a\u00020\u00052\b\b\u0002\u0010\t\u001a\u00020\u00052\b\b\u0002\u0010\n\u001a\u00020\u00052\b\b\u0002\u0010\u000b\u001a\u00020\u00052\b\b\u0002\u0010\f\u001a\u00020\u00052\b\b\u0002\u0010\r\u001a\u00020\u00052\u000e\b\u0002\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00100\u000f2\b\b\u0002\u0010\u0011\u001a\u00020\u00052\b\b\u0002\u0010\u0012\u001a\u00020\u00052\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\u0014H\u00c6\u0001J\u0013\u00106\u001a\u00020\u00032\b\u00107\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00108\u001a\u00020\u0005H\u00d6\u0001J\t\u00109\u001a\u00020\u0014H\u00d6\u0001R\u0011\u0010\t\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0011\u0010\u0006\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0017R\u0013\u0010\u0013\u001a\u0004\u0018\u00010\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u001aR\u0011\u0010\n\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0017R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0002\u0010\u001cR\u0011\u0010\f\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u0017R\u0011\u0010\r\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u0017R\u0011\u0010\u000b\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u0017R\u0011\u0010\b\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u0017R\u0011\u0010\u0007\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b!\u0010\u0017R\u0011\u0010\u0012\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\"\u0010\u0017R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b#\u0010\u0017R\u0011\u0010\u0011\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b$\u0010\u0017R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00100\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b%\u0010&\u00a8\u0006:"}, d2 = {"Lcom/serene/logcal/viewmodel/dashboard/DashboardUiState;", "", "isLoading", "", "todayCalories", "", "dailyGoal", "remainingCalories", "proteinGrams", "carbsGrams", "fatGrams", "macroProteinPercent", "macroCarbsPercent", "macroFatPercent", "weeklyStats", "", "Lcom/serene/logcal/viewmodel/dashboard/WeeklyDayStat;", "weeklyAverageCalories", "streakDays", "errorMessage", "", "(ZIIIIIIIIILjava/util/List;IILjava/lang/String;)V", "getCarbsGrams", "()I", "getDailyGoal", "getErrorMessage", "()Ljava/lang/String;", "getFatGrams", "()Z", "getMacroCarbsPercent", "getMacroFatPercent", "getMacroProteinPercent", "getProteinGrams", "getRemainingCalories", "getStreakDays", "getTodayCalories", "getWeeklyAverageCalories", "getWeeklyStats", "()Ljava/util/List;", "component1", "component10", "component11", "component12", "component13", "component14", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "toString", "app_debug"})
public final class DashboardUiState {
    private final boolean isLoading = false;
    private final int todayCalories = 0;
    private final int dailyGoal = 0;
    private final int remainingCalories = 0;
    private final int proteinGrams = 0;
    private final int carbsGrams = 0;
    private final int fatGrams = 0;
    private final int macroProteinPercent = 0;
    private final int macroCarbsPercent = 0;
    private final int macroFatPercent = 0;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.serene.logcal.viewmodel.dashboard.WeeklyDayStat> weeklyStats = null;
    private final int weeklyAverageCalories = 0;
    private final int streakDays = 0;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String errorMessage = null;
    
    public final boolean component1() {
        return false;
    }
    
    public final int component10() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.serene.logcal.viewmodel.dashboard.WeeklyDayStat> component11() {
        return null;
    }
    
    public final int component12() {
        return 0;
    }
    
    public final int component13() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component14() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final int component3() {
        return 0;
    }
    
    public final int component4() {
        return 0;
    }
    
    public final int component5() {
        return 0;
    }
    
    public final int component6() {
        return 0;
    }
    
    public final int component7() {
        return 0;
    }
    
    public final int component8() {
        return 0;
    }
    
    public final int component9() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.serene.logcal.viewmodel.dashboard.DashboardUiState copy(boolean isLoading, int todayCalories, int dailyGoal, int remainingCalories, int proteinGrams, int carbsGrams, int fatGrams, int macroProteinPercent, int macroCarbsPercent, int macroFatPercent, @org.jetbrains.annotations.NotNull()
    java.util.List<com.serene.logcal.viewmodel.dashboard.WeeklyDayStat> weeklyStats, int weeklyAverageCalories, int streakDays, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage) {
        return null;
    }
    
    @java.lang.Override()
    public boolean equals(@org.jetbrains.annotations.Nullable()
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override()
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String toString() {
        return null;
    }
    
    public DashboardUiState(boolean isLoading, int todayCalories, int dailyGoal, int remainingCalories, int proteinGrams, int carbsGrams, int fatGrams, int macroProteinPercent, int macroCarbsPercent, int macroFatPercent, @org.jetbrains.annotations.NotNull()
    java.util.List<com.serene.logcal.viewmodel.dashboard.WeeklyDayStat> weeklyStats, int weeklyAverageCalories, int streakDays, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage) {
        super();
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    public final int getTodayCalories() {
        return 0;
    }
    
    public final int getDailyGoal() {
        return 0;
    }
    
    public final int getRemainingCalories() {
        return 0;
    }
    
    public final int getProteinGrams() {
        return 0;
    }
    
    public final int getCarbsGrams() {
        return 0;
    }
    
    public final int getFatGrams() {
        return 0;
    }
    
    public final int getMacroProteinPercent() {
        return 0;
    }
    
    public final int getMacroCarbsPercent() {
        return 0;
    }
    
    public final int getMacroFatPercent() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.serene.logcal.viewmodel.dashboard.WeeklyDayStat> getWeeklyStats() {
        return null;
    }
    
    public final int getWeeklyAverageCalories() {
        return 0;
    }
    
    public final int getStreakDays() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getErrorMessage() {
        return null;
    }
    
    public DashboardUiState() {
        super();
    }
}