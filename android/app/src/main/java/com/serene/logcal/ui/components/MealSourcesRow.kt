package com.serene.logcal.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.serene.logcal.model.MealSource
import com.serene.logcal.ui.theme.LogCalTheme

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MealSourcesRow(
    sources: List<MealSource>,
    modifier: Modifier = Modifier,
) {
    val colors = LogCalTheme.colors
    val uriHandler = LocalUriHandler.current
    val validSources = sources.filter { it.url.startsWith("http://") || it.url.startsWith("https://") }
    if (validSources.isEmpty()) return

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            "Sources",
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.SemiBold,
            color = colors.quietText,
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            validSources.take(2).forEach { source ->
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(colors.primaryGreen.copy(alpha = 0.10f))
                        .clickable { uriHandler.openUri(source.url) }
                        .padding(horizontal = 8.dp, vertical = 5.dp),
                ) {
                    Text(
                        source.displayTitle,
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = colors.primaryGreen,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }

            if (validSources.size > 2) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(colors.cardBorder.copy(alpha = 0.35f))
                        .padding(horizontal = 8.dp, vertical = 5.dp),
                ) {
                    Text(
                        "+${validSources.size - 2} more",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = colors.quietText,
                    )
                }
            }
        }
    }
}
