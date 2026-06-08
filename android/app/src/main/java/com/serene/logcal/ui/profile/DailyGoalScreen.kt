package com.serene.logcal.ui.profile

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.DietStyle
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DailyGoalScreen(
    onBack: () -> Unit,
    onNavigateToQuestionnaire: () -> Unit,
    dietStyleOverride: DietStyle? = null
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val prefManager = remember { AppGraph.preferenceManager(context) }
    val syncService = remember { AppGraph.cloudSyncService(context) }
    val colors = LogCalTheme.colors

    var currentGoal by remember { mutableStateOf(2000.0) }
    var currentDietStyle by remember { mutableStateOf(DietStyle.BALANCED) }
    var currentProteinPercent by remember { mutableStateOf(30.0) }
    var currentCarbsPercent by remember { mutableStateOf(40.0) }
    var currentFatPercent by remember { mutableStateOf(30.0) }

    var isSaving by remember { mutableStateOf(false) }

    // Load initial preferences
    LaunchedEffect(Unit) {
        currentGoal = prefManager.dailyGoal
        currentDietStyle = dietStyleOverride ?: DietStyle.fromRawValue(prefManager.dietStyle)
        currentProteinPercent = prefManager.customProteinPercent
        currentCarbsPercent = prefManager.customCarbsPercent
        currentFatPercent = prefManager.customFatPercent
    }

    // React to diet style helper override if retargeted
    LaunchedEffect(dietStyleOverride) {
        if (dietStyleOverride != null) {
            currentDietStyle = dietStyleOverride
            val percent = dietStyleOverride.macroPercentages
            currentProteinPercent = percent.first * 100.0
            currentCarbsPercent = percent.second * 100.0
            currentFatPercent = percent.third * 100.0
        }
    }

    val currentPercentages = remember(currentDietStyle, currentProteinPercent, currentCarbsPercent, currentFatPercent) {
        if (currentDietStyle != DietStyle.CUSTOM) {
            val percentages = currentDietStyle.macroPercentages
            Triple(percentages.first, percentages.second, percentages.third)
        } else {
            Triple(currentProteinPercent / 100.0, currentCarbsPercent / 100.0, currentFatPercent / 100.0)
        }
    }

    val calculatedGrams = remember(currentGoal, currentPercentages) {
        DietStyle.calculateGrams(
            calories = currentGoal,
            proteinPercent = currentPercentages.first,
            carbsPercent = currentPercentages.second,
            fatPercent = currentPercentages.third
        )
    }

    val totalPercentage = currentProteinPercent + currentCarbsPercent + currentFatPercent
    val isCustomValid = currentDietStyle != DietStyle.CUSTOM || totalPercentage == 100.0
    val canSave = !isSaving && isCustomValid

    fun saveGoal() {
        isSaving = true
        coroutineScope.launch {
            try {
                // Save locally
                prefManager.dailyGoal = currentGoal
                prefManager.dietStyle = currentDietStyle.rawValue
                prefManager.proteinGoal = calculatedGrams.first
                prefManager.carbsGoal = calculatedGrams.second
                prefManager.fatGoal = calculatedGrams.third

                if (currentDietStyle == DietStyle.CUSTOM) {
                    prefManager.customProteinPercent = currentProteinPercent
                    prefManager.customCarbsPercent = currentCarbsPercent
                    prefManager.customFatPercent = currentFatPercent
                }

                // Sync to Firestore
                syncService.syncUserPreferencesToCloud(
                    dailyGoal = currentGoal,
                    proteinGoal = calculatedGrams.first,
                    carbsGoal = calculatedGrams.second,
                    fatGoal = calculatedGrams.third,
                    dietStyle = currentDietStyle.rawValue
                )

                Toast.makeText(context, "Goal targets saved successfully!", Toast.LENGTH_SHORT).show()
                onBack()
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Failed to save goal preferences", e)
                Toast.makeText(context, "Failed to save: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            } finally {
                isSaving = false
            }
        }
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
                "Daily Targets",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Text(
                "Set your daily calorie goal and diet style to track your macro targets effectively.",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.mutedText,
                modifier = Modifier.padding(horizontal = 4.dp)
            )

            // 1. Calorie Goal Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.cardBackground, RoundedCornerShape(16.dp))
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Flag, contentDescription = null, tint = colors.primaryGreen)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Daily Calorie Goal", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Target", style = MaterialTheme.typography.bodyMedium, color = colors.mutedText)
                    Text("${currentGoal.roundToInt()} cal", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    IconButton(
                        onClick = { if (currentGoal > 100) currentGoal -= 50 }
                    ) {
                        Icon(Icons.Default.RemoveCircle, contentDescription = "Decrement", tint = colors.primaryGreen, modifier = Modifier.size(28.dp))
                    }

                    Slider(
                        value = currentGoal.toFloat(),
                        onValueChange = { currentGoal = it.roundToInt().toDouble() },
                        valueRange = 100f..5000f,
                        steps = ((5000 - 100) / 50) - 1,
                        modifier = Modifier.weight(1f),
                        colors = SliderDefaults.colors(
                            activeTrackColor = colors.primaryGreen,
                            inactiveTrackColor = colors.insetBackground,
                            thumbColor = colors.primaryGreen
                        )
                    )

                    IconButton(
                        onClick = { if (currentGoal < 5000) currentGoal += 50 }
                    ) {
                        Icon(Icons.Default.AddCircle, contentDescription = "Increment", tint = colors.primaryGreen, modifier = Modifier.size(28.dp))
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("100", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                    Text("5,000", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                }
            }

            // 2. Diet Style Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.cardBackground, RoundedCornerShape(16.dp))
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.PieChart, contentDescription = null, tint = colors.primaryGreen)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Diet Style & Macro Split", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                }

                // Grid of Diet Styles
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    maxItemsInEachRow = 2
                ) {
                    DietStyle.entries.forEach { style ->
                        val isSelected = currentDietStyle == style
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (isSelected) colors.primaryGreen else colors.insetBackground)
                                .border(1.dp, if (isSelected) colors.primaryGreen else colors.cardBorder, RoundedCornerShape(10.dp))
                                .clickable {
                                    currentDietStyle = style
                                    if (style != DietStyle.CUSTOM) {
                                        val percent = style.macroPercentages
                                        currentProteinPercent = percent.first * 100.0
                                        currentCarbsPercent = percent.second * 100.0
                                        currentFatPercent = percent.third * 100.0
                                    }
                                }
                                .padding(horizontal = 14.dp, vertical = 12.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    style.rawValue,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isSelected) Color.White else colors.primaryText
                                )
                                if (isSelected) {
                                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                                }
                            }
                        }
                    }
                }

                // Help Me Choose Button
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(colors.softAccentBackground)
                        .clickable { onNavigateToQuestionnaire() }
                        .padding(vertical = 10.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Star, contentDescription = null, tint = colors.primaryGreen, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        "Help Me Choose",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryGreen
                    )
                }

                // Custom Percentages Steppers
                if (currentDietStyle == DietStyle.CUSTOM) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.padding(top = 8.dp)
                    ) {
                        HorizontalDivider(color = colors.cardBorder)
                        Text(
                            "Adjust Percentages (Must sum to 100%)",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold,
                            color = colors.mutedText
                        )

                        // Protein Stepper
                        CustomMacroStepperRow(
                            label = "Protein:",
                            value = currentProteinPercent,
                            color = colors.protein,
                            onValueChange = { currentProteinPercent = it }
                        )

                        // Carbs Stepper
                        CustomMacroStepperRow(
                            label = "Carbohydrates:",
                            value = currentCarbsPercent,
                            color = colors.carbs,
                            onValueChange = { currentCarbsPercent = it }
                        )

                        // Fat Stepper
                        CustomMacroStepperRow(
                            label = "Fats:",
                            value = currentFatPercent,
                            color = colors.fat,
                            onValueChange = { currentFatPercent = it }
                        )

                        HorizontalDivider(color = colors.cardBorder)

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Total Percentage", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                            Text(
                                "${totalPercentage.roundToInt()}%",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = if (totalPercentage == 100.0) colors.primaryGreen else colors.dangerRed
                            )
                        }
                    }
                }
            }

            // 3. Calculated Targets Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.cardBackground, RoundedCornerShape(16.dp))
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.List, contentDescription = null, tint = colors.primaryGreen)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Calculated Daily Targets", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                }

                // Protein Row
                CalculatedTargetRow(
                    name = "Protein",
                    grams = calculatedGrams.first,
                    percentage = currentPercentages.first,
                    color = colors.protein,
                    kcal = calculatedGrams.first * 4.0
                )

                // Carbs Row
                CalculatedTargetRow(
                    name = "Carbohydrates",
                    grams = calculatedGrams.second,
                    percentage = currentPercentages.second,
                    color = colors.carbs,
                    kcal = calculatedGrams.second * 4.0
                )

                // Fat Row
                CalculatedTargetRow(
                    name = "Fats",
                    grams = calculatedGrams.third,
                    percentage = currentPercentages.third,
                    color = colors.fat,
                    kcal = calculatedGrams.third * 9.0
                )
            }

            // Save Button
            Button(
                onClick = { saveGoal() },
                enabled = canSave,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = colors.primaryGreen,
                    contentColor = Color.White,
                    disabledContainerColor = colors.mutedText.copy(alpha = 0.2f),
                    disabledContentColor = colors.mutedText
                )
            ) {
                if (isSaving) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp))
                } else {
                    Text("Save Goal", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}

@Composable
private fun CustomMacroStepperRow(
    label: String,
    value: Double,
    color: Color,
    onValueChange: (Double) -> Unit
) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(label, style = MaterialTheme.typography.bodyMedium, color = colors.primaryText)
            Text("${value.roundToInt()}%", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = color)
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            IconButton(
                onClick = { if (value >= 2.5) onValueChange(value - 2.5) }
            ) {
                Icon(Icons.Default.Remove, contentDescription = "Minus", tint = colors.primaryText)
            }

            IconButton(
                onClick = { if (value <= 97.5) onValueChange(value + 2.5) }
            ) {
                Icon(Icons.Default.Add, contentDescription = "Plus", tint = colors.primaryText)
            }
        }
    }
}

@Composable
private fun CalculatedTargetRow(
    name: String,
    grams: Double,
    percentage: Double,
    color: Color,
    kcal: Double
) {
    val colors = LogCalTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(color)
                )
                Text(name, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
            }

            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("${grams.roundToInt()}g", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                Text("(${(percentage * 100).roundToInt()}% • ${kcal.roundToInt()} kcal)", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
            }
        }

        // Progress Capsule
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(CircleShape)
                .background(colors.insetBackground)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(percentage.toFloat())
                    .height(6.dp)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}
