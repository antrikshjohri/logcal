package com.serene.logcal.ui.profile

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.QuestionMark
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.ui.theme.LogCalTheme
import androidx.compose.runtime.LaunchedEffect

data class FAQItem(val question: String, val answer: String)

@Composable
fun HelpFAQScreen(
    onBack: () -> Unit
) {
    val colors = LogCalTheme.colors

    LaunchedEffect(Unit) {
        AnalyticsService.trackHelpFAQOpened()
    }

    val faqs = remember {
        listOf(
            FAQItem(
                question = "How accurate is the calorie estimation?",
                answer = "LogCal uses OpenAI's GPT-4 to analyze your meal descriptions and provide calorie estimates. While highly accurate, estimates may vary based on portion sizes and preparation methods. We recommend being as specific as possible in your descriptions."
            ),
            FAQItem(
                question = "Can I edit logged meals?",
                answer = "Yes! Navigate to the History screen, find the meal you want to edit, and tap on it to view details. You can then adjust the calorie count or delete the entry."
            ),
            FAQItem(
                question = "How do I change my daily calorie goal?",
                answer = "Go to Profile > Daily Goal, then use the slider to adjust your daily calorie target. Your new goal will be saved automatically."
            ),
            FAQItem(
                question = "Does LogCal work offline?",
                answer = "LogCal requires an internet connection to analyze meals using AI. However, you can view your previously logged meals offline."
            ),
            FAQItem(
                question = "Is my data private and secure?",
                answer = "Absolutely. We use industry-standard encryption to protect your data. Your meal logs and personal information are never shared with third parties."
            ),
            FAQItem(
                question = "How does the voice input work?",
                answer = "Tap the microphone to record what you ate, then tap again to stop. Your audio is sent securely to be transcribed, then our AI estimates calories from the text."
            ),
            FAQItem(
                question = "What if the calorie estimate seems wrong?",
                answer = "You can manually adjust any calorie estimate after logging. We also recommend providing detailed descriptions (e.g., \"grilled chicken breast, 6 oz\" instead of just \"chicken\")."
            )
        )
    }

    var expandedIndices by remember { mutableStateOf(setOf<Int>()) }

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
                "Help & FAQ",
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
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Find answers to commonly asked questions about LogCal.",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.mutedText,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            faqs.forEachIndexed { index, faq ->
                val isExpanded = expandedIndices.contains(index)
                
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                        .clip(RoundedCornerShape(12.dp))
                        .clickable {
                            expandedIndices = if (isExpanded) {
                                expandedIndices - index
                            } else {
                                expandedIndices + index
                            }
                        }
                        .padding(vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Circle question mark
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .clip(CircleShape)
                                .background(colors.softAccentBackground),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.QuestionMark,
                                contentDescription = null,
                                tint = colors.primaryGreen,
                                modifier = Modifier.size(16.dp)
                            )
                        }

                        Text(
                            faq.question,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryText,
                            modifier = Modifier.weight(1f)
                        )

                        Icon(
                            imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                            contentDescription = null,
                            tint = colors.mutedText
                        )
                    }

                    AnimatedVisibility(
                        visible = isExpanded,
                        enter = fadeIn() + expandVertically(),
                        exit = fadeOut() + shrinkVertically()
                    ) {
                        Column {
                            HorizontalDivider(color = colors.cardBorder, modifier = Modifier.padding(horizontal = 16.dp))
                            Text(
                                faq.answer,
                                style = MaterialTheme.typography.bodyMedium,
                                color = colors.mutedText,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(start = 60.dp, end = 16.dp, top = 12.dp, bottom = 16.dp),
                                lineHeight = 20.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
