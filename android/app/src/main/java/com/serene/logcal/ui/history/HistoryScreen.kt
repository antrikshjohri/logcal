package com.serene.logcal.ui.history

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.util.HistoryDaySection
import com.serene.logcal.util.buildDaySections
import com.serene.logcal.viewmodel.history.HistoryViewModel
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel,
    onNavigateToLogTab: () -> Unit = {},
) {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = "history_list") {
        composable("history_list") {
            HistoryListScreen(
                viewModel = viewModel,
                onNavigateToLogTab = onNavigateToLogTab,
                onMealClick = { mealId ->
                    DebugLogger.d("DEBUG: [HistoryScreen] navigate to detail mealId=$mealId")
                    navController.navigate("meal_detail/$mealId")
                },
            )
        }
        composable(
            route = "meal_detail/{mealId}",
            arguments = listOf(navArgument("mealId") { type = NavType.StringType }),
        ) { entry ->
            val mealId = entry.arguments?.getString("mealId") ?: return@composable
            MealDetailScreen(
                mealId = mealId,
                viewModel = viewModel,
                onBack = { navController.popBackStack() },
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HistoryListScreen(
    viewModel: HistoryViewModel,
    onNavigateToLogTab: () -> Unit,
    onMealClick: (String) -> Unit,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var lastErrorShown: String? by remember { mutableStateOf(null) }

    var editMode by remember { mutableStateOf(false) }
    var selectedIds by remember { mutableStateOf(setOf<String>()) }
    var collapsedDates by remember { mutableStateOf(setOf<String>()) }
    var showClearAllDialog by remember { mutableStateOf(false) }
    var showBulkDeleteDialog by remember { mutableStateOf(false) }

    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    val zone = ZoneId.systemDefault()
    val sections = remember(uiState.meals) { buildDaySections(uiState.meals, zone) }

    LaunchedEffect(editMode) {
        if (editMode) {
            DebugLogger.d("DEBUG: [HistoryListScreen] editMode=true expand all sections")
            collapsedDates = emptySet()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("History") },
                actions = {
                    if (!editMode) {
                        IconButton(
                            onClick = { showClearAllDialog = true },
                            enabled = uiState.meals.isNotEmpty(),
                        ) {
                            Icon(Icons.Default.DeleteSweep, contentDescription = "Clear all")
                        }
                        TextButton(
                            onClick = {
                                editMode = true
                                selectedIds = emptySet()
                                DebugLogger.d("DEBUG: [HistoryListScreen] entered edit mode")
                            },
                            enabled = uiState.meals.isNotEmpty(),
                        ) { Text("Edit") }
                    } else {
                        TextButton(
                            onClick = {
                                editMode = false
                                selectedIds = emptySet()
                                DebugLogger.d("DEBUG: [HistoryListScreen] cancelled edit mode")
                            },
                        ) { Text("Cancel") }
                        TextButton(
                            onClick = {
                                if (selectedIds.isNotEmpty()) showBulkDeleteDialog = true
                            },
                            enabled = selectedIds.isNotEmpty(),
                        ) { Text("Delete (${selectedIds.size})") }
                    }
                },
            )
        },
    ) { padding ->
        if (uiState.isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(Color(0xFFF2F2F6)),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        if (uiState.meals.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(Color(0xFFF2F2F6))
                    .padding(20.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("No meals logged yet", style = MaterialTheme.typography.titleMedium)
                Text(
                    "Log meals from the Log tab and they will appear here.",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(top = 8.dp),
                )
                Button(
                    onClick = {
                        DebugLogger.d("DEBUG: [HistoryListScreen] empty CTA -> Log tab")
                        onNavigateToLogTab()
                    },
                    modifier = Modifier.padding(top = 16.dp),
                ) { Text("Log your first meal") }
            }
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(Color(0xFFF2F2F6))
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            items(sections, key = { it.date.toString() }) { section ->
                DaySectionCard(
                    section = section,
                    zone = zone,
                    expanded = !collapsedDates.contains(section.date.toString()),
                    onToggleExpand = {
                        val key = section.date.toString()
                        collapsedDates = if (collapsedDates.contains(key)) {
                            collapsedDates - key
                        } else {
                            collapsedDates + key
                        }
                        DebugLogger.d("DEBUG: [HistoryListScreen] toggle day=$key collapsed=${collapsedDates.contains(key)}")
                    },
                    editMode = editMode,
                    selectedIds = selectedIds,
                    onToggleSelect = { id ->
                        selectedIds = if (selectedIds.contains(id)) selectedIds - id else selectedIds + id
                        DebugLogger.d("DEBUG: [HistoryListScreen] select toggle id=$id count=${selectedIds.size}")
                    },
                    onMealClick = onMealClick,
                )
            }
        }
    }

    if (showClearAllDialog) {
        AlertDialog(
            onDismissRequest = { showClearAllDialog = false },
            title = { Text("Clear all meals?") },
            text = { Text("This will remove every meal from this device.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showClearAllDialog = false
                        editMode = false
                        selectedIds = emptySet()
                        DebugLogger.d("DEBUG: [HistoryListScreen] clear all confirmed")
                        viewModel.deleteAllMeals()
                    },
                ) { Text("Clear all") }
            },
            dismissButton = {
                TextButton(onClick = { showClearAllDialog = false }) { Text("Cancel") }
            },
        )
    }

    if (showBulkDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showBulkDeleteDialog = false },
            title = { Text("Delete ${selectedIds.size} meals?") },
            text = { Text("This cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        val ids = selectedIds.toList()
                        showBulkDeleteDialog = false
                        editMode = false
                        DebugLogger.d("DEBUG: [HistoryListScreen] bulk delete count=${ids.size}")
                        viewModel.deleteMeals(ids)
                        selectedIds = emptySet()
                    },
                ) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showBulkDeleteDialog = false }) { Text("Cancel") }
            },
        )
    }
}

@Composable
private fun DaySectionCard(
    section: HistoryDaySection,
    zone: ZoneId,
    expanded: Boolean,
    onToggleExpand: () -> Unit,
    editMode: Boolean,
    selectedIds: Set<String>,
    onToggleSelect: (String) -> Unit,
    onMealClick: (String) -> Unit,
) {
    val title = daySectionTitle(section.date, zone)
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color.White),
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onToggleExpand() },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        "${section.totalCalories.toInt()} cal total",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Icon(
                    if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = if (expanded) "Collapse" else "Expand",
                )
            }
            if (expanded) {
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                if (section.meals.isEmpty()) {
                    Text(
                        if (section.isToday) "No meals logged today yet."
                        else "No meals on this day.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    if (section.isToday) {
                        Text(
                            "Tap Log to add one.",
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.padding(top = 4.dp),
                        )
                    }
                } else {
                    section.meals.forEachIndexed { index, meal ->
                        HistoryMealRow(
                            meal = meal,
                            zone = zone,
                            editMode = editMode,
                            selected = selectedIds.contains(meal.id),
                            onToggleSelect = { onToggleSelect(meal.id) },
                            onOpen = { onMealClick(meal.id) },
                        )
                        if (index < section.meals.lastIndex) {
                            HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))
                        }
                    }
                }
            }
        }
    }
}

private fun daySectionTitle(date: LocalDate, zone: ZoneId): String {
    val today = LocalDate.now(zone)
    val fmt = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.getDefault())
    return when (date) {
        today -> "Today"
        today.minusDays(1) -> "Yesterday"
        else -> date.format(fmt)
    }
}

@Composable
private fun HistoryMealRow(
    meal: HistoryMeal,
    zone: ZoneId,
    editMode: Boolean,
    selected: Boolean,
    onToggleSelect: () -> Unit,
    onOpen: () -> Unit,
) {
    val timeFmt = remember { DateTimeFormatter.ofPattern("h:mm a", Locale.getDefault()) }
    val timeText = Instant.ofEpochMilli(meal.timestampMillis).atZone(zone).toLocalTime().format(timeFmt)
    val p = meal.response.protein
    val c = meal.response.carbs
    val f = meal.response.fat
    val macroCompact = buildString {
        if (p != null) append("P ${p.toInt()}g  ")
        if (c != null) append("C ${c.toInt()}g  ")
        if (f != null) append("F ${f.toInt()}g")
    }.trim()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                if (editMode) {
                    onToggleSelect()
                } else {
                    onOpen()
                }
            }
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (editMode) {
            Checkbox(checked = selected, onCheckedChange = null)
        }
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                if (meal.hasImage) {
                    Icon(
                        Icons.Default.Image,
                        contentDescription = "Photo",
                        modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                }
                Text(
                    meal.foodText,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
            Row(
                modifier = Modifier.padding(top = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Surface(
                    color = Color(0xFFE8F0FE),
                    shape = MaterialTheme.shapes.small,
                ) {
                    Text(
                        meal.mealType.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                    )
                }
                Text(timeText, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (macroCompact.isNotEmpty()) {
                    Text(
                        macroCompact,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
        Text(
            "${meal.totalCalories.toInt()}",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF007AFF),
        )
    }
}
