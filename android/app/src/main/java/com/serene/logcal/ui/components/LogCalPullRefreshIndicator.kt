package com.serene.logcal.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.serene.logcal.ui.theme.LogCalTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BoxScope.LogCalPullRefreshIndicator(
    state: PullToRefreshState,
    isRefreshing: Boolean,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors
    val fraction = state.distanceFraction.coerceIn(0f, 1f)

    if (fraction > 0.05f || isRefreshing) {
        Box(
            modifier = modifier
                .align(Alignment.TopCenter)
                .padding(top = 12.dp)
                .graphicsLayer {
                    translationY = (state.distanceFraction * 40.dp.toPx()).coerceAtMost(60.dp.toPx())
                    alpha = if (isRefreshing) 1f else fraction
                    scaleX = if (isRefreshing) 1f else (0.75f + 0.25f * fraction)
                    scaleY = if (isRefreshing) 1f else (0.75f + 0.25f * fraction)
                }
                .shadow(
                    elevation = 4.dp,
                    shape = CircleShape,
                    ambientColor = colors.shadowColor,
                    spotColor = colors.shadowColor
                )
                .clip(CircleShape)
                .background(colors.cardBackground)
                .border(0.8.dp, colors.cardBorder.copy(alpha = 0.8f), CircleShape)
                .padding(8.dp),
            contentAlignment = Alignment.Center
        ) {
            if (isRefreshing) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = colors.primaryGreen,
                    strokeWidth = 2.2.dp
                )
            } else {
                CircularProgressIndicator(
                    progress = { fraction },
                    modifier = Modifier.size(20.dp),
                    color = colors.primaryGreen,
                    strokeWidth = 2.2.dp,
                    trackColor = colors.primaryGreen.copy(alpha = 0.15f)
                )
            }
        }
    }
}
