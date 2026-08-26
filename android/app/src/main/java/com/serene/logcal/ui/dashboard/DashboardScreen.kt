package com.serene.logcal.ui.dashboard

import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import com.serene.logcal.ui.components.LogCalPullRefreshIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.HealthConnectService
import com.serene.logcal.service.HealthWorkout
import com.serene.logcal.ui.components.CalendarBottomSheet
import com.serene.logcal.ui.components.ConnectHealthDiscoveryCard
import com.serene.logcal.ui.components.TodaysActivityCard
import com.serene.logcal.ui.profile.DailyGoalScreen
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.NumberUtils
import com.serene.logcal.viewmodel.dashboard.DashboardViewModel
import com.serene.logcal.viewmodel.dashboard.WeeklyTrendNutrient
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(viewModel: DashboardViewModel, onNavigateToHistory: () -> Unit = {}) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val selectedDate by viewModel.selectedDate.collectAsStateWithLifecycle()
    val isRefreshing by viewModel.isRefreshing.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val coroutineScope = rememberCoroutineScope()

    val prefManager = remember { AppGraph.preferenceManager(context) }
    val healthConnectService = remember { HealthConnectService.getInstance(context) }

    var showDailyGoalSheet by remember { mutableStateOf(false) }
    var showCustomizeDashboardSheet by remember { mutableStateOf(false) }
    var selectedTrendNutrient by remember { mutableStateOf(WeeklyTrendNutrient.CALORIES) }
    var refreshCustomizationTrigger by remember { mutableIntStateOf(0) }

    // Health Connect data
    var isHealthAuthorized by remember { mutableStateOf(false) }
    var activeBurn by remember { mutableStateOf(0.0) }
    var basalBurn by remember { mutableStateOf(1600.0) }
    var steps by remember { mutableStateOf(0L) }
    var workouts by remember { mutableStateOf<List<HealthWorkout>>(emptyList()) }
    var dismissedHealthCard by remember { mutableStateOf(prefManager.dismissedHealthConnectCard) }

    suspend fun refreshHealthStats() {
        if (healthConnectService.isAvailable()) {
            val authorized = healthConnectService.checkPermissions()
            isHealthAuthorized = authorized
            if (authorized && prefManager.isHealthConnectEnabled) {
                activeBurn = healthConnectService.fetchActiveCalories(selectedDate)
                basalBurn = healthConnectService.fetchBasalCalories(selectedDate)
                steps = healthConnectService.fetchSteps(selectedDate)
                workouts = healthConnectService.fetchWorkouts(selectedDate)
            } else {
                activeBurn = 0.0
                basalBurn = 1600.0
                steps = 0L
                workouts = emptyList()
            }
        }
    }

    // Health Connect Permission Launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { _ ->
        coroutineScope.launch {
            val authorized = healthConnectService.checkPermissions()
            if (authorized) {
                prefManager.isHealthConnectEnabled = true
                isHealthAuthorized = true
                refreshHealthStats()
                Toast.makeText(context, "Health Connect connected!", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // Trigger rollover check and Health Connect refresh when returning to foreground
    DisposableEffect(lifecycleOwner, selectedDate) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                viewModel.checkAndResetSelectedDateIfNeeded()
                coroutineScope.launch {
                    refreshHealthStats()
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    LaunchedEffect(selectedDate) {
        viewModel.checkAndResetSelectedDateIfNeeded()
        refreshHealthStats()
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

    // Format date headers
    val displayDateTitle = when (selectedDate) {
        LocalDate.now() -> "Today"
        LocalDate.now().minusDays(1) -> "Yesterday"
        LocalDate.now().plusDays(1) -> "Tomorrow"
        else -> selectedDate.format(DateTimeFormatter.ofPattern("EEEE", Locale.getDefault()))
    }
    val formattedDateText = selectedDate.format(DateTimeFormatter.ofPattern("MMMM d, yyyy", Locale.getDefault()))

    var dragAccumulator by remember { mutableStateOf(0f) }

    val pullRefreshState = rememberPullToRefreshState()
    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = {
            viewModel.refreshData()
            coroutineScope.launch { refreshHealthStats() }
        },
        state = pullRefreshState,
        indicator = {
            LogCalPullRefreshIndicator(
                state = pullRefreshState,
                isRefreshing = isRefreshing
            )
        }
    ) {
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
                .padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // 1. Date Header Navigation
            var showDatePicker by remember { mutableStateOf(false) }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.ChevronLeft,
                    contentDescription = "Previous Day",
                    tint = LogCalTheme.colors.primaryGreen,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(LogCalTheme.colors.softAccentBackground)
                        .clickable { viewModel.changeDate(-1) }
                        .padding(8.dp)
                )

                Spacer(modifier = Modifier.width(24.dp))

                Column(
                    modifier = Modifier.clickable { showDatePicker = true },
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
                        style = MaterialTheme.typography.bodyMedium,
                        color = LogCalTheme.colors.mutedText
                    )
                }

                Spacer(modifier = Modifier.width(24.dp))

                val isToday = selectedDate == LocalDate.now()
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "Next Day",
                    tint = if (isToday) LogCalTheme.colors.mutedText.copy(alpha = 0.3f) else LogCalTheme.colors.primaryGreen,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(if (isToday) Color.Transparent else LogCalTheme.colors.softAccentBackground)
                        .clickable(enabled = !isToday) { viewModel.changeDate(1) }
                        .padding(8.dp)
                )
            }

            if (showDatePicker) {
                CalendarBottomSheet(
                    initialDate = selectedDate,
                    onDateSelected = { viewModel.setSelectedDate(it) },
                    onDismiss = { showDatePicker = false }
                )
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

            // Standalone Status Card (1:1 with iOS Status Card)
            val isOverGoal = uiState.todayCalories > uiState.dailyGoal && uiState.dailyGoal > 0
            val dailyStatusColor = if (isOverGoal) LogCalTheme.colors.warningAmber else LogCalTheme.colors.primaryGreen
            val statusCardTitle = when {
                uiState.dailyGoal <= 0 -> "Set a daily goal"
                isOverGoal -> "Over your daily target"
                else -> "On track for your goal"
            }
            val statusCardSubtitle = when {
                uiState.dailyGoal <= 0 -> "Track your progress by setting a goal."
                isOverGoal -> "${uiState.todayCalories - uiState.dailyGoal} cal over target"
                else -> "Great choices so far today!"
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(dailyStatusColor.copy(alpha = 0.10f))
                    .border(1.dp, dailyStatusColor.copy(alpha = 0.20f), RoundedCornerShape(16.dp))
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(dailyStatusColor),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (isOverGoal) Icons.Default.Warning else Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text(
                        text = statusCardTitle,
                        style = MaterialTheme.typography.titleMedium.copy(fontSize = 15.sp),
                        fontWeight = FontWeight.Bold,
                        color = LogCalTheme.colors.primaryText
                    )
                    Text(
                        text = statusCardSubtitle,
                        style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp),
                        color = LogCalTheme.colors.mutedText
                    )
                }

                Icon(
                    imageVector = Icons.Default.Eco,
                    contentDescription = null,
                    tint = dailyStatusColor.copy(alpha = 0.35f),
                    modifier = Modifier.size(28.dp)
                )
            }

            // Read dynamic section order from preferences
            val sectionKeys = prefManager.dashboardSectionOrder.split(",").mapNotNull { DashboardSectionType.fromId(it.trim()) }
            val completeSections = sectionKeys.toMutableList()
            DashboardSectionType.entries.forEach { if (!completeSections.contains(it)) completeSections.add(it) }

            // Render sections in custom user order
            completeSections.forEach { sectionType ->
                when (sectionType) {
                    DashboardSectionType.CALORIES -> {
                        if (prefManager.showDashboardCalories) {
                            // 3. Status & Calories Card (matching iOS TodaysCaloriesCard)
                            AppCard {
                                // Top Row: Calories Eaten (Left) & Progress Ring with leaf (Right)
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = NumberUtils.formatNumber(uiState.todayCalories),
                                            fontSize = 48.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = LogCalTheme.colors.primaryText,
                                            letterSpacing = (-1).sp
                                        )
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = "of ${NumberUtils.formatNumber(uiState.dailyGoal)} cal eaten",
                                            fontSize = 15.sp,
                                            fontWeight = FontWeight.Medium,
                                            color = LogCalTheme.colors.mutedText
                                        )
                                    }

                                    // Progress Ring with nested leaf & percentage
                                    Box(contentAlignment = Alignment.Center, modifier = Modifier.size(90.dp)) {
                                        RingProgress(
                                            progress = progress,
                                            size = 90.dp,
                                            stroke = 8.dp,
                                            progressColor = dailyStatusColor
                                        )
                                        Column(
                                            horizontalAlignment = Alignment.CenterHorizontally,
                                            verticalArrangement = Arrangement.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Eco,
                                                contentDescription = null,
                                                tint = dailyStatusColor,
                                                modifier = Modifier.size(20.dp)
                                            )
                                            Spacer(modifier = Modifier.height(2.dp))
                                            Text(
                                                text = "${(progress * 100).roundToInt()}%",
                                                fontSize = 13.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LogCalTheme.colors.primaryText
                                            )
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(16.dp))

                                // Bottom Row: Status Pill/Badge spanning width
                                val remainingUnderGoal = (uiState.dailyGoal - uiState.todayCalories).coerceAtLeast(0)
                                val amountOverGoal = (uiState.todayCalories - uiState.dailyGoal).coerceAtLeast(0)
                                val pillText = if (isOverGoal) {
                                    "${NumberUtils.formatNumber(amountOverGoal)} cal over target"
                                } else {
                                    "${NumberUtils.formatNumber(remainingUnderGoal)} cal remaining"
                                }

                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(dailyStatusColor.copy(alpha = 0.12f))
                                        .padding(horizontal = 14.dp, vertical = 10.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = if (isOverGoal) Icons.Default.Warning else Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = dailyStatusColor,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = pillText,
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = dailyStatusColor
                                    )
                                    Spacer(modifier = Modifier.weight(1f))
                                    if (activeBurn > 0) {
                                        Row(
                                            modifier = Modifier
                                                .clip(RoundedCornerShape(12.dp))
                                                .background(Color(0xFFFFA500).copy(alpha = 0.15f))
                                                .padding(horizontal = 8.dp, vertical = 4.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Whatshot,
                                                contentDescription = "Active Burn",
                                                tint = Color(0xFFFFA500),
                                                modifier = Modifier.size(12.dp)
                                            )
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text(
                                                text = "${activeBurn.roundToInt()} burned",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = Color(0xFFFFA500)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DashboardSectionType.MACROS -> {
                        if (prefManager.showDashboardMacros) {
                            // 5. Today's Macros Card
                            AppCard {
                                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "Macros",
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.ExtraBold,
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
                                Spacer(modifier = Modifier.height(16.dp))
                                val proteinTarget = if (uiState.macroProteinPercent > 0) (uiState.proteinGrams * 100 / uiState.macroProteinPercent) else 0
                                val carbsTarget = if (uiState.macroCarbsPercent > 0) (uiState.carbsGrams * 100 / uiState.macroCarbsPercent) else 0
                                val fatTarget = if (uiState.macroFatPercent > 0) (uiState.fatGrams * 100 / uiState.macroFatPercent) else 0
                                val fiberTarget = uiState.fiberGoal.roundToInt()

                                Column(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalArrangement = Arrangement.spacedBy(20.dp)
                                ) {
                                    MacroLinearRow("Protein", uiState.proteinGrams, proteinTarget, uiState.macroProteinPercent, LogCalTheme.colors.protein)
                                    MacroLinearRow("Carbs", uiState.carbsGrams, carbsTarget, uiState.macroCarbsPercent, LogCalTheme.colors.carbs)
                                    MacroLinearRow("Fat", uiState.fatGrams, fatTarget, uiState.macroFatPercent, LogCalTheme.colors.fat)
                                    MacroLinearRow("Fiber", uiState.fiberGrams.roundToInt(), fiberTarget, uiState.macroFiberPercent, LogCalTheme.colors.fiber)
                                }
                            }
                        }
                    }

                    DashboardSectionType.WEEKLY_TREND -> {
                        if (prefManager.showDashboardWeeklyTrend) {
                            // 6. Multi-Macro Weekly Chart Card
                            var dropdownExpanded by remember { mutableStateOf(false) }
                            val proteinTarget = if (uiState.macroProteinPercent > 0) (uiState.proteinGrams * 100 / uiState.macroProteinPercent) else 0
                            val carbsTarget = if (uiState.macroCarbsPercent > 0) (uiState.carbsGrams * 100 / uiState.macroCarbsPercent) else 0
                            val fatTarget = if (uiState.macroFatPercent > 0) (uiState.fatGrams * 100 / uiState.macroFatPercent) else 0
                            val avgVal = uiState.averageFor(selectedTrendNutrient)
                            val goalVal = uiState.goalFor(selectedTrendNutrient, proteinTarget, carbsTarget, fatTarget)
                            val nutrientColor = when (selectedTrendNutrient) {
                                WeeklyTrendNutrient.CALORIES -> LogCalTheme.colors.primaryGreen
                                WeeklyTrendNutrient.PROTEIN -> Color(0xFFF26161)
                                WeeklyTrendNutrient.CARBS -> Color(0xFFF3B240)
                                WeeklyTrendNutrient.FATS -> Color(0xFF4DC6F5)
                                WeeklyTrendNutrient.FIBER -> Color(0xFF34C759)
                            }

                            AppCard {
                                // Row 1: Title & Dropdown Pill
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = "Weekly trend",
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.ExtraBold,
                                        color = LogCalTheme.colors.primaryText
                                    )

                                    // Dropdown Menu Selector
                                    Box {
                                        Row(
                                            modifier = Modifier
                                                .clip(CircleShape)
                                                .background(nutrientColor.copy(alpha = 0.15f))
                                                .clickable { dropdownExpanded = true }
                                                .padding(horizontal = 10.dp, vertical = 5.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = selectedTrendNutrient.title,
                                                fontSize = 13.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = nutrientColor
                                            )
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Icon(
                                                imageVector = Icons.Default.ArrowDropDown,
                                                contentDescription = "Select Nutrient",
                                                tint = nutrientColor,
                                                modifier = Modifier.size(16.dp)
                                            )
                                        }

                                        DropdownMenu(
                                            expanded = dropdownExpanded,
                                            onDismissRequest = { dropdownExpanded = false },
                                            modifier = Modifier.background(LogCalTheme.colors.cardBackground)
                                        ) {
                                            WeeklyTrendNutrient.entries.forEach { nutrient ->
                                                DropdownMenuItem(
                                                    text = {
                                                        Text(
                                                            text = nutrient.title,
                                                            fontWeight = if (nutrient == selectedTrendNutrient) FontWeight.Bold else FontWeight.Normal,
                                                            color = if (nutrient == selectedTrendNutrient) nutrientColor else LogCalTheme.colors.primaryText
                                                        )
                                                    },
                                                    onClick = {
                                                        selectedTrendNutrient = nutrient
                                                        dropdownExpanded = false
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }

                                // Row 2: 7-Day Average
                                Spacer(modifier = Modifier.height(4.dp))
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "7-Day Avg: ",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = LogCalTheme.colors.mutedText
                                    )
                                    val formattedAvg = if (selectedTrendNutrient == WeeklyTrendNutrient.CALORIES) {
                                        "${NumberUtils.formatNumber(avgVal.roundToInt())} cal / day"
                                    } else {
                                        "${avgVal.roundToInt()}g / day"
                                    }
                                    Text(
                                        text = formattedAvg,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = nutrientColor
                                    )
                                }

                                Spacer(modifier = Modifier.height(16.dp))

                                WeeklyBarChart(
                                    values = uiState.weeklyStats.map { it.valueFor(selectedTrendNutrient) },
                                    labels = uiState.weeklyStats.map { it.date.dayOfWeek.name.lowercase().replaceFirstChar { c -> c.uppercase() }.take(3) },
                                    selectedIdx = uiState.weeklyStats.indexOfFirst { it.date == selectedDate },
                                    onBarSelected = { idx ->
                                        uiState.weeklyStats.getOrNull(idx)?.let { stat ->
                                            viewModel.setSelectedDate(stat.date)
                                        }
                                    },
                                    goal = goalVal,
                                    nutrient = selectedTrendNutrient,
                                    nutrientColor = nutrientColor
                                )
                            }
                        }
                    }

                    DashboardSectionType.GOAL_STREAK -> {
                        if (prefManager.showDashboardGoalStreak) {
                            // 7. Daily Goal & Streak Cards (Matching iOS layout)
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                // Daily Goal Card
                                AppCard(modifier = Modifier.weight(1f)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(40.dp)
                                                .clip(CircleShape)
                                                .background(LogCalTheme.colors.softAccentBackground),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.TrackChanges,
                                                contentDescription = "Goal",
                                                tint = LogCalTheme.colors.primaryGreen,
                                                modifier = Modifier.size(20.dp)
                                            )
                                        }
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = "Daily Goal",
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.Medium,
                                                color = LogCalTheme.colors.mutedText
                                            )
                                            Text(
                                                text = "${NumberUtils.formatNumber(uiState.dailyGoal)} cal",
                                                fontSize = 16.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LogCalTheme.colors.primaryText
                                            )
                                            Row(
                                                modifier = Modifier
                                                    .clip(RoundedCornerShape(4.dp))
                                                    .clickable { showDailyGoalSheet = true }
                                                    .padding(top = 2.dp),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text(
                                                    text = "Edit goal",
                                                    fontSize = 12.sp,
                                                    fontWeight = FontWeight.SemiBold,
                                                    color = LogCalTheme.colors.primaryGreen
                                                )
                                                Spacer(modifier = Modifier.width(2.dp))
                                                Icon(
                                                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                                    contentDescription = "Edit",
                                                    tint = LogCalTheme.colors.primaryGreen,
                                                    modifier = Modifier.size(12.dp)
                                                )
                                            }
                                        }
                                    }
                                }

                                // Streak Card
                                AppCard(modifier = Modifier.weight(1f)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(40.dp)
                                                .clip(CircleShape)
                                                .background(Color(0xFFFFA500).copy(alpha = 0.15f)),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Bolt,
                                                contentDescription = "Streak",
                                                tint = Color(0xFFFFA500),
                                                modifier = Modifier.size(20.dp)
                                            )
                                        }
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = "Streak",
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.Medium,
                                                color = LogCalTheme.colors.mutedText
                                            )
                                            Text(
                                                text = "${uiState.streakDays} ${if (uiState.streakDays == 1) "day" else "days"}",
                                                fontSize = 16.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LogCalTheme.colors.primaryText
                                            )
                                            Text(
                                                text = "Keep it going!",
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = Color(0xFFFFA500),
                                                modifier = Modifier.padding(top = 2.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DashboardSectionType.ACTIVITY -> {
                        if (prefManager.showDashboardActivity) {
                            if (prefManager.isHealthConnectEnabled && isHealthAuthorized) {
                                TodaysActivityCard(
                                    activeBurn = activeBurn,
                                    basalBurn = basalBurn,
                                    consumedCalories = uiState.todayCalories,
                                    steps = steps,
                                    workouts = workouts
                                )
                            } else if (!dismissedHealthCard) {
                                ConnectHealthDiscoveryCard(
                                    onConnect = {
                                        permissionLauncher.launch(HealthConnectService.PERMISSIONS)
                                    },
                                    onDismiss = {
                                        prefManager.dismissedHealthConnectCard = true
                                        dismissedHealthCard = true
                                    }
                                )
                            }
                        }
                    }
                }
            }

            // Customize Dashboard Button
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(LogCalTheme.colors.cardBackground)
                        .border(1.dp, LogCalTheme.colors.cardBorder, RoundedCornerShape(20.dp))
                        .clickable { showCustomizeDashboardSheet = true }
                        .padding(horizontal = 16.dp, vertical = 9.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Tune,
                            contentDescription = "Customize",
                            tint = LogCalTheme.colors.mutedText,
                            modifier = Modifier.size(15.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Customize Dashboard",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LogCalTheme.colors.mutedText
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    if (showDailyGoalSheet) {
        ModalBottomSheet(
            onDismissRequest = { showDailyGoalSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            contentWindowInsets = { BottomSheetDefaults.windowInsets }
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

    if (showCustomizeDashboardSheet) {
        CustomizeDashboardBottomSheet(
            onDismiss = { showCustomizeDashboardSheet = false },
            onUpdated = {
                refreshCustomizationTrigger += 1
            }
        )
    }
}

@Composable
private fun AppCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier
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
private fun MacroLinearRow(
    title: String,
    current: Int,
    target: Int,
    percent: Int,
    color: Color
) {
    val progress = if (target > 0) (current.toFloat() / target.toFloat()).coerceIn(0f, 1.5f) else 0f

    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                color = LogCalTheme.colors.primaryText
            )
            Text(
                text = "$current / ${target}g (${percent}%)",
                style = MaterialTheme.typography.bodySmall,
                color = LogCalTheme.colors.mutedText
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(CircleShape)
                .background(LogCalTheme.colors.softAccentBackground)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction = (progress / 1.5f).coerceIn(0f, 1f))
                    .height(6.dp)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}

@Composable
private fun WeeklyBarChart(
    values: List<Double>,
    labels: List<String>,
    selectedIdx: Int,
    onBarSelected: (Int) -> Unit,
    goal: Double,
    nutrient: WeeklyTrendNutrient,
    nutrientColor: Color
) {
    val maxVal = maxOf(values.maxOrNull() ?: 1.0, goal, 1.0)

    Box(modifier = Modifier.fillMaxWidth().height(160.dp)) {
        // Goal Line
        if (goal > 0) {
            val chartTopPadding = 30.dp
            val availableHeight = 160.dp - chartTopPadding - 30.dp
            val goalY = chartTopPadding + availableHeight - (availableHeight * (goal.toFloat() / maxVal.toFloat()))
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawLine(
                    color = Color.Gray.copy(alpha = 0.4f),
                    start = Offset(0f, goalY.toPx()),
                    end = Offset(size.width, goalY.toPx()),
                    strokeWidth = 3f,
                    pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f)
                )
            }
        }

        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            val chartTopPadding = 30.dp
            val availableHeight = 160.dp - chartTopPadding - 30.dp

            values.forEachIndexed { idx, value ->
                val heightDp = if (value <= 0.0) 4.dp else ((value.toFloat() / maxVal.toFloat()) * availableHeight.value).coerceAtLeast(4f).dp
                val isSelected = idx == selectedIdx
                val isOverGoal = nutrient == WeeklyTrendNutrient.CALORIES && goal > 0 && value > goal
                val barColor = if (isOverGoal) LogCalTheme.colors.dangerRed else nutrientColor
                val displayColor = if (isSelected) barColor else barColor.copy(alpha = 0.5f)

                Column(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onBarSelected(idx) },
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Top label
                    Box(modifier = Modifier.height(20.dp), contentAlignment = Alignment.BottomCenter) {
                        if (value > 0.0) {
                            val labelText = if (nutrient == WeeklyTrendNutrient.CALORIES) {
                                NumberUtils.formatNumber(value.roundToInt())
                            } else {
                                "${value.roundToInt()}g"
                            }
                            Text(
                                text = labelText,
                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 10.sp),
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                color = if (isSelected) LogCalTheme.colors.primaryText else LogCalTheme.colors.mutedText,
                                maxLines = 1
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Box(modifier = Modifier.height(availableHeight).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
                        Box(
                            modifier = Modifier
                                .width(18.dp)
                                .height(heightDp)
                                .clip(CircleShape)
                                .background(displayColor)
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
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
}

@Composable
private fun RingProgress(
    progress: Float,
    size: Dp,
    stroke: Dp,
    progressColor: Color
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
                sweepAngle = 360f * progress,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
        }
    }
}
