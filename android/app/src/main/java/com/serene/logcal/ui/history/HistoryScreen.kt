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
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import com.serene.logcal.data.local.PreferenceManager
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

    val preferenceManager = remember { PreferenceManager(context) }
    val dailyGoal = remember { preferenceManager.dailyGoal }

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

    var showBulkDeleteDialog by remember { mutableStateOf(false) }
    val isAnonymous = FirebaseAuth.getInstance().currentUser?.isAnonymous == true

    Scaffold(
        containerColor = colors.background
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .statusBarsPadding()
                .fillMaxSize()
                .background(colors.background)
        ) {
            // Edit / Cancel Pill Button (Top Left)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(
                    onClick = {
                        editMode = !editMode
                        selectedIds = emptySet()
                    },
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.textButtonColors(
                        containerColor = colors.cardBackground,
                        contentColor = colors.primaryGreen
                    ),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                    modifier = Modifier.shadow(1.dp, RoundedCornerShape(20.dp))
                ) {
                    Text(
                        text = if (editMode) "Cancel" else "Edit",
                        fontWeight = FontWeight.Medium
                    )
                }

                if (editMode) {
                    TextButton(
                        onClick = {
                            if (selectedIds.isNotEmpty()) showBulkDeleteDialog = true
                        },
                        enabled = selectedIds.isNotEmpty(),
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = colors.dangerRed,
                            disabledContentColor = colors.mutedText
                        )
                    ) {
                        Text(
                            text = "Delete (${selectedIds.size})",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Screen Title
            Text(
                text = "History",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
            )

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
                shape = RoundedCornerShape(24.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = Color.Transparent,
                    unfocusedBorderColor = Color.Transparent,
                    focusedContainerColor = colors.cardBackground,
                    unfocusedContainerColor = colors.cardBackground,
                    focusedTextColor = colors.primaryText,
                    unfocusedTextColor = colors.primaryText
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
                contentPadding = PaddingValues(bottom = 100.dp),
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
                        onMealClick = onMealClick,
                        dailyGoal = dailyGoal
                    )
                }
            }
        }
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
private fun CalorieStatusIcon(
    isOverGoal: Boolean,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors
    val (bgColor, iconChar) = if (isOverGoal) {
        Pair(colors.warningAmber, "!")
    } else {
        Pair(colors.primaryGreen, "✓")
    }

    Box(
        modifier = modifier
            .size(16.dp)
            .clip(CircleShape)
            .background(bgColor),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = iconChar,
            color = Color.White,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            lineHeight = 10.sp
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
    dailyGoal: Double
) {
    val colors = LogCalTheme.colors
    val title = daySectionTitle(section.date, zone)

    // Calculate sum macros for header
    val sumProtein = section.meals.mapNotNull { it.response.protein }.sum()
    val sumCarbs = section.meals.mapNotNull { it.response.carbs }.sum()
    val sumFat = section.meals.mapNotNull { it.response.fat }.sum()

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
                    .clickable { onToggleExpand() }
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    if (section.isToday) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(colors.primaryGreen)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val isOverGoal = section.totalCalories > dailyGoal
                    CalorieStatusIcon(isOverGoal = isOverGoal)
                    
                    Text(
                        text = "${NumberUtils.formatNumber(section.totalCalories.toInt())} cal",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (isOverGoal) colors.warningAmber else colors.primaryGreen
                    )

                    Icon(
                        imageVector = if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                        contentDescription = null,
                        tint = colors.mutedText,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            if (expanded) {
                Spacer(modifier = Modifier.height(8.dp))
                
                // Day Total Row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(colors.mutedText.copy(alpha = 0.08f))
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Day Total",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "P: ${sumProtein.toInt()}g  ·  C: ${sumCarbs.toInt()}g  ·  F: ${sumFat.toInt()}g",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        fontWeight = FontWeight.Medium
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
                HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f))
                Spacer(modifier = Modifier.height(8.dp))

                if (section.meals.isEmpty()) {
                    Text(
                        text = if (section.isToday) "No meals logged today yet." else "No meals logged on this day.",
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

    val p = meal.response.protein
    val c = meal.response.carbs
    val f = meal.response.fat
    val macroCompact = buildString {
        if (p != null) append("P: ${p.toInt()}g")
        if (c != null) {
            if (isNotEmpty()) append("  ·  ")
            append("C: ${c.toInt()}g")
        }
        if (f != null) {
            if (isNotEmpty()) append("  ·  ")
            append("F: ${f.toInt()}g")
        }
    }

    val mealTypeLower = meal.mealType.lowercase(Locale.ROOT)
    val (emoji, displayLabel) = when (mealTypeLower) {
        "breakfast" -> Pair("🌅", "Breakfast")
        "lunch" -> Pair("☀️", "Lunch")
        "dinner" -> Pair("🌙", "Dinner")
        "snack" -> Pair("🌿", "Snack")
        else -> Pair("🍽️", meal.mealType.replaceFirstChar { it.uppercase() })
    }

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
                    text = meal.foodText,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
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
                        text = "$emoji $displayLabel",
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.primaryGreen,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (macroCompact.isNotEmpty()) {
                    Text(
                        text = macroCompact,
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.warningAmber,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = "${NumberUtils.formatNumber(meal.totalCalories.toInt())} cal",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = colors.primaryGreen
        )
    }
}

private fun daySectionTitle(date: LocalDate, zone: ZoneId): String {
    val today = LocalDate.now(zone)
    val fmt = DateTimeFormatter.ofPattern("EEE, MMM d")
    return when (date) {
        today -> "Today"
        today.minusDays(1) -> "Yesterday"
        today.plusDays(1) -> "Tomorrow"
        else -> date.format(fmt)
    }
}
