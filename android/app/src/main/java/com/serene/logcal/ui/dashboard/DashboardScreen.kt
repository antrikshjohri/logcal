package com.serene.logcal.ui.dashboard

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.QueryStats
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.serene.logcal.viewmodel.dashboard.DashboardViewModel
import kotlin.math.roundToInt

@Composable
fun DashboardScreen(viewModel: DashboardViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    if (uiState.isLoading) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    val progress = if (uiState.dailyGoal > 0) {
        (uiState.todayCalories.toFloat() / uiState.dailyGoal.toFloat()).coerceIn(0f, 1f)
    } else 0f

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F7))
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text("Dashboard", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        Text("Track your daily progress", style = MaterialTheme.typography.bodyLarge, color = Color(0xFF7B7B83))

        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Today's Calories", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                    Text(
                        text = uiState.todayCalories.toString(),
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 56.sp),
                        fontWeight = FontWeight.Bold
                    )
                    Text("of ${uiState.dailyGoal} cal", style = MaterialTheme.typography.titleMedium, color = Color(0xFF7B7B83))
                }
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = Color(0xFF9A9AA1))
                    RingProgress(
                        progress = progress,
                        percentageText = "${(progress * 100f).roundToInt()}%",
                        size = 96.dp,
                        stroke = 10.dp,
                        progressColor = Color(0xFF1E9BFF)
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Remaining", color = Color(0xFF7B7B83), style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Text("${uiState.remainingCalories} cal", color = Color(0xFF1E9BFF), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            }
        }

        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Today's Macros", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.weight(1f))
                Icon(Icons.Default.PieChart, contentDescription = null, tint = Color(0xFF9A9AA1))
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                MacroCard("Protein", "${uiState.proteinGrams}g", uiState.macroProteinPercent)
                MacroCard("Carbs", "${uiState.carbsGrams}g", uiState.macroCarbsPercent)
                MacroCard("Fat", "${uiState.fatGrams}g", uiState.macroFatPercent)
            }
        }

        AppCard {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("This Week", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.weight(1f))
                Icon(Icons.Default.QueryStats, contentDescription = null, tint = Color(0xFF9A9AA1))
            }
            Spacer(modifier = Modifier.height(12.dp))
            WeeklyBarChart(
                values = uiState.weeklyStats.map { it.calories },
                labels = uiState.weeklyStats.map { it.date.dayOfWeek.name.lowercase().replaceFirstChar { c -> c.uppercase() }.take(3) }
            )
            Spacer(modifier = Modifier.height(10.dp))
            SeparatorLine()
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Weekly Average", color = Color(0xFF7B7B83), style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Text("${uiState.weeklyAverageCalories} cal", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            }
        }

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SmallStatTile(
                modifier = Modifier.weight(1f),
                icon = { Icon(Icons.Default.TrackChanges, contentDescription = null, tint = Color(0xFF1E9BFF)) },
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
                icon = { Icon(Icons.Default.TrendingUp, contentDescription = null, tint = Color(0xFF2DBE60)) },
                title = "Streak",
                value = uiState.streakDays.toString(),
                suffix = "days"
            )
        }
    }
}

@Composable
private fun AppCard(content: @Composable ColumnScope.() -> Unit) {
    Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp)) {
        Column(modifier = Modifier.padding(16.dp), content = content)
    }
}

@Composable
private fun SeparatorLine() {
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(Color(0xFFE4E4E8)))
}

@Composable
private fun RowScope.MacroCard(label: String, value: String, percent: Int) {
    Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.titleMedium, color = Color(0xFF7B7B83))
        RingProgress(
            progress = (percent / 100f).coerceIn(0f, 1f),
            percentageText = "${percent.coerceAtMost(999)}%",
            size = 74.dp,
            stroke = 8.dp,
            progressColor = Color(0xFF1E9BFF)
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
                color = Color(0xFFE3E3E6),
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
        Text(percentageText, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun WeeklyBarChart(values: List<Int>, labels: List<String>) {
    val max = values.maxOrNull()?.coerceAtLeast(1) ?: 1
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Bottom) {
        values.forEachIndexed { idx, value ->
            val heightDp = (value.toFloat() / max.toFloat() * 72f).coerceAtLeast(4f).dp
            Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(modifier = Modifier.height(74.dp).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(heightDp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(Color(0xFF38C35A))
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(labels.getOrElse(idx) { "-" }, style = MaterialTheme.typography.bodyMedium, color = Color(0xFF7B7B83))
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
    Card(modifier = modifier, shape = RoundedCornerShape(16.dp)) {
        Column(
            modifier = Modifier.padding(14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            icon()
            Text(title, style = MaterialTheme.typography.titleMedium, color = Color(0xFF7B7B83), textAlign = TextAlign.Center)
            Text(value, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
            Text(suffix, style = MaterialTheme.typography.bodyLarge, color = Color(0xFF7B7B83))
            footer?.invoke()
        }
    }
}

