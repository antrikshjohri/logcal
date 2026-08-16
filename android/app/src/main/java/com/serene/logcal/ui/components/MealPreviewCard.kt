package com.serene.logcal.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.model.CompletedMealPreview
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.NumberUtils

import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Visibility

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MealPreviewCard(
    preview: CompletedMealPreview,
    isSaved: Boolean,
    onLogMeal: (() -> Unit)? = null,
    onDismiss: (() -> Unit)? = null,
    onBookmark: () -> Unit,
    onQuickEdit: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors
    val result = preview.response
    var quickEditPrompt by remember { mutableStateOf("") }

    Card(
        modifier = modifier
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
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header: Status, Meal Type, Bookmark, Dismiss
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (preview.isPreviewOnly) {
                        Icon(
                            imageVector = Icons.Default.Visibility,
                            contentDescription = null,
                            tint = colors.accentBlue,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            "Preview",
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.accentBlue
                        )
                        Box(
                            modifier = Modifier
                                .background(
                                    colors.accentBlue.copy(alpha = 0.12f),
                                    RoundedCornerShape(6.dp)
                                )
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                "Not Logged",
                                color = colors.accentBlue,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    } else {
                        Text(
                            "Logged Successfully",
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.primaryText
                        )
                        Box(
                            modifier = Modifier
                                .background(
                                    colors.softAccentBackground,
                                    RoundedCornerShape(6.dp)
                                )
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                result.mealType.replaceFirstChar { it.uppercase() },
                                color = colors.primaryGreen,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (!preview.isPreviewOnly) {
                        IconButton(onClick = onBookmark) {
                            Icon(
                                imageVector = if (isSaved) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                                contentDescription = "Bookmark favourite",
                                tint = colors.primaryGreen
                            )
                        }
                    }

                    if (onDismiss != null) {
                        IconButton(onClick = { onDismiss() }) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Dismiss summary",
                                tint = colors.mutedText
                            )
                        }
                    }
                }
            }

            // Food Title if present
            if (preview.foodText.isNotBlank()) {
                Text(
                    preview.foodText,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = colors.mutedText
                )
            }

            // Calories
            Text(
                "${NumberUtils.formatNumber(result.totalCalories.toInt())} cal",
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Black,
                color = colors.primaryText
            )

            // Macros
            if (result.protein != null && result.carbs != null && result.fat != null) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    MacroPill("Protein", "${result.protein.toInt()}g", colors.protein)
                    MacroPill("Carbs", "${result.carbs.toInt()}g", colors.carbs)
                    MacroPill("Fat", "${result.fat.toInt()}g", colors.fat)
                    if (result.fiber != null) {
                        MacroPill("Fiber", "${result.fiber.toInt()}g", colors.fiber)
                    }
                }
            }

            HorizontalDivider(color = colors.cardBorder)

            Text(
                "Items Breakdown",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = colors.mutedText
            )

            result.items.forEachIndexed { index, item ->
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            item.name,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = colors.primaryText
                        )
                        Text(
                            "${item.calories.toInt()} cal",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryGreen
                        )
                    }

                    Text(
                        item.quantity,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.mutedText
                    )

                    if (item.protein != null && item.carbs != null && item.fat != null) {
                        Text(
                            "${item.protein.toInt()}g P • ${item.carbs.toInt()}g C • ${item.fat.toInt()}g F" +
                                if (item.fiber != null) " • ${item.fiber.toInt()}g Fiber" else "",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.mutedText
                        )
                    }

                    if (!item.assumptions.isNullOrBlank()) {
                        Text(
                            "Assumptions: ${item.assumptions}",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.mutedText
                        )
                    }
                }

                if (index < result.items.size - 1) {
                    HorizontalDivider(
                        color = colors.cardBorder.copy(alpha = 0.5f),
                        modifier = Modifier.padding(vertical = 4.dp)
                    )
                }
            }

            MealSourcesRow(sources = result.sources)

            if (preview.isPreviewOnly && onLogMeal != null) {
                Button(
                    onClick = onLogMeal,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(24.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                ) {
                    Icon(
                        imageVector = Icons.Default.AddCircle,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Log this Meal", fontWeight = FontWeight.Bold)
                }
            }

            HorizontalDivider(color = colors.cardBorder)

            // Quick Edit Section
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "Quick Edit / Correction",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = colors.mutedText
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = quickEditPrompt,
                        onValueChange = { quickEditPrompt = it },
                        placeholder = { Text("e.g. Actually had 2 cups", fontSize = 13.sp) },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = colors.primaryGreen,
                            unfocusedBorderColor = colors.cardBorder
                        )
                    )

                    Button(
                        onClick = {
                            if (quickEditPrompt.isNotBlank()) {
                                onQuickEdit(quickEditPrompt)
                                quickEditPrompt = ""
                            }
                        },
                        enabled = quickEditPrompt.isNotBlank() && !preview.isRefining,
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        if (preview.isRefining) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = Color.White
                            )
                        } else {
                            Text("Update", fontWeight = FontWeight.Bold)
                        }
                    }
                }

                if (!preview.refineError.isNullOrBlank()) {
                    Text(
                        preview.refineError,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.warningAmber
                    )
                }
            }
        }
    }
}

@Composable
private fun MacroPill(label: String, value: String, color: Color) {
    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.12f), RoundedCornerShape(12.dp))
            .padding(horizontal = 8.dp, vertical = 6.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .background(color, CircleShape)
            )
            Text(
                "$value $label",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = LogCalTheme.colors.primaryText
            )
        }
    }
}
