package com.serene.logcal.viewmodel;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00004\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0017\n\u0002\u0010\b\n\u0002\b\u0002\b\u0087\b\u0018\u00002\u00020\u0001BO\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0002\u0010\u0007\u001a\u00020\b\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\f\u0012\n\b\u0002\u0010\r\u001a\u0004\u0018\u00010\n\u00a2\u0006\u0002\u0010\u000eJ\t\u0010\u0019\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u001a\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u001b\u001a\u00020\u0006H\u00c6\u0003J\t\u0010\u001c\u001a\u00020\bH\u00c6\u0003J\t\u0010\u001d\u001a\u00020\nH\u00c6\u0003J\u000b\u0010\u001e\u001a\u0004\u0018\u00010\fH\u00c6\u0003J\u000b\u0010\u001f\u001a\u0004\u0018\u00010\nH\u00c6\u0003JS\u0010 \u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00062\b\b\u0002\u0010\u0007\u001a\u00020\b2\b\b\u0002\u0010\t\u001a\u00020\n2\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\f2\n\b\u0002\u0010\r\u001a\u0004\u0018\u00010\nH\u00c6\u0001J\u0013\u0010!\u001a\u00020\u00032\b\u0010\"\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010#\u001a\u00020$H\u00d6\u0001J\t\u0010%\u001a\u00020\nH\u00d6\u0001R\u0013\u0010\r\u001a\u0004\u0018\u00010\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0010R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0002\u0010\u0012R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0004\u0010\u0012R\u0013\u0010\u000b\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016R\u0011\u0010\u0007\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0018\u00a8\u0006&"}, d2 = {"Lcom/serene/logcal/viewmodel/LogUiState;", "", "isAuthReady", "", "isLoading", "selectedDate", "Ljava/time/LocalDate;", "selectedMealType", "Lcom/serene/logcal/model/MealType;", "foodText", "", "latestResult", "Lcom/serene/logcal/model/MealLogResponse;", "errorMessage", "(ZZLjava/time/LocalDate;Lcom/serene/logcal/model/MealType;Ljava/lang/String;Lcom/serene/logcal/model/MealLogResponse;Ljava/lang/String;)V", "getErrorMessage", "()Ljava/lang/String;", "getFoodText", "()Z", "getLatestResult", "()Lcom/serene/logcal/model/MealLogResponse;", "getSelectedDate", "()Ljava/time/LocalDate;", "getSelectedMealType", "()Lcom/serene/logcal/model/MealType;", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "copy", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class LogUiState {
    private final boolean isAuthReady = false;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.NotNull()
    private final java.time.LocalDate selectedDate = null;
    @org.jetbrains.annotations.NotNull()
    private final com.serene.logcal.model.MealType selectedMealType = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String foodText = null;
    @org.jetbrains.annotations.Nullable()
    private final com.serene.logcal.model.MealLogResponse latestResult = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String errorMessage = null;
    
    public final boolean component1() {
        return false;
    }
    
    public final boolean component2() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.time.LocalDate component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.serene.logcal.model.MealType component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.serene.logcal.model.MealLogResponse component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component7() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.serene.logcal.viewmodel.LogUiState copy(boolean isAuthReady, boolean isLoading, @org.jetbrains.annotations.NotNull()
    java.time.LocalDate selectedDate, @org.jetbrains.annotations.NotNull()
    com.serene.logcal.model.MealType selectedMealType, @org.jetbrains.annotations.NotNull()
    java.lang.String foodText, @org.jetbrains.annotations.Nullable()
    com.serene.logcal.model.MealLogResponse latestResult, @org.jetbrains.annotations.Nullable()
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
    
    public LogUiState(boolean isAuthReady, boolean isLoading, @org.jetbrains.annotations.NotNull()
    java.time.LocalDate selectedDate, @org.jetbrains.annotations.NotNull()
    com.serene.logcal.model.MealType selectedMealType, @org.jetbrains.annotations.NotNull()
    java.lang.String foodText, @org.jetbrains.annotations.Nullable()
    com.serene.logcal.model.MealLogResponse latestResult, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage) {
        super();
    }
    
    public final boolean isAuthReady() {
        return false;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.time.LocalDate getSelectedDate() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.serene.logcal.model.MealType getSelectedMealType() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getFoodText() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.serene.logcal.model.MealLogResponse getLatestResult() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getErrorMessage() {
        return null;
    }
    
    public LogUiState() {
        super();
    }
}