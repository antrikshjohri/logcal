package com.serene.logcal.ui;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000J\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\u001a\u001e\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u00052\f\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00030\u0007H\u0003\u001a\u0010\u0010\b\u001a\u00020\u00032\u0006\u0010\t\u001a\u00020\nH\u0007\u001a\u0010\u0010\u000b\u001a\u00020\u00032\u0006\u0010\f\u001a\u00020\rH\u0003\u001a\u0010\u0010\u000e\u001a\u00020\u000f2\u0006\u0010\u0010\u001a\u00020\u0011H\u0002\u001a$\u0010\u0012\u001a\u00020\u00032\u0006\u0010\u0010\u001a\u00020\u00112\u0012\u0010\u0013\u001a\u000e\u0012\u0004\u0012\u00020\u0015\u0012\u0004\u0012\u00020\u00030\u0014H\u0002\u001a\u001c\u0010\u0016\u001a\u00020\u0003*\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00012\u0006\u0010\u0019\u001a\u00020\u0001H\u0003\"\u000e\u0010\u0000\u001a\u00020\u0001X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001a"}, d2 = {"LOG_MEAL_LOADING_LABEL", "", "LogIconButton", "", "icon", "Landroidx/compose/ui/graphics/vector/ImageVector;", "onClick", "Lkotlin/Function0;", "LogMealScreen", "viewModel", "Lcom/serene/logcal/viewmodel/LogViewModel;", "ResultCard", "result", "Lcom/serene/logcal/model/MealLogResponse;", "createTempImageUri", "Landroid/net/Uri;", "context", "Landroid/content/Context;", "launchSpeechInput", "launch", "Lkotlin/Function1;", "Landroid/content/Intent;", "MacroBlock", "Landroidx/compose/foundation/layout/RowScope;", "label", "value", "app_debug"})
public final class LogMealScreenKt {
    
    /**
     * Shown next to the spinner while `logMeal` is in flight (single line; low latency).
     */
    @org.jetbrains.annotations.NotNull()
    private static final java.lang.String LOG_MEAL_LOADING_LABEL = "Analyzing your meal\u2026";
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable()
    public static final void LogMealScreen(@org.jetbrains.annotations.NotNull()
    com.serene.logcal.viewmodel.LogViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void LogIconButton(androidx.compose.ui.graphics.vector.ImageVector icon, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ResultCard(com.serene.logcal.model.MealLogResponse result) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void MacroBlock(androidx.compose.foundation.layout.RowScope $this$MacroBlock, java.lang.String label, java.lang.String value) {
    }
    
    private static final android.net.Uri createTempImageUri(android.content.Context context) {
        return null;
    }
    
    private static final void launchSpeechInput(android.content.Context context, kotlin.jvm.functions.Function1<? super android.content.Intent, kotlin.Unit> launch) {
    }
}