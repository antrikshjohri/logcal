package com.serene.logcal.ui.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.ui.theme.LogCalTheme
import java.time.LocalDate
import java.time.Month
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

/**
 * A shared calendar bottom sheet component used across the app.
 * Displays a monthly calendar grid with:
 * - Tappable month/year header for month picker navigation
 * - Left/right arrows for month navigation
 * - Today's date highlighted with a border
 * - Auto-dismiss on date selection
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarBottomSheet(
    initialDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit
) {
    val colors = LogCalTheme.colors
    var currentMonth by remember { mutableStateOf(initialDate.withDayOfMonth(1)) }
    var showMonthPicker by remember { mutableStateOf(false) }
    val today = LocalDate.now()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = colors.cardBackground,
        dragHandle = { BottomSheetDefaults.DragHandle(color = colors.cardBorder) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title
            Text(
                text = "Select Date",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(20.dp)),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = colors.background)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Month/Year header row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Tappable Month/Year label
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .clickable { showMonthPicker = !showMonthPicker }
                                .padding(vertical = 4.dp, horizontal = 4.dp)
                        ) {
                            Text(
                                text = currentMonth.format(
                                    DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH)
                                ),
                                fontWeight = FontWeight.Bold,
                                color = colors.primaryText,
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = if (showMonthPicker) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                                contentDescription = if (showMonthPicker) "Hide month picker" else "Show month picker",
                                tint = colors.primaryGreen,
                                modifier = Modifier.size(20.dp)
                            )
                        }

                        // Left/Right arrows for navigation
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Icon(
                                imageVector = Icons.Default.ChevronLeft,
                                contentDescription = if (showMonthPicker) "Previous year" else "Previous month",
                                tint = colors.primaryGreen,
                                modifier = Modifier
                                    .size(24.dp)
                                    .clip(CircleShape)
                                    .clickable {
                                        currentMonth = if (showMonthPicker) {
                                            currentMonth.minusYears(1)
                                        } else {
                                            currentMonth.minusMonths(1)
                                        }
                                    }
                            )
                            Icon(
                                imageVector = Icons.Default.ChevronRight,
                                contentDescription = if (showMonthPicker) "Next year" else "Next month",
                                tint = colors.primaryGreen,
                                modifier = Modifier
                                    .size(24.dp)
                                    .clip(CircleShape)
                                    .clickable {
                                        currentMonth = if (showMonthPicker) {
                                            currentMonth.plusYears(1)
                                        } else {
                                            currentMonth.plusMonths(1)
                                        }
                                    }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    AnimatedContent(
                        targetState = showMonthPicker,
                        transitionSpec = { fadeIn() togetherWith fadeOut() },
                        label = "calendar_mode"
                    ) { isMonthPicker ->
                        if (isMonthPicker) {
                            // Month picker grid (3 columns × 4 rows)
                            MonthPickerGrid(
                                currentMonth = currentMonth,
                                selectedDate = initialDate,
                                colors = colors,
                                onMonthSelected = { month ->
                                    currentMonth = currentMonth.withMonth(month.value)
                                    showMonthPicker = false
                                }
                            )
                        } else {
                            // Day calendar grid
                            DayCalendarGrid(
                                currentMonth = currentMonth,
                                selectedDate = initialDate,
                                today = today,
                                colors = colors,
                                onDateSelected = { date ->
                                    onDateSelected(date)
                                    onDismiss()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthPickerGrid(
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    colors: com.serene.logcal.ui.theme.LogCalColors,
    onMonthSelected: (Month) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        val months = Month.values()
        for (row in 0 until 4) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                for (col in 0 until 3) {
                    val monthIndex = row * 3 + col
                    val month = months[monthIndex]
                    val isSelected = currentMonth.year == selectedDate.year && month == selectedDate.month
                    val isCurrentMonth = currentMonth.year == LocalDate.now().year && month == LocalDate.now().month

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(12.dp))
                            .background(
                                if (isSelected) colors.primaryGreen else Color.Transparent
                            )
                            .then(
                                if (isCurrentMonth && !isSelected) {
                                    Modifier.border(1.5.dp, colors.primaryGreen, RoundedCornerShape(12.dp))
                                } else Modifier
                            )
                            .clickable { onMonthSelected(month) }
                            .padding(vertical = 12.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = month.getDisplayName(TextStyle.SHORT, Locale.ENGLISH),
                            color = when {
                                isSelected -> Color.White
                                isCurrentMonth -> colors.primaryGreen
                                else -> colors.primaryText
                            },
                            fontWeight = if (isSelected || isCurrentMonth) FontWeight.Bold else FontWeight.Normal,
                            fontSize = 14.sp
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DayCalendarGrid(
    currentMonth: LocalDate,
    selectedDate: LocalDate,
    today: LocalDate,
    colors: com.serene.logcal.ui.theme.LogCalColors,
    onDateSelected: (LocalDate) -> Unit
) {
    Column {
        // Weekday headers
        val weekdays = listOf("SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT")
        Row(modifier = Modifier.fillMaxWidth()) {
            weekdays.forEach { day ->
                Text(
                    text = day,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    color = colors.quietText
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Day grid
        val daysInMonth = currentMonth.lengthOfMonth()
        val firstDayOfWeek = currentMonth.dayOfWeek.value
        val emptySlots = if (firstDayOfWeek == 7) 0 else firstDayOfWeek
        val totalSlots = emptySlots + daysInMonth
        val rowsCount = (totalSlots + 6) / 7

        for (r in 0 until rowsCount) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (c in 0 until 7) {
                    val slotIndex = r * 7 + c
                    if (slotIndex < emptySlots || slotIndex >= totalSlots) {
                        Spacer(modifier = Modifier.weight(1f))
                    } else {
                        val dayNumber = slotIndex - emptySlots + 1
                        val date = currentMonth.withDayOfMonth(dayNumber)
                        val isSelected = date == selectedDate
                        val isToday = date == today

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(CircleShape)
                                .background(
                                    if (isSelected) colors.primaryGreen else Color.Transparent
                                )
                                .then(
                                    if (isToday && !isSelected) {
                                        Modifier.border(1.5.dp, colors.primaryGreen, CircleShape)
                                    } else Modifier
                                )
                                .clickable {
                                    onDateSelected(date)
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = dayNumber.toString(),
                                color = when {
                                    isSelected -> Color.White
                                    isToday -> colors.primaryGreen
                                    else -> colors.primaryText
                                },
                                fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
