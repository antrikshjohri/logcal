package com.serene.logcal.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.model.PendingLogStatus
import com.serene.logcal.model.PendingMealLog
import com.serene.logcal.ui.theme.LogCalTheme
import java.util.Locale

@Composable
fun PendingMealsTray(
    pendingLogs: List<PendingMealLog>,
    onRetry: (String) -> Unit,
    onDismiss: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    if (pendingLogs.isEmpty()) return

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        pendingLogs.forEach { pending ->
            PendingMealCard(
                pending = pending,
                onRetry = { onRetry(pending.id) },
                onDismiss = { onDismiss(pending.id) }
            )
        }
    }
}

@Composable
private fun PendingMealCard(
    pending: PendingMealLog,
    onRetry: () -> Unit,
    onDismiss: () -> Unit
) {
    val colors = LogCalTheme.colors
    val (emoji, displayLabel) = when (pending.mealType.rawValue.lowercase(Locale.ROOT)) {
        "breakfast" -> Pair("🌅", "Breakfast")
        "lunch" -> Pair("☀️", "Lunch")
        "dinner" -> Pair("🌙", "Dinner")
        "snack" -> Pair("🌿", "Snack")
        else -> Pair("🍽️", pending.mealType.rawValue.replaceFirstChar { it.uppercase() })
    }

    val borderColor = when (pending.status) {
        is PendingLogStatus.Failed -> colors.warningAmber.copy(alpha = 0.5f)
        is PendingLogStatus.Completed -> colors.primaryGreen.copy(alpha = 0.4f)
        is PendingLogStatus.Processing -> colors.cardBorder
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 4.dp,
                shape = RoundedCornerShape(12.dp),
                ambientColor = colors.shadowColor,
                spotColor = colors.shadowColor
            ),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        border = BorderStroke(1.dp, borderColor)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status Icon / Spinner
            when (pending.status) {
                is PendingLogStatus.Processing -> {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = colors.primaryGreen
                    )
                }
                is PendingLogStatus.Completed -> {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = "Completed",
                        tint = colors.primaryGreen,
                        modifier = Modifier.size(20.dp)
                    )
                }
                is PendingLogStatus.Failed -> {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = "Failed",
                        tint = colors.warningAmber,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Food text and status details
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = pending.displayText,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = colors.primaryText,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Row(
                    modifier = Modifier.padding(top = 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .background(colors.softAccentBackground, RoundedCornerShape(4.dp))
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "$emoji $displayLabel",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.primaryGreen,
                            fontWeight = FontWeight.Bold,
                            fontSize = 10.sp
                        )
                    }

                    when (val status = pending.status) {
                        is PendingLogStatus.Processing -> {
                            Text(
                                text = "Estimating macros...",
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.mutedText,
                                fontSize = 11.sp
                            )
                        }
                        is PendingLogStatus.Completed -> {
                            Text(
                                text = "${status.response.totalCalories.toInt()} cal",
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.primaryGreen,
                                fontWeight = FontWeight.Bold,
                                fontSize = 11.sp
                            )
                        }
                        is PendingLogStatus.Failed -> {
                            Text(
                                text = status.error,
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.warningAmber,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }

            // Actions for failed items
            if (pending.status is PendingLogStatus.Failed) {
                Spacer(modifier = Modifier.width(8.dp))

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(colors.primaryGreen)
                        .clickable { onRetry() }
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "Retry",
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold
                    )
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Dismiss",
                        tint = colors.mutedText,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}
