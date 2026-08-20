package com.serene.logcal.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.service.HealthWorkout
import com.serene.logcal.ui.theme.LogCalTheme
import kotlin.math.absoluteValue
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodaysActivityCard(
    activeBurn: Double,
    basalBurn: Double,
    consumedCalories: Int,
    steps: Long,
    workouts: List<HealthWorkout>,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors
    var showInfoSheet by remember { mutableStateOf(false) }

    val totalBurn = (basalBurn + activeBurn).roundToInt()
    val netBalance = totalBurn - consumedCalories
    val isDeficit = netBalance >= 0

    val burnProgress = if (totalBurn > 0) {
        (consumedCalories.toFloat() / totalBurn.toFloat()).coerceIn(0f, 1.5f)
    } else 0f

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(colors.cardBackground)
            .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF4DC6F5).copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.DirectionsRun,
                            contentDescription = "Activity",
                            tint = Color(0xFF4DC6F5),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(
                        text = "Activity & Energy",
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )
                }

                IconButton(
                    onClick = { showInfoSheet = true },
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = "Info",
                        tint = colors.mutedText,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // 3-Tile Stat Grid (compact, left-aligned)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Tile 1: Active Calories
                StatTile(
                    title = "Active Calories",
                    value = "${activeBurn.roundToInt()}",
                    unit = "cal",
                    color = Color(0xFFF26161),
                    modifier = Modifier.weight(1f)
                )

                // Tile 2: Total Calories (by midnight)
                StatTile(
                    title = "Total (midnight)",
                    value = "$totalBurn",
                    unit = "cal",
                    color = Color(0xFFFFA500),
                    modifier = Modifier.weight(1f)
                )

                // Tile 3: Steps
                StatTile(
                    title = "Steps",
                    value = "$steps",
                    unit = "steps",
                    color = Color(0xFF4DC6F5),
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Estimated Net Deficit / Surplus Bar
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(colors.background)
                    .padding(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (isDeficit) "Est. Net Deficit" else "Est. Net Surplus",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = colors.primaryText
                    )
                    Text(
                        text = "${netBalance.absoluteValue} cal ${if (isDeficit) "Deficit" else "Surplus"}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isDeficit) Color(0xFF4E9F3D) else Color(0xFFF26161)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                LinearProgressIndicator(
                    progress = { (burnProgress / 1.0f).coerceIn(0f, 1f) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = if (isDeficit) Color(0xFF4E9F3D) else Color(0xFFF26161),
                    trackColor = colors.cardBorder
                )
            }

            // Workouts List (if any)
            if (workouts.isNotEmpty()) {
                Spacer(modifier = Modifier.height(10.dp))
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    workouts.forEach { workout ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(colors.background)
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Default.FitnessCenter,
                                    contentDescription = "Workout",
                                    tint = Color(0xFF4DC6F5),
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = workout.title,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = colors.primaryText
                                )
                            }
                            Text(
                                text = "${workout.durationMinutes} min • ${workout.caloriesBurned.roundToInt()} cal",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF4DC6F5)
                            )
                        }
                    }
                }
            }
        }
    }

    if (showInfoSheet) {
        ActivityExplanationBottomSheet(onDismiss = { showInfoSheet = false })
    }
}

@Composable
private fun StatTile(
    title: String,
    value: String,
    unit: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors

    Column(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(colors.background)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.Start
    ) {
        Text(
            text = title,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = colors.mutedText,
            maxLines = 1
        )
        Spacer(modifier = Modifier.height(2.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = value,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Spacer(modifier = Modifier.width(3.dp))
            Text(
                text = unit,
                fontSize = 10.sp,
                color = colors.mutedText,
                modifier = Modifier.padding(bottom = 1.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ActivityExplanationBottomSheet(onDismiss: () -> Unit) {
    val colors = LogCalTheme.colors
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = colors.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Activity & Energy Explained",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryText
                )
                TextButton(onClick = onDismiss) {
                    Text(text = "Done", fontWeight = FontWeight.Bold, color = Color(0xFF4E9F3D))
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            ExplanationItem(
                icon = Icons.Default.Whatshot,
                iconColor = Color(0xFFF26161),
                title = "Active Calories",
                description = "Calories burned through active movement, exercise sessions, and workouts recorded in Google Health Connect."
            )

            Spacer(modifier = Modifier.height(12.dp))

            ExplanationItem(
                icon = Icons.Default.Speed,
                iconColor = Color(0xFFFFA500),
                title = "Total Calories (by midnight)",
                description = "Your Total Daily Energy Expenditure (TDEE). Combines your resting BMR (what your body burns just staying alive all 24 hours) with your active burn."
            )

            Spacer(modifier = Modifier.height(12.dp))

            ExplanationItem(
                icon = Icons.AutoMirrored.Filled.DirectionsRun,
                iconColor = Color(0xFF4DC6F5),
                title = "Steps & Workouts",
                description = "Live step counts and workout sessions synced directly from connected devices (Pixel Watch, Galaxy Watch, etc.)."
            )

            Spacer(modifier = Modifier.height(12.dp))

            ExplanationItem(
                icon = Icons.Default.Lock,
                iconColor = Color(0xFF4E9F3D),
                title = "Privacy First",
                description = "Health data remains strictly on your device and is never shared with third parties or stored unencrypted."
            )

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun ExplanationItem(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    description: String
) {
    val colors = LogCalTheme.colors

    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(iconColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = iconColor,
                modifier = Modifier.size(18.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = description,
                fontSize = 12.sp,
                color = colors.mutedText,
                lineHeight = 16.sp
            )
        }
    }
}
