package com.serene.logcal.ui.dashboard

import android.app.DatePickerDialog
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
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
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

@Composable
fun DashboardScreen(viewModel: DashboardViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val selectedDate by viewModel.selectedDate.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

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
        isOverGoal -> "${(uiState.todayCalories - uiState.dailyGoal)} cal over target"
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
                detectDragGestures(
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
                    onDrag = { change, dragAmount ->
                        change.consume()
                        dragAccumulator += dragAmount.x
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
            horizontalArrangement = Arrangement.SpaceBetween,
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

            Column(
                modifier = Modifier
                    .weight(1f)
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
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Today's Calories", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold, color = LogCalTheme.colors.primaryText)
                    Text(
                        text = uiState.todayCalories.toString(),
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 56.sp),
                        fontWeight = FontWeight.Bold,
                        color = LogCalTheme.colors.primaryText
                    )
                    Text("of ${uiState.dailyGoal} cal", style = MaterialTheme.typography.titleMedium, color = LogCalTheme.colors.mutedText)
                }
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = LogCalTheme.colors.quietText)
                    RingProgress(
                        progress = progress,
                        percentageText = "${(progress * 100f).roundToInt()}%",
                        size = 96.dp,
                        stroke = 10.dp,
                        progressColor = LogCalTheme.colors.primaryGreen
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Remaining", color = LogCalTheme.colors.mutedText, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "${uiState.remainingCalories} cal",
                    color = LogCalTheme.colors.primaryGreen,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        // 5. Today's Macros Card
        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Today's Macros", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold, color = LogCalTheme.colors.primaryText)
                Spacer(modifier = Modifier.weight(1f))
                Icon(Icons.Default.PieChart, contentDescription = null, tint = LogCalTheme.colors.quietText)
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
                Text("This Week", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold, color = LogCalTheme.colors.primaryText)
                Spacer(modifier = Modifier.weight(1f))
                Icon(Icons.Default.QueryStats, contentDescription = null, tint = LogCalTheme.colors.quietText)
            }
            Spacer(modifier = Modifier.height(12.dp))
            WeeklyBarChart(
                values = uiState.weeklyStats.map { it.calories },
                labels = uiState.weeklyStats.map { it.date.dayOfWeek.name.lowercase().replaceFirstChar { c -> c.uppercase() }.take(3) },
                selectedIdx = uiState.weeklyStats.indexOfFirst { it.date == selectedDate }
            )
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Weekly Average", color = LogCalTheme.colors.mutedText, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "${uiState.weeklyAverageCalories} cal",
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
                value = uiState.dailyGoal.toString(),
                suffix = "calories"
            ) {
                DailyGoalInlineEditor(
                    currentGoal = uiState.dailyGoal,
                    onSaveGoal = { viewModel.setDailyGoal(it) }
                )
            }
            SmallStatTile(
                modifier = Modifier.weight(1f),
                icon = { Icon(Icons.Default.TrendingUp, contentDescription = null, tint = LogCalTheme.colors.mintGreen) },
                title = "Streak",
                value = uiState.streakDays.toString(),
                suffix = "days"
            )
        }
    }
}

@Composable
private fun AppCard(content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
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
private fun RingProgress(progress: Float, percentageText: String, size: Dp, stroke: Dp, progressColor: Color) {
    Box(contentAlignment = Alignment.Center, modifier = Modifier.size(size)) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val strokePx = stroke.toPx()
            val arcSize = Size(size.toPx() - strokePx, size.toPx() - strokePx)
            val topLeft = Offset(strokePx / 2, strokePx / 2)
            drawArc(
                color = Color(0xFFE8E8E8),
                startAngle = -210f,
                sweepAngle = 240f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
            drawArc(
                color = progressColor,
                startAngle = -210f,
                sweepAngle = 240f * progress.coerceIn(0f, 1f),
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
        }
        Text(percentageText, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = LogCalTheme.colors.primaryText)
    }
}

@Composable
private fun WeeklyBarChart(values: List<Int>, labels: List<String>, selectedIdx: Int) {
    val max = values.maxOrNull()?.coerceAtLeast(1) ?: 1
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Bottom) {
        values.forEachIndexed { idx, value ->
            val heightDp = (value.toFloat() / max.toFloat() * 72f).coerceAtLeast(4f).dp
            val isSelected = idx == selectedIdx
            val barColor = if (isSelected) LogCalTheme.colors.primaryGreen else LogCalTheme.colors.mintGreen.copy(alpha = 0.5f)
            
            Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(modifier = Modifier.height(74.dp).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
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
private fun DailyGoalInlineEditor(currentGoal: Int, onSaveGoal: (Int) -> Unit) {
    var value by remember(currentGoal) { mutableStateOf(currentGoal.toString()) }
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(
            value = value,
            onValueChange = { next -> value = next.filter { it.isDigit() }.take(5) },
            modifier = Modifier.weight(1f),
            label = { Text("Goal") },
            singleLine = true
        )
        Button(
            onClick = { value.toIntOrNull()?.let(onSaveGoal) },
            modifier = Modifier.widthIn(min = 72.dp)
        ) {
            Text("Set")
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
    footer: (@Composable () -> Unit)? = null
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = LogCalTheme.colors.cardBackground),
        border = androidx.compose.foundation.BorderStroke(1.dp, LogCalTheme.colors.cardBorder)
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            icon()
            Text(title, style = MaterialTheme.typography.titleMedium, color = LogCalTheme.colors.mutedText, textAlign = TextAlign.Center)
            Text(value, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold, color = LogCalTheme.colors.primaryText)
            Text(suffix, style = MaterialTheme.typography.bodyLarge, color = LogCalTheme.colors.mutedText)
            footer?.invoke()
        }
    }
}
