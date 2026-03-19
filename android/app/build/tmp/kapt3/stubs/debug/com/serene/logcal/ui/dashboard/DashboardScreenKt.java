package com.serene.logcal.ui.dashboard;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000f\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010 \n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u001a&\u0010\u0000\u001a\u00020\u00012\u001c\u0010\u0002\u001a\u0018\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00010\u0003\u00a2\u0006\u0002\b\u0005\u00a2\u0006\u0002\b\u0006H\u0003\u001a$\u0010\u0007\u001a\u00020\u00012\u0006\u0010\b\u001a\u00020\t2\u0012\u0010\n\u001a\u000e\u0012\u0004\u0012\u00020\t\u0012\u0004\u0012\u00020\u00010\u0003H\u0003\u001a\u0010\u0010\u000b\u001a\u00020\u00012\u0006\u0010\f\u001a\u00020\rH\u0007\u001a:\u0010\u000e\u001a\u00020\u00012\u0006\u0010\u000f\u001a\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u00142\u0006\u0010\u0015\u001a\u00020\u00142\u0006\u0010\u0016\u001a\u00020\u0017H\u0003\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u0018\u0010\u0019\u001a\b\u0010\u001a\u001a\u00020\u0001H\u0003\u001aT\u0010\u001b\u001a\u00020\u00012\b\b\u0002\u0010\u001c\u001a\u00020\u001d2\u0011\u0010\u001e\u001a\r\u0012\u0004\u0012\u00020\u00010\u001f\u00a2\u0006\u0002\b\u00052\u0006\u0010 \u001a\u00020\u00122\u0006\u0010!\u001a\u00020\u00122\u0006\u0010\"\u001a\u00020\u00122\u0015\b\u0002\u0010#\u001a\u000f\u0012\u0004\u0012\u00020\u0001\u0018\u00010\u001f\u00a2\u0006\u0002\b\u0005H\u0003\u001a$\u0010$\u001a\u00020\u00012\f\u0010%\u001a\b\u0012\u0004\u0012\u00020\t0&2\f\u0010\'\u001a\b\u0012\u0004\u0012\u00020\u00120&H\u0003\u001a$\u0010(\u001a\u00020\u0001*\u00020)2\u0006\u0010*\u001a\u00020\u00122\u0006\u0010!\u001a\u00020\u00122\u0006\u0010+\u001a\u00020\tH\u0003\u0082\u0002\u0007\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006,"}, d2 = {"AppCard", "", "content", "Lkotlin/Function1;", "Landroidx/compose/foundation/layout/ColumnScope;", "Landroidx/compose/runtime/Composable;", "Lkotlin/ExtensionFunctionType;", "DailyGoalInlineEditor", "currentGoal", "", "onSaveGoal", "DashboardScreen", "viewModel", "Lcom/serene/logcal/viewmodel/dashboard/DashboardViewModel;", "RingProgress", "progress", "", "percentageText", "", "size", "Landroidx/compose/ui/unit/Dp;", "stroke", "progressColor", "Landroidx/compose/ui/graphics/Color;", "RingProgress-U-DRBZw", "(FLjava/lang/String;FFJ)V", "SeparatorLine", "SmallStatTile", "modifier", "Landroidx/compose/ui/Modifier;", "icon", "Lkotlin/Function0;", "title", "value", "suffix", "footer", "WeeklyBarChart", "values", "", "labels", "MacroCard", "Landroidx/compose/foundation/layout/RowScope;", "label", "percent", "app_debug"})
public final class DashboardScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void DashboardScreen(@org.jetbrains.annotations.NotNull()
    com.serene.logcal.viewmodel.dashboard.DashboardViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void AppCard(kotlin.jvm.functions.Function1<? super androidx.compose.foundation.layout.ColumnScope, kotlin.Unit> content) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SeparatorLine() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void MacroCard(androidx.compose.foundation.layout.RowScope $this$MacroCard, java.lang.String label, java.lang.String value, int percent) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void WeeklyBarChart(java.util.List<java.lang.Integer> values, java.util.List<java.lang.String> labels) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void DailyGoalInlineEditor(int currentGoal, kotlin.jvm.functions.Function1<? super java.lang.Integer, kotlin.Unit> onSaveGoal) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SmallStatTile(androidx.compose.ui.Modifier modifier, kotlin.jvm.functions.Function0<kotlin.Unit> icon, java.lang.String title, java.lang.String value, java.lang.String suffix, kotlin.jvm.functions.Function0<kotlin.Unit> footer) {
    }
}