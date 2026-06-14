package com.serene.logcal.ui.profile

import android.Manifest
import android.app.TimePickerDialog
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.FirestoreService
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.launch
import java.util.Locale

@Composable
fun NotificationsScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val prefManager = remember { AppGraph.preferenceManager(context) }
    val reminderService = remember { AppGraph.mealReminderService(context) }
    val firestoreService = remember { FirestoreService() }
    val coroutineScope = rememberCoroutineScope()
    val colors = LogCalTheme.colors

    var mealRemindersEnabled by remember { mutableStateOf(true) }
    var breakfastHour by remember { mutableIntStateOf(8) }
    var breakfastMinute by remember { mutableIntStateOf(0) }
    var lunchHour by remember { mutableIntStateOf(13) }
    var lunchMinute by remember { mutableIntStateOf(0) }
    var dinnerHour by remember { mutableIntStateOf(20) }
    var dinnerMinute by remember { mutableIntStateOf(0) }

    var originalEnabled by remember { mutableStateOf(true) }
    var originalBreakfastHour by remember { mutableIntStateOf(8) }
    var originalBreakfastMinute by remember { mutableIntStateOf(0) }
    var originalLunchHour by remember { mutableIntStateOf(13) }
    var originalLunchMinute by remember { mutableIntStateOf(0) }
    var originalDinnerHour by remember { mutableIntStateOf(20) }
    var originalDinnerMinute by remember { mutableIntStateOf(0) }
    var isSaving by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        mealRemindersEnabled = prefManager.mealRemindersEnabled
        breakfastHour = prefManager.breakfastHour
        breakfastMinute = prefManager.breakfastMinute
        lunchHour = prefManager.lunchHour
        lunchMinute = prefManager.lunchMinute
        dinnerHour = prefManager.dinnerHour
        dinnerMinute = prefManager.dinnerMinute

        originalEnabled = mealRemindersEnabled
        originalBreakfastHour = breakfastHour
        originalBreakfastMinute = breakfastMinute
        originalLunchHour = lunchHour
        originalLunchMinute = lunchMinute
        originalDinnerHour = dinnerHour
        originalDinnerMinute = dinnerMinute
    }

    val hasChanges = mealRemindersEnabled != originalEnabled ||
            breakfastHour != originalBreakfastHour ||
            breakfastMinute != originalBreakfastMinute ||
            lunchHour != originalLunchHour ||
            lunchMinute != originalLunchMinute ||
            dinnerHour != originalDinnerHour ||
            dinnerMinute != originalDinnerMinute

    fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
    }

    fun persistReminderPreferences(enabledOverride: Boolean? = null, closeAfterSave: Boolean = true) {
        val effectiveEnabled = enabledOverride ?: mealRemindersEnabled
        mealRemindersEnabled = effectiveEnabled
        isSaving = true

        coroutineScope.launch {
            prefManager.mealRemindersEnabled = effectiveEnabled
            prefManager.breakfastHour = breakfastHour
            prefManager.breakfastMinute = breakfastMinute
            prefManager.lunchHour = lunchHour
            prefManager.lunchMinute = lunchMinute
            prefManager.dinnerHour = dinnerHour
            prefManager.dinnerMinute = dinnerMinute

            try {
                firestoreService.saveNotificationPreferences(
                    mealRemindersEnabled = effectiveEnabled,
                    breakfastTime = FirestoreService.ReminderTime(breakfastHour, breakfastMinute),
                    lunchTime = FirestoreService.ReminderTime(lunchHour, lunchMinute),
                    dinnerTime = FirestoreService.ReminderTime(dinnerHour, dinnerMinute)
                )
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: [NotificationsScreen] Failed to sync notification preferences", e)
                Toast.makeText(context, "Saved on this device. Cloud sync failed.", Toast.LENGTH_SHORT).show()
            }

            if (effectiveEnabled) {
                reminderService.scheduleAll()
            } else {
                reminderService.cancelAll()
            }

            originalEnabled = effectiveEnabled
            originalBreakfastHour = breakfastHour
            originalBreakfastMinute = breakfastMinute
            originalLunchHour = lunchHour
            originalLunchMinute = lunchMinute
            originalDinnerHour = dinnerHour
            originalDinnerMinute = dinnerMinute

            isSaving = false
            Toast.makeText(context, "Reminder preferences saved!", Toast.LENGTH_SHORT).show()
            if (closeAfterSave) {
                onBack()
            }
        }
    }

    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        prefManager.hasRequestedNotificationPermission = true
        if (granted) {
            persistReminderPreferences()
        } else {
            Toast.makeText(context, "Notification permission is required for meal reminders.", Toast.LENGTH_SHORT).show()
            persistReminderPreferences(enabledOverride = false, closeAfterSave = false)
        }
    }

    fun saveReminders() {
        if (mealRemindersEnabled && !hasNotificationPermission()) {
            prefManager.hasRequestedNotificationPermission = true
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            return
        }
        persistReminderPreferences()
    }

    fun formatTime(hour: Int, minute: Int): String {
        val amPm = if (hour < 12) "AM" else "PM"
        val displayHour = when {
            hour == 0 -> 12
            hour > 12 -> hour - 12
            else -> hour
        }
        return String.format(Locale.US, "%d:%02d %s", displayHour, minute, amPm)
    }

    fun showPicker(currentHour: Int, currentMinute: Int, onTimePicked: (Int, Int) -> Unit) {
        TimePickerDialog(
            context,
            { _, hourOfDay, minute ->
                onTimePicked(hourOfDay, minute)
            },
            currentHour,
            currentMinute,
            false
        ).show()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = colors.primaryText)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "Meal Reminders",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Reminders toggle row card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.cardBackground, RoundedCornerShape(12.dp))
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            Icons.Default.Notifications,
                            contentDescription = null,
                            tint = colors.primaryGreen,
                            modifier = Modifier.size(24.dp)
                        )
                        Column {
                            Text("Meal Reminders", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
                            Text(
                                "Get reminded to log your meals at breakfast, lunch, and dinner time",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.mutedText
                            )
                        }
                    }
                    Switch(
                        checked = mealRemindersEnabled,
                        onCheckedChange = { mealRemindersEnabled = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = colors.primaryGreen,
                            checkedTrackColor = colors.primaryGreen.copy(alpha = 0.5f)
                        )
                    )
                }
            }

            AnimatedVisibility(
                visible = mealRemindersEnabled,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("REMINDER TIMES", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = colors.mutedText)

                    // Breakfast Time Picker Row
                    ReminderTimePickerRow(
                        label = "Breakfast",
                        timeStr = formatTime(breakfastHour, breakfastMinute),
                        icon = Icons.Default.WbTwilight,
                        onClick = {
                            showPicker(breakfastHour, breakfastMinute) { h, m ->
                                breakfastHour = h
                                breakfastMinute = m
                            }
                        }
                    )

                    // Lunch Time Picker Row
                    ReminderTimePickerRow(
                        label = "Lunch",
                        timeStr = formatTime(lunchHour, lunchMinute),
                        icon = Icons.Default.WbSunny,
                        onClick = {
                            showPicker(lunchHour, lunchMinute) { h, m ->
                                lunchHour = h
                                lunchMinute = m
                            }
                        }
                    )

                    // Dinner Time Picker Row
                    ReminderTimePickerRow(
                        label = "Dinner",
                        timeStr = formatTime(dinnerHour, dinnerMinute),
                        icon = Icons.Default.Bedtime,
                        onClick = {
                            showPicker(dinnerHour, dinnerMinute) { h, m ->
                                dinnerHour = h
                                dinnerMinute = m
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            if (hasChanges) {
                Button(
                    onClick = { saveReminders() },
                    enabled = !isSaving,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                ) {
                    Text(
                        if (isSaving) "Saving..." else "Save Changes",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun ReminderTimePickerRow(
    label: String,
    timeStr: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit
) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.cardBackground, RoundedCornerShape(12.dp))
            .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(icon, contentDescription = null, tint = colors.primaryGreen)
            Text(label, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
        }

        Box(
            modifier = Modifier
                .background(colors.insetBackground, RoundedCornerShape(6.dp))
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text(timeStr, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
        }
    }
}
