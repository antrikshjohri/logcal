package com.serene.logcal.viewmodel;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000T\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\b\u0010\u0012\u001a\u00020\u0013H\u0002J\u0006\u0010\u0014\u001a\u00020\u0013J\u000e\u0010\u0015\u001a\u00020\u00132\u0006\u0010\u0016\u001a\u00020\u0017J\u000e\u0010\u0018\u001a\u00020\u00132\u0006\u0010\u0019\u001a\u00020\u001aJ\u000e\u0010\u001b\u001a\u00020\u00132\u0006\u0010\u001c\u001a\u00020\u001dR\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u000bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\rX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00070\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011\u00a8\u0006\u001e"}, d2 = {"Lcom/serene/logcal/viewmodel/LogViewModel;", "Landroidx/lifecycle/AndroidViewModel;", "application", "Landroid/app/Application;", "(Landroid/app/Application;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/serene/logcal/viewmodel/LogUiState;", "auth", "Lcom/google/firebase/auth/FirebaseAuth;", "localRepo", "Lcom/serene/logcal/data/repository/LocalMealRepository;", "repo", "Lcom/serene/logcal/service/FirebaseMealRepository;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "ensureAnonymousAuth", "", "logMeal", "onFoodTextChanged", "newText", "", "setMealType", "newMealType", "Lcom/serene/logcal/model/MealType;", "setSelectedDate", "newDate", "Ljava/time/LocalDate;", "app_debug"})
public final class LogViewModel extends androidx.lifecycle.AndroidViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.auth.FirebaseAuth auth = null;
    @org.jetbrains.annotations.NotNull()
    private final com.serene.logcal.service.FirebaseMealRepository repo = null;
    @org.jetbrains.annotations.NotNull()
    private final com.serene.logcal.data.repository.LocalMealRepository localRepo = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.serene.logcal.viewmodel.LogUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.serene.logcal.viewmodel.LogUiState> uiState = null;
    
    public LogViewModel(@org.jetbrains.annotations.NotNull()
    android.app.Application application) {
        super(null);
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.serene.logcal.viewmodel.LogUiState> getUiState() {
        return null;
    }
    
    private final void ensureAnonymousAuth() {
    }
    
    public final void onFoodTextChanged(@org.jetbrains.annotations.NotNull()
    java.lang.String newText) {
    }
    
    public final void setMealType(@org.jetbrains.annotations.NotNull()
    com.serene.logcal.model.MealType newMealType) {
    }
    
    public final void setSelectedDate(@org.jetbrains.annotations.NotNull()
    java.time.LocalDate newDate) {
    }
    
    public final void logMeal() {
    }
}