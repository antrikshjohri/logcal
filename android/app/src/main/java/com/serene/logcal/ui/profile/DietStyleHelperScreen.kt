package com.serene.logcal.ui.profile

import androidx.compose.animation.AnimatedContent
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.HeartBroken
import androidx.compose.material.icons.filled.LocalActivity
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MonitorWeight
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.TextButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.model.DietStyle
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.ui.theme.LogCalTheme
import androidx.compose.runtime.LaunchedEffect
import kotlin.math.roundToInt

enum class GoalOption(val rawValue: String, val description: String, val icon: ImageVector) {
    MUSCLE("Build Muscle & Strength", "Support muscle recovery and growth with higher protein.", Icons.Default.FitnessCenter),
    FAT_LOSS("Fat Loss & Tone", "Increase protein and manage carbs to burn fat and maintain fullness.", Icons.Default.LocalFireDepartment),
    HEALTH("General Health & Wellness", "Maintain steady daily energy levels with a balanced mix.", Icons.Default.Spa)
}

enum class ActivityOption(val rawValue: String, val description: String, val icon: ImageVector) {
    SEDENTARY("Sedentary", "Mainly sitting during the day, light exercise.", Icons.Default.Work),
    ACTIVE("Moderately Active", "Standing/walking during work, or exercising 3-4x/week.", Icons.Default.DirectionsWalk),
    VERY_ACTIVE("Highly Active", "Intense exercise daily or highly physical occupation.", Icons.Default.DirectionsRun)
}

enum class CarbOption(val rawValue: String, val description: String, val icon: ImageVector) {
    NORMAL("Enjoy Carbs", "Eat grains, oats, fruit, and feel energized by them.", Icons.Default.Spa),
    LOW_CARB("Low Carb", "Prefer higher fat, protein, and lighter carb intake.", Icons.Default.Scale),
    KETO("Ketogenic", "Achieve ketosis with minimal carbs (under 50g) and high fat.", Icons.Default.PieChart)
}

@Composable
fun DietStyleHelperScreen(
    calorieGoal: Double,
    onApply: (DietStyle) -> Unit,
    onDismiss: () -> Unit
) {
    val colors = LogCalTheme.colors

    var currentStep by remember { mutableStateOf(0) }
    var selectedGoal by remember { mutableStateOf(GoalOption.HEALTH) }
    var selectedActivity by remember { mutableStateOf(ActivityOption.ACTIVE) }
    var selectedCarbPref by remember { mutableStateOf(CarbOption.NORMAL) }

    val totalSteps = 3

    LaunchedEffect(Unit) {
        AnalyticsService.trackDietStyleHelperOpened()
    }

    val recommendedStyle = remember(selectedCarbPref, selectedGoal, selectedActivity) {
        when {
            selectedCarbPref == CarbOption.KETO -> DietStyle.KETO
            selectedCarbPref == CarbOption.LOW_CARB -> DietStyle.LOW_CARB
            selectedGoal == GoalOption.HEALTH -> DietStyle.BALANCED
            (selectedGoal == GoalOption.MUSCLE || selectedGoal == GoalOption.FAT_LOSS) && 
            (selectedActivity == ActivityOption.ACTIVE || selectedActivity == ActivityOption.VERY_ACTIVE) -> DietStyle.HIGH_PROTEIN
            else -> DietStyle.BALANCED
        }
    }

    val styleExplanation = remember(recommendedStyle) {
        when (recommendedStyle) {
            DietStyle.BALANCED -> "A Balanced split (30% Protein / 40% Carbs / 30% Fat) is perfect for general health, steady energy, and supporting active workouts while enjoying a variety of foods."
            DietStyle.HIGH_PROTEIN -> "A High Protein split (40% Protein / 30% Carbs / 30% Fat) is ideal to rebuild muscle, support strength training, and maximize satiety for fat loss."
            DietStyle.LOW_CARB -> "A Low Carb split (25% Protein / 15% Carbs / 60% Fat) helps keep blood sugar levels steady and utilizes fats as a primary source of daily energy."
            DietStyle.KETO -> "A Ketogenic split (20% Protein / 5% Carbs / 75% Fat) shifts your body's metabolism to use ketones from fats rather than glucose from carbohydrates."
            DietStyle.CUSTOM -> ""
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .padding(bottom = 100.dp)
    ) {
        // Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = {
                AnalyticsService.trackDietStyleHelperCancelTapped()
                onDismiss()
            }) {
                Icon(Icons.Default.Close, contentDescription = "Close", tint = colors.primaryText)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (currentStep < totalSteps) "Step ${currentStep + 1} of $totalSteps" else "Recommendation",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        // Progress Bar
        if (currentStep < totalSteps) {
            LinearProgressIndicator(
                progress = { (currentStep + 1).toFloat() / totalSteps.toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp),
                color = colors.primaryGreen,
                trackColor = colors.insetBackground
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Content Area
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
        ) {
            AnimatedContent(
                targetState = currentStep,
                label = "QuestionnaireStepAnimation"
            ) { step ->
                when (step) {
                    0 -> GoalStepView(
                        selected = selectedGoal,
                        onSelect = {
                            AnalyticsService.trackDietStyleHelperOptionSelected(it.rawValue)
                            selectedGoal = it
                        }
                    )
                    1 -> ActivityStepView(
                        selected = selectedActivity,
                        onSelect = {
                            AnalyticsService.trackDietStyleHelperOptionSelected(it.rawValue)
                            selectedActivity = it
                        }
                    )
                    2 -> CarbStepView(
                        selected = selectedCarbPref,
                        onSelect = {
                            AnalyticsService.trackDietStyleHelperOptionSelected(it.rawValue)
                            selectedCarbPref = it
                        }
                    )
                    else -> RecommendationResultView(
                        recommendedStyle = recommendedStyle,
                        explanation = styleExplanation,
                        calorieGoal = calorieGoal,
                        onApply = {
                            AnalyticsService.trackDietStyleHelperCompleted(recommendedStyle.rawValue)
                            onApply(recommendedStyle)
                        },
                        onRetake = {
                            AnalyticsService.trackDietStyleHelperRetakeTapped()
                            currentStep = 0
                        }
                    )
                }
            }
        }

        // Navigation Footer
        if (currentStep < totalSteps) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.cardBackground)
                    .border(1.dp, colors.cardBorder)
                    .padding(horizontal = 24.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (currentStep > 0) {
                    Text(
                        "Back",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.mutedText,
                        modifier = Modifier
                            .clickable {
                                AnalyticsService.trackDietStyleHelperBackTapped(currentStep - 1)
                                currentStep -= 1
                            }
                            .padding(8.dp)
                    )
                } else {
                    Spacer(modifier = Modifier.width(1.dp))
                }

                Text(
                    "Next",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryGreen,
                    modifier = Modifier
                        .clickable {
                            AnalyticsService.trackDietStyleHelperNextTapped(currentStep + 1)
                            currentStep += 1
                        }
                        .padding(8.dp)
                )
            }
        }
    }
}

@Composable
private fun GoalStepView(
    selected: GoalOption,
    onSelect: (GoalOption) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        QuestionHeader(
            title = "What is your primary goal?",
            subtitle = "Your fitness objectives determine how much protein and energy you need daily."
        )

        GoalOption.entries.forEach { option ->
            SelectionCard(
                title = option.rawValue,
                description = option.description,
                icon = option.icon,
                isSelected = selected == option,
                onSelect = { onSelect(option) }
            )
        }
    }
}

@Composable
private fun ActivityStepView(
    selected: ActivityOption,
    onSelect: (ActivityOption) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        QuestionHeader(
            title = "What is your activity level?",
            subtitle = "More active lifestyles burn more carbs and benefit from higher protein recovery."
        )

        ActivityOption.entries.forEach { option ->
            SelectionCard(
                title = option.rawValue,
                description = option.description,
                icon = option.icon,
                isSelected = selected == option,
                onSelect = { onSelect(option) }
            )
        }
    }
}

@Composable
private fun CarbStepView(
    selected: CarbOption,
    onSelect: (CarbOption) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        QuestionHeader(
            title = "What are your food preferences?",
            subtitle = "Choose whether you digest carbs well or prefer high fat/low carb style meals."
        )

        CarbOption.entries.forEach { option ->
            SelectionCard(
                title = option.rawValue,
                description = option.description,
                icon = option.icon,
                isSelected = selected == option,
                onSelect = { onSelect(option) }
            )
        }
    }
}

@Composable
private fun RecommendationResultView(
    recommendedStyle: DietStyle,
    explanation: String,
    calorieGoal: Double,
    onApply: () -> Unit,
    onRetake: () -> Unit
) {
    val colors = LogCalTheme.colors
    val percentages = recommendedStyle.macroPercentages
    val grams = DietStyle.calculateGrams(
        calories = calorieGoal,
        proteinPercent = percentages.first,
        carbsPercent = percentages.second,
        fatPercent = percentages.third
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // Sparks header
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                Icons.Default.AutoAwesome,
                contentDescription = null,
                tint = colors.primaryGreen,
                modifier = Modifier.size(44.dp)
            )
            Text(
                "Recommended Diet Style",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                color = colors.mutedText
            )
            Text(
                recommendedStyle.rawValue,
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Black,
                color = colors.primaryText
            )
        }

        // Explanation Card
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(colors.cardBackground, RoundedCornerShape(12.dp))
                .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                .padding(20.dp)
        ) {
            Text(
                text = explanation,
                style = MaterialTheme.typography.bodyMedium,
                color = colors.primaryText,
                lineHeight = 22.sp
            )
        }

        // Targets Preview Card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(colors.cardBackground, RoundedCornerShape(12.dp))
                .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                "Your Daily Targets (${calorieGoal.roundToInt()} kcal)",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )

            // Protein
            ResultTargetRow(
                name = "Protein",
                grams = grams.first,
                percentage = percentages.first,
                color = colors.protein,
                kcal = grams.first * 4.0
            )

            // Carbs
            ResultTargetRow(
                name = "Carbs",
                grams = grams.second,
                percentage = percentages.second,
                color = colors.carbs,
                kcal = grams.second * 4.0
            )

            // Fat
            ResultTargetRow(
                name = "Fat",
                grams = grams.third,
                percentage = percentages.third,
                color = colors.fat,
                kcal = grams.third * 9.0
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Save & Retake Buttons
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Button(
                onClick = onApply,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
            ) {
                Text("Apply & Save", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium, color = Color.White)
            }

            TextButton(
                onClick = onRetake,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    "Retake Questionnaire",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryGreen
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
private fun QuestionHeader(title: String, subtitle: String) {
    val colors = LogCalTheme.colors
    Column(
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = Modifier.padding(vertical = 12.dp)
    ) {
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = colors.primaryText)
        Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.mutedText)
    }
}

@Composable
private fun SelectionCard(
    title: String,
    description: String,
    icon: ImageVector,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (isSelected) colors.primaryGreen.copy(alpha = 0.12f) else colors.cardBackground)
            .border(
                1.dp,
                if (isSelected) colors.primaryGreen else colors.cardBorder,
                RoundedCornerShape(12.dp)
            )
            .clickable { onSelect() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon Circle
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(if (isSelected) colors.primaryGreen else colors.insetBackground),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (isSelected) Color.White else colors.primaryText,
                modifier = Modifier.size(22.dp)
            )
        }

        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
            Text(description, style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
        }

        if (isSelected) {
            Icon(
                Icons.Default.CheckCircle,
                contentDescription = "Selected",
                tint = colors.primaryGreen,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun ResultTargetRow(
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
                val pctVal = percentage * 100.0
                val pctDisplay = if (pctVal % 1.0 == 0.0) "${pctVal.toInt()}%" else "$pctVal%"
                Text("${grams.roundToInt()}g", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.primaryText)
                Text("($pctDisplay • ${kcal.roundToInt()} kcal)", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
            }
        }

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
