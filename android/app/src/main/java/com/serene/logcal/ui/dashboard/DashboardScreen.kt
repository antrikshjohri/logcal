package com.serene.logcal.ui.dashboard

import android.app.DatePickerDialog
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.QueryStats
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.graphics.Brush
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import com.serene.logcal.ui.profile.DailyGoalScreen
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.model.DietStyle
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.viewmodel.dashboard.DashboardViewModel
import com.serene.logcal.util.NumberUtils
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt
import kotlin.math.absoluteValue
import android.widget.Toast

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(viewModel: DashboardViewModel, onNavigateToHistory: () -> Unit = {}) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val selectedDate by viewModel.selectedDate.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    var showDailyGoalSheet by remember { mutableStateOf(false) }

    // Trigger rollover check when app returns to foreground
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                viewModel.checkAndResetSelectedDateIfNeeded()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    LaunchedEffect(Unit) {
        viewModel.checkAndResetSelectedDateIfNeeded()
    }

    if (uiState.isLoading) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = LogCalTheme.colors.primaryGreen)
        }
        return
    }

    val progress = if (uiState.dailyGoal > 0) {
        (uiState.todayCalories.toFloat() / uiState.dailyGoal.toFloat()).coerceIn(0f, 1f)
    } else 0f

    val isAnonymous = FirebaseAuth.getInstance().currentUser?.isAnonymous == true
    val isOverGoal = uiState.todayCalories > uiState.dailyGoal
    val dailyStatusColor = if (isOverGoal) LogCalTheme.colors.warningAmber else LogCalTheme.colors.primaryGreen

    val statusCardTitle = when {
        uiState.dailyGoal <= 0 -> "Set a daily goal"
        isOverGoal -> "Over your daily target"
        else -> "On track for your goal"
    }

    val statusCardSubtitle = when {
        uiState.dailyGoal <= 0 -> "Track your progress by setting a goal."
        isOverGoal -> "${NumberUtils.formatNumber((uiState.todayCalories - uiState.dailyGoal).toInt())} cal over target"
        else -> "Great choices so far today!"
    }

    // Format date headers
    val displayDateTitle = when (selectedDate) {
        LocalDate.now() -> "Today"
        LocalDate.now().minusDays(1) -> "Yesterday"
        LocalDate.now().plusDays(1) -> "Tomorrow"
        else -> selectedDate.format(DateTimeFormatter.ofPattern("EEEE", Locale.getDefault()))
    }
    val formattedDateText = selectedDate.format(DateTimeFormatter.ofPattern("MMMM d, yyyy", Locale.getDefault()))

    var dragAccumulator by remember { mutableStateOf(0f) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(LogCalTheme.colors.background)
            .verticalScroll(rememberScrollState())
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = {
                        val threshold = 100f
                        if (dragAccumulator > threshold) {
                            viewModel.changeDate(-1)
                        } else if (dragAccumulator < -threshold) {
                            val isToday = selectedDate == LocalDate.now()
                            if (!isToday) {
                                viewModel.changeDate(1)
                            }
                        }
                        dragAccumulator = 0f
                    },
                    onHorizontalDrag = { change, dragAmount ->
                        change.consume()
                        dragAccumulator += dragAmount
                    }
                )
            }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 1. Date Header Navigation
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(LogCalTheme.colors.softAccentBackground)
                    .clickable { viewModel.changeDate(-1) },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.ChevronLeft,
                    contentDescription = "Previous Day",
                    tint = LogCalTheme.colors.primaryGreen,
                    modifier = Modifier.size(18.dp)
                )
            }

            Spacer(modifier = Modifier.width(24.dp))

            Column(
                modifier = Modifier
                    .clickable {
                        DatePickerDialog(
                            context,
                            { _, y, m, d -> viewModel.setSelectedDate(LocalDate.of(y, m + 1, d)) },
                            selectedDate.year,
                            selectedDate.monthValue - 1,
                            selectedDate.dayOfMonth
                        ).show()
                    },
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = displayDateTitle,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = LogCalTheme.colors.primaryText
                )
                Text(
                    text = formattedDateText,
                    style = MaterialTheme.typography.bodySmall,
                    color = LogCalTheme.colors.mutedText
                )
            }

            Spacer(modifier = Modifier.width(24.dp))

            val isToday = selectedDate == LocalDate.now()
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(if (isToday) Color.Transparent else LogCalTheme.colors.softAccentBackground)
                    .clickable(enabled = !isToday) { viewModel.changeDate(1) },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "Next Day",
                    tint = if (isToday) LogCalTheme.colors.mutedText.copy(alpha = 0.3f) else LogCalTheme.colors.primaryGreen,
                    modifier = Modifier.size(18.dp)
                )
            }
        }

        // 2. Guest Warning Banner
        if (isAnonymous) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(LogCalTheme.colors.cardBackground)
                    .border(1.dp, LogCalTheme.colors.cardBorder, RoundedCornerShape(12.dp))
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Cloud,
                    contentDescription = "Warning",
                    tint = LogCalTheme.colors.warningAmber,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Cloud backup is disabled in Guest Mode.",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = LogCalTheme.colors.primaryText,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = "Sign In",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = LogCalTheme.colors.primaryGreen,
                    modifier = Modifier.clickable {
                        FirebaseAuth.getInstance().signOut()
                    }
                )
            }
        }

        // 3. Status Card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(dailyStatusColor.copy(alpha = if (MaterialTheme.colorScheme.background.red < 0.5f) 0.15f else 0.08f))
                .border(1.dp, dailyStatusColor.copy(alpha = 0.18f), RoundedCornerShape(12.dp))
                .padding(horizontal = 16.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .background(dailyStatusColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isOverGoal) Icons.Default.Warning else Icons.Default.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(14.dp)
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = statusCardTitle,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = LogCalTheme.colors.primaryText
                )
                Text(
                    text = statusCardSubtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = LogCalTheme.colors.mutedText
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                imageVector = Icons.Default.Eco,
                contentDescription = null,
                tint = dailyStatusColor.copy(alpha = 0.25f),
                modifier = Modifier.size(28.dp)
            )
        }

        // 4. Calories Card
        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = NumberUtils.formatNumber(uiState.todayCalories.toInt()),
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 56.sp),
                        fontWeight = FontWeight.Bold,
                        color = LogCalTheme.colors.primaryText
                    )
                    Text("of ${NumberUtils.formatNumber(uiState.dailyGoal.toInt())} cal", style = MaterialTheme.typography.titleMedium, color = LogCalTheme.colors.mutedText)
                }
                RingProgress(
                    progress = progress,
                    percentageText = "${(progress * 100f).roundToInt()}%",
                    size = 96.dp,
                    stroke = 10.dp,
                    progressColor = LogCalTheme.colors.primaryGreen,
                    showLeaf = true
                )
            }
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            
            val diff = (uiState.todayCalories - uiState.dailyGoal).toInt()
            val statusColor = if (isOverGoal) LogCalTheme.colors.warningAmber else LogCalTheme.colors.primaryGreen
            val highlightText = if (isOverGoal) {
                "${NumberUtils.formatNumber(diff.absoluteValue)} cal overdue"
            } else {
                "${NumberUtils.formatNumber(uiState.remainingCalories.toInt().coerceAtLeast(0))} cal remaining"
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(statusColor.copy(alpha = 0.15f))
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .background(statusColor, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (isOverGoal) Icons.Default.Warning else Icons.Default.Check,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(14.dp)
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = highlightText,
                    color = statusColor,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // 5. Today's Macros Card
        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "Macros",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = LogCalTheme.colors.primaryText
                )
                Spacer(modifier = Modifier.weight(1f))
                Row(
                    modifier = Modifier.clickable { onNavigateToHistory() },
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Details",
                        color = LogCalTheme.colors.primaryGreen,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.width(2.dp))
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = "Details",
                        tint = LogCalTheme.colors.primaryGreen,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                MacroCard("Protein", "${uiState.proteinGrams}g", uiState.macroProteinPercent, LogCalTheme.colors.protein)
                MacroCard("Carbs", "${uiState.carbsGrams}g", uiState.macroCarbsPercent, LogCalTheme.colors.carbs)
                MacroCard("Fat", "${uiState.fatGrams}g", uiState.macroFatPercent, LogCalTheme.colors.fat)
            }
        }

        // 6. Weekly Chart Card
        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "Weekly trend",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = LogCalTheme.colors.primaryText
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "Total calories",
                    style = MaterialTheme.typography.bodySmall,
                    color = LogCalTheme.colors.mutedText
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
            WeeklyBarChart(
                values = uiState.weeklyStats.map { it.calories },
                labels = uiState.weeklyStats.map { it.date.dayOfWeek.name.lowercase().replaceFirstChar { c -> c.uppercase() }.take(3) },
                selectedIdx = uiState.weeklyStats.indexOfFirst { it.date == selectedDate },
                onBarSelected = { idx ->
                    uiState.weeklyStats.getOrNull(idx)?.let { stat ->
                        viewModel.setSelectedDate(stat.date)
                    }
                }
            )
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Weekly Average", color = LogCalTheme.colors.mutedText, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "${NumberUtils.formatNumber(uiState.weeklyAverageCalories.toInt())} cal",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = LogCalTheme.colors.primaryText
                )
            }
        }

        // 7. Daily Goal & Streak Tiles
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SmallStatTile(
                modifier = Modifier.weight(1f),
                icon = { Icon(Icons.Default.TrackChanges, contentDescription = null, tint = LogCalTheme.colors.primaryGreen) },
                title = "Daily Goal",
                value = NumberUtils.formatNumber(uiState.dailyGoal.toInt()),
                suffix = "calories",
                onClick = { showDailyGoalSheet = true }
            )
            
            val hasStreak = uiState.streakDays > 0
            val streakBrush = if (hasStreak) {
                Brush.linearGradient(
                    colors = listOf(Color(0xFFFF5E3A), Color(0xFFFF2A68))
                )
            } else null
            
            SmallStatTile(
                modifier = Modifier.weight(1f),
                icon = { 
                    Icon(
                        imageVector = if (hasStreak) Icons.Default.Whatshot else Icons.Default.TrendingUp,
                        contentDescription = null,
                        tint = if (hasStreak) Color.White else LogCalTheme.colors.mintGreen,
                        modifier = Modifier.size(24.dp)
                    )
                },
                title = "Streak",
                value = uiState.streakDays.toString(),
                suffix = if (uiState.streakDays == 1) "day" else "days",
                backgroundBrush = streakBrush,
                contentColor = if (hasStreak) Color.White else null
            )
        }
    }

    if (showDailyGoalSheet) {
        ModalBottomSheet(
            onDismissRequest = { showDailyGoalSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            windowInsets = BottomSheetDefaults.windowInsets
        ) {
            DailyGoalScreen(
                onBack = { showDailyGoalSheet = false },
                onNavigateToQuestionnaire = {
                    showDailyGoalSheet = false
                    Toast.makeText(context, "Go to Profile tab to use the Questionnaire helper", Toast.LENGTH_LONG).show()
                }
            )
        }
    }
}

@Composable
private fun AppCard(content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 6.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = LogCalTheme.colors.shadowColor,
                spotColor = LogCalTheme.colors.shadowColor
            ),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = LogCalTheme.colors.cardBackground),
        border = androidx.compose.foundation.BorderStroke(1.dp, LogCalTheme.colors.cardBorder)
    ) {
        Column(modifier = Modifier.padding(16.dp), content = content)
    }
}

@Composable
private fun SeparatorLine() {
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(LogCalTheme.colors.cardBorder))
}

@Composable
private fun RowScope.MacroCard(label: String, value: String, percent: Int, progressColor: Color) {
    Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = LogCalTheme.colors.primaryText)
        Text(label, style = MaterialTheme.typography.titleMedium, color = LogCalTheme.colors.mutedText)
        Spacer(modifier = Modifier.height(6.dp))
        RingProgress(
            progress = (percent / 100f).coerceIn(0f, 1f),
            percentageText = "${percent.coerceAtMost(999)}%",
            size = 74.dp,
            stroke = 8.dp,
            progressColor = progressColor
        )
    }
}

@Composable
private fun RingProgress(
    progress: Float,
    percentageText: String,
    size: Dp,
    stroke: Dp,
    progressColor: Color,
    showLeaf: Boolean = false
) {
    val cardBorderColor = LogCalTheme.colors.cardBorder
    Box(contentAlignment = Alignment.Center, modifier = Modifier.size(size)) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val strokePx = stroke.toPx()
            val arcSize = Size(size.toPx() - strokePx, size.toPx() - strokePx)
            val topLeft = Offset(strokePx / 2, strokePx / 2)
            drawArc(
                color = cardBorderColor,
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
            drawArc(
                color = progressColor,
                startAngle = -90f,
                sweepAngle = 360f * progress.coerceIn(0f, 1f),
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
        }
        if (showLeaf) {
            Icon(
                imageVector = Icons.Default.Eco,
                contentDescription = null,
                tint = progressColor,
                modifier = Modifier.size(size * 0.4f)
            )
        } else {
            Text(percentageText, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = LogCalTheme.colors.primaryText)
        }
    }
}

@Composable
private fun WeeklyBarChart(
    values: List<Int>,
    labels: List<String>,
    selectedIdx: Int,
    onBarSelected: (Int) -> Unit
) {
    val max = values.maxOrNull()?.coerceAtLeast(1) ?: 1
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        values.forEachIndexed { idx, value ->
            val heightDp = (value.toFloat() / max.toFloat() * 60f).coerceAtLeast(4f).dp
            val isSelected = idx == selectedIdx
            val barColor = if (isSelected) LogCalTheme.colors.primaryGreen else LogCalTheme.colors.mintGreen.copy(alpha = 0.5f)
            
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onBarSelected(idx) },
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Calorie label above the bar (only if selected)
                Box(
                    modifier = Modifier.height(18.dp),
                    contentAlignment = Alignment.Center
                ) {
                    if (isSelected && value > 0) {
                        Text(
                            text = NumberUtils.formatNumber(value),
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 10.sp),
                            fontWeight = FontWeight.Bold,
                            color = LogCalTheme.colors.primaryText,
                            maxLines = 1
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                Box(modifier = Modifier.height(60.dp).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(heightDp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(barColor)
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = labels.getOrElse(idx) { "-" },
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                    color = if (isSelected) LogCalTheme.colors.primaryText else LogCalTheme.colors.mutedText
                )
            }
        }
    }
}

@Composable
private fun SmallStatTile(
    modifier: Modifier = Modifier,
    icon: @Composable () -> Unit,
    title: String,
    value: String,
    suffix: String,
    backgroundBrush: Brush? = null,
    contentColor: Color? = null,
    onClick: (() -> Unit)? = null,
    footer: (@Composable () -> Unit)? = null
) {
    val finalContentColor = contentColor ?: LogCalTheme.colors.primaryText
    val finalMutedColor = contentColor ?: LogCalTheme.colors.mutedText

    Card(
        modifier = modifier
            .shadow(
                elevation = 4.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = LogCalTheme.colors.shadowColor,
                spotColor = LogCalTheme.colors.shadowColor
            )
            .let {
                if (onClick != null) it.clickable { onClick() } else it
            },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (backgroundBrush == null) LogCalTheme.colors.cardBackground else Color.Transparent
        ),
        border = if (backgroundBrush == null) androidx.compose.foundation.BorderStroke(1.dp, LogCalTheme.colors.cardBorder) else null
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .let {
                    if (backgroundBrush != null) it.background(backgroundBrush) else it
                }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                icon()
                Text(title, style = MaterialTheme.typography.titleMedium, color = finalMutedColor, textAlign = TextAlign.Center)
                Text(value, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold, color = finalContentColor)
                Text(suffix, style = MaterialTheme.typography.bodyLarge, color = finalMutedColor)
                footer?.invoke()
            }
        }
    }
}
