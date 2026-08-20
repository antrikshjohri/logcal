package com.serene.logcal.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.QueryStats
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.ui.theme.LogCalTheme

enum class DashboardSectionType(
    val id: String,
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val iconColor: Color,
) {
    CALORIES(
        id = "calories",
        title = "Calorie Card",
        subtitle = "Daily calorie ring, budget & remaining intake",
        icon = Icons.Default.Whatshot,
        iconColor = Color(0xFF4E9F3D)
    ),
    MACROS(
        id = "macros",
        title = "Macros Split",
        subtitle = "Protein, Carbs, Fats & Fiber breakdown",
        icon = Icons.Default.PieChart,
        iconColor = Color(0xFFF26161)
    ),
    WEEKLY_TREND(
        id = "weekly_trend",
        title = "Weekly Trend",
        subtitle = "7-day nutrient bar charts and daily averages",
        icon = Icons.Default.QueryStats,
        iconColor = Color(0xFFF3B240)
    ),
    GOAL_STREAK(
        id = "goal_streak",
        title = "Daily Goal & Streak",
        subtitle = "Calorie target shortcut and logging streak",
        icon = Icons.Default.Bolt,
        iconColor = Color(0xFFFFA500)
    ),
    ACTIVITY(
        id = "activity",
        title = "Activity & Energy Balance",
        subtitle = "Active burn, steps, workouts & TDEE by midnight",
        icon = Icons.Default.DirectionsRun,
        iconColor = Color(0xFF4DC6F5)
    );

    companion object {
        fun fromId(id: String): DashboardSectionType? {
            return entries.firstOrNull { it.id.equals(id, ignoreCase = true) }
        }

        val defaultOrder: List<DashboardSectionType> = listOf(
            CALORIES, MACROS, WEEKLY_TREND, GOAL_STREAK, ACTIVITY
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomizeDashboardBottomSheet(
    onDismiss: () -> Unit,
    onUpdated: () -> Unit
) {
    val context = LocalContext.current
    val prefManager = remember { AppGraph.preferenceManager(context) }
    val colors = LogCalTheme.colors
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // Parse stored order
    var sectionList by remember {
        val stored = prefManager.dashboardSectionOrder.split(",").mapNotNull { DashboardSectionType.fromId(it.trim()) }
        val allSections = DashboardSectionType.entries
        val complete = stored.toMutableList()
        allSections.forEach { if (!complete.contains(it)) complete.add(it) }
        mutableStateOf<List<DashboardSectionType>>(complete)
    }

    var showCalories by remember { mutableStateOf(prefManager.showDashboardCalories) }
    var showMacros by remember { mutableStateOf(prefManager.showDashboardMacros) }
    var showWeeklyTrend by remember { mutableStateOf(prefManager.showDashboardWeeklyTrend) }
    var showGoalStreak by remember { mutableStateOf(prefManager.showDashboardGoalStreak) }
    var showActivity by remember { mutableStateOf(prefManager.showDashboardActivity) }

    fun isEnabled(type: DashboardSectionType): Boolean = when (type) {
        DashboardSectionType.CALORIES -> showCalories
        DashboardSectionType.MACROS -> showMacros
        DashboardSectionType.WEEKLY_TREND -> showWeeklyTrend
        DashboardSectionType.GOAL_STREAK -> showGoalStreak
        DashboardSectionType.ACTIVITY -> showActivity
    }

    fun setEnabled(type: DashboardSectionType, value: Boolean) {
        when (type) {
            DashboardSectionType.CALORIES -> { showCalories = value; prefManager.showDashboardCalories = value }
            DashboardSectionType.MACROS -> { showMacros = value; prefManager.showDashboardMacros = value }
            DashboardSectionType.WEEKLY_TREND -> { showWeeklyTrend = value; prefManager.showDashboardWeeklyTrend = value }
            DashboardSectionType.GOAL_STREAK -> { showGoalStreak = value; prefManager.showDashboardGoalStreak = value }
            DashboardSectionType.ACTIVITY -> { showActivity = value; prefManager.showDashboardActivity = value }
        }
        onUpdated()
    }

    val activeCount = listOf(showCalories, showMacros, showWeeklyTrend, showGoalStreak, showActivity).count { it }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = colors.background,
        dragHandle = null
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Customize Dashboard",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryText
                )
                TextButton(onClick = onDismiss) {
                    Text(
                        text = "Done",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF4E9F3D)
                    )
                }
            }

            Text(
                text = "Use arrows to reorder. Toggle switches to hide or show sections on your dashboard.",
                fontSize = 13.sp,
                color = colors.mutedText,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            // Section List
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                itemsIndexed(sectionList, key = { _, item -> item.id }) { index, section ->
                    val isChecked = isEnabled(section)
                    val isDisableProtected = activeCount <= 1 && isChecked

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(colors.cardBackground)
                            .border(1.dp, colors.cardBorder, RoundedCornerShape(14.dp))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Reorder controls (Up / Down)
                        Column(
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(end = 6.dp)
                        ) {
                            IconButton(
                                onClick = {
                                    if (index > 0) {
                                        val mutable = sectionList.toMutableList()
                                        val item = mutable.removeAt(index)
                                        mutable.add(index - 1, item)
                                        sectionList = mutable
                                        prefManager.dashboardSectionOrder = mutable.joinToString(",") { it.id }
                                        onUpdated()
                                    }
                                },
                                enabled = index > 0,
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.KeyboardArrowUp,
                                    contentDescription = "Move Up",
                                    tint = if (index > 0) colors.mutedText else colors.mutedText.copy(alpha = 0.2f),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                            IconButton(
                                onClick = {
                                    if (index < sectionList.size - 1) {
                                        val mutable = sectionList.toMutableList()
                                        val item = mutable.removeAt(index)
                                        mutable.add(index + 1, item)
                                        sectionList = mutable
                                        prefManager.dashboardSectionOrder = mutable.joinToString(",") { it.id }
                                        onUpdated()
                                    }
                                },
                                enabled = index < sectionList.size - 1,
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.KeyboardArrowDown,
                                    contentDescription = "Move Down",
                                    tint = if (index < sectionList.size - 1) colors.mutedText else colors.mutedText.copy(alpha = 0.2f),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }

                        // Icon Box
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .background(section.iconColor.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = section.icon,
                                contentDescription = section.title,
                                tint = section.iconColor,
                                modifier = Modifier.size(18.dp)
                            )
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        // Text column
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = section.title,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = colors.primaryText
                            )
                            Text(
                                text = section.subtitle,
                                fontSize = 11.5.sp,
                                color = colors.mutedText,
                                maxLines = 1
                            )
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        // Switch
                        Switch(
                            checked = isChecked,
                            onCheckedChange = { setEnabled(section, it) },
                            enabled = !isDisableProtected,
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF4E9F3D),
                                uncheckedThumbColor = Color.White,
                                uncheckedTrackColor = colors.cardBorder
                            )
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Reset to Default Button
            TextButton(
                onClick = {
                    val defaultList = DashboardSectionType.defaultOrder
                    sectionList = defaultList
                    prefManager.dashboardSectionOrder = defaultList.joinToString(",") { it.id }
                    showCalories = true
                    showMacros = true
                    showWeeklyTrend = true
                    showGoalStreak = true
                    showActivity = true
                    prefManager.showDashboardCalories = true
                    prefManager.showDashboardMacros = true
                    prefManager.showDashboardWeeklyTrend = true
                    prefManager.showDashboardGoalStreak = true
                    prefManager.showDashboardActivity = true
                    onUpdated()
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Reset to Default Order & Visibility",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = colors.mutedText
                )
            }
        }
    }
}
