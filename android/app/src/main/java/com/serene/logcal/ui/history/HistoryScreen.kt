package com.serene.logcal.ui.history

import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.util.HistoryDaySection
import com.serene.logcal.util.buildDaySections
import com.serene.logcal.util.NumberUtils
import com.serene.logcal.viewmodel.history.HistoryViewModel
import com.serene.logcal.ui.theme.LogCalTheme
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel,
    onNavigateToLogTab: () -> Unit = {}
) {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = "history_list") {
        composable("history_list") {
            HistoryListScreen(
                viewModel = viewModel,
                onNavigateToLogTab = onNavigateToLogTab,
                onMealClick = { mealId ->
                    navController.navigate("meal_edit/$mealId")
                }
            )
        }
        composable(
            route = "meal_edit/{mealId}",
            arguments = listOf(navArgument("mealId") { type = NavType.StringType })
        ) { entry ->
            val mealId = entry.arguments?.getString("mealId") ?: return@composable
            MealEditScreen(
                mealId = mealId,
                viewModel = viewModel,
                onBack = { navController.popBackStack() }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HistoryListScreen(
    viewModel: HistoryViewModel,
    onNavigateToLogTab: () -> Unit,
    onMealClick: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LogCalTheme.colors
    var lastErrorShown by remember { mutableStateOf<String?>(null) }

    var editMode by remember { mutableStateOf(false) }
    var selectedIds by remember { mutableStateOf(setOf<String>()) }

    var searchText by remember { mutableStateOf("") }

    val zone = ZoneId.systemDefault()
    val sections = remember(uiState.meals, searchText) {
        val filtered = if (searchText.isBlank()) {
            uiState.meals
        } else {
            uiState.meals.filter { it.foodText.contains(searchText, ignoreCase = true) }
        }
        buildDaySections(filtered, zone)
    }

    // Default expand logic: first two dates expanded by default, rest collapsed
    var collapsedDates by remember { mutableStateOf(setOf<String>()) }
    var hasInitializedCollapsed by remember { mutableStateOf(false) }

    LaunchedEffect(sections) {
        if (!hasInitializedCollapsed && sections.isNotEmpty()) {
            val initialCollapsed = sections.drop(2).map { it.date.toString() }.toSet()
            collapsedDates = initialCollapsed
            hasInitializedCollapsed = true
        }
    }

    LaunchedEffect(editMode) {
        if (editMode) {
            collapsedDates = emptySet()
        }
    }

    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    var showClearAllDialog by remember { mutableStateOf(false) }
    var showBulkDeleteDialog by remember { mutableStateOf(false) }
    val isAnonymous = FirebaseAuth.getInstance().currentUser?.isAnonymous == true

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("History", fontWeight = FontWeight.Bold) },
                actions = {
                    if (!editMode) {
                        IconButton(
                            onClick = { showClearAllDialog = true },
                            enabled = uiState.meals.isNotEmpty()
                        ) {
                            Icon(
                                Icons.Default.DeleteSweep,
                                contentDescription = "Clear all",
                                tint = colors.dangerRed
                            )
                        }
                        TextButton(
                            onClick = {
                                editMode = true
                                selectedIds = emptySet()
                            },
                            enabled = uiState.meals.isNotEmpty()
                        ) {
                            Text("Edit", color = colors.primaryGreen, fontWeight = FontWeight.Bold)
                        }
                    } else {
                        TextButton(
                            onClick = {
                                editMode = false
                                selectedIds = emptySet()
                            }
                        ) {
                            Text("Cancel", color = colors.primaryText)
                        }
                        TextButton(
                            onClick = {
                                if (selectedIds.isNotEmpty()) showBulkDeleteDialog = true
                            },
                            enabled = selectedIds.isNotEmpty()
                        ) {
                            Text(
                                text = "Delete (${selectedIds.size})",
                                color = if (selectedIds.isNotEmpty()) colors.dangerRed else colors.mutedText,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background, titleContentColor = colors.primaryText)
            )
        },
        containerColor = colors.background
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .background(colors.background)
        ) {
            // Search field
            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                placeholder = { Text("Search meals...", color = colors.quietText) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = colors.mutedText) },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = colors.primaryGreen,
                    unfocusedBorderColor = colors.cardBorder,
                    focusedContainerColor = colors.cardBackground,
                    unfocusedContainerColor = colors.cardBackground
                ),
                textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText)
            )

            // Anonymous guest mode warning card
            // Anonymous guest mode warning card
            if (isAnonymous) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(colors.cardBackground)
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = "Warning",
                        tint = colors.warningAmber,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Cloud backup is disabled in Guest Mode.",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = colors.primaryText,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = "Sign In",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryGreen,
                        modifier = Modifier.clickable {
                            FirebaseAuth.getInstance().signOut()
                        }
                    )
                }
            }

            if (uiState.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = colors.primaryGreen)
                }
                return@Scaffold
            }

            if (uiState.meals.isEmpty()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(CircleShape)
                            .background(colors.primaryGreen.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CalendarMonth,
                            contentDescription = null,
                            tint = colors.primaryGreen,
                            modifier = Modifier.size(40.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Text(
                        text = "No meals logged yet",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Log meals from the Log tab and they will appear here in your calendar history.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 24.dp)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = onNavigateToLogTab,
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen),
                        shape = RoundedCornerShape(24.dp),
                        modifier = Modifier.height(48.dp).padding(horizontal = 16.dp)
                    ) {
                        Text("Go to Log Tab", color = Color.White, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                    }
                }
                return@Scaffold
            }

            // History sections list
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
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
                        },
                        editMode = editMode,
                        selectedIds = selectedIds,
                        onToggleSelect = { id ->
                            selectedIds = if (selectedIds.contains(id)) selectedIds - id else selectedIds + id
                        },
                        onMealClick = onMealClick
                    )
                }
            }
        }
    }

    // Confirmation dialogs
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
                        viewModel.deleteAllMeals()
                    }
                ) { Text("Clear all", color = colors.dangerRed) }
            },
            dismissButton = {
                TextButton(onClick = { showClearAllDialog = false }) { Text("Cancel") }
            }
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
                        viewModel.deleteMeals(ids)
                        selectedIds = emptySet()
                    }
                ) { Text("Delete", color = colors.dangerRed) }
            },
            dismissButton = {
                TextButton(onClick = { showBulkDeleteDialog = false }) { Text("Cancel") }
            }
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
    onMealClick: (String) -> Unit
) {
    val colors = LogCalTheme.colors
    val title = daySectionTitle(section.date, zone)

    // Calculate sum macros for header
    val sumProtein = section.meals.mapNotNull { it.response.protein }.sum()
    val sumCarbs = section.meals.mapNotNull { it.response.carbs }.sum()
    val sumFat = section.meals.mapNotNull { it.response.fat }.sum()
    val showMacros = sumProtein > 0 || sumCarbs > 0 || sumFat > 0

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 6.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = colors.shadowColor,
                spotColor = colors.shadowColor
            ),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        border = BorderStroke(1.dp, colors.cardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onToggleExpand() },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            "${NumberUtils.formatNumber(section.totalCalories.toInt())} cal",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryGreen
                        )
                        if (showMacros) {
                            Text(
                                "· P: ${sumProtein.toInt()}g C: ${sumCarbs.toInt()}g F: ${sumFat.toInt()}g",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.mutedText
                            )
                        }
                    }
                }
                Icon(
                    if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = colors.mutedText
                )
            }

            if (expanded) {
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp), color = colors.cardBorder)
                if (section.meals.isEmpty()) {
                    Text(
                        if (section.isToday) "No meals logged today yet." else "No meals logged on this day.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                } else {
                    section.meals.forEachIndexed { index, meal ->
                        HistoryMealRow(
                            meal = meal,
                            zone = zone,
                            editMode = editMode,
                            selected = selectedIds.contains(meal.id),
                            onToggleSelect = { onToggleSelect(meal.id) },
                            onOpen = { onMealClick(meal.id) }
                        )
                        if (index < section.meals.lastIndex) {
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp), color = colors.cardBorder.copy(alpha = 0.5f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HistoryMealRow(
    meal: HistoryMeal,
    zone: ZoneId,
    editMode: Boolean,
    selected: Boolean,
    onToggleSelect: () -> Unit,
    onOpen: () -> Unit
) {
    val colors = LogCalTheme.colors
    val timeFmt = remember { DateTimeFormatter.ofPattern("h:mm a") }
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
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (editMode) {
            Checkbox(
                checked = selected,
                onCheckedChange = { onToggleSelect() },
                colors = CheckboxDefaults.colors(checkedColor = colors.primaryGreen)
            )
            Spacer(modifier = Modifier.width(6.dp))
        }

        Column(modifier = Modifier.weight(1f)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                if (meal.hasImage) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(colors.softAccentBackground)
                            .padding(4.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Image,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = colors.primaryGreen
                        )
                    }
                }
                Text(
                    meal.foodText,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = colors.primaryText,
                    modifier = Modifier.weight(1f, fill = false)
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .background(colors.softAccentBackground, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        meal.mealType.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.primaryGreen,
                        fontWeight = FontWeight.Bold
                    )
                }

                Text(
                    timeText,
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.mutedText
                )

                if (macroCompact.isNotEmpty()) {
                    Text(
                        macroCompact,
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.quietText
                    )
                }
            }
        }

        Text(
            NumberUtils.formatNumber(meal.totalCalories.toInt()),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = colors.primaryGreen
        )
    }
}

private fun daySectionTitle(date: LocalDate, zone: ZoneId): String {
    val today = LocalDate.now(zone)
    val fmt = DateTimeFormatter.ofPattern("EEEE, MMM d")
    return when (date) {
        today -> "Today"
        today.minusDays(1) -> "Yesterday"
        today.plusDays(1) -> "Tomorrow"
        else -> date.format(fmt)
    }
}
