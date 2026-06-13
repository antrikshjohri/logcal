package com.serene.logcal.ui.profile

import android.widget.Toast
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.service.FirestoreService
import com.serene.logcal.ui.theme.LogCalTheme
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedbackDialog(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val firestoreService = remember { FirestoreService() }
    val colors = LogCalTheme.colors

    var feedbackText by remember { mutableStateOf("") }
    var contactEmail by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val textLimit = 2000

    LaunchedEffect(Unit) {
        val user = FirebaseAuth.getInstance().currentUser
        if (user != null && !user.isAnonymous && !user.email.isNullOrBlank()) {
            contactEmail = user.email!!
        }
    }

    val isSubmitDisabled = feedbackText.trim().isEmpty() || isLoading

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = colors.background,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        dragHandle = { BottomSheetDefaults.DragHandle(color = colors.cardBorder) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 36.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Cancel Pill button (Top Left)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start
            ) {
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(colors.cardBackground)
                        .border(1.dp, colors.cardBorder, CircleShape)
                        .clickable { onDismiss() }
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .shadow(1.dp, CircleShape, ambientColor = colors.shadowColor, spotColor = colors.shadowColor),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Cancel",
                        color = colors.primaryGreen,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(2.dp))

            // Page Title
            Text(
                text = "Feedback",
                fontSize = 32.sp,
                fontWeight = FontWeight.ExtraBold,
                color = colors.primaryText,
                modifier = Modifier.fillMaxWidth()
            )

            // Description text
            Text(
                text = "We would love to hear your thoughts, feature requests, or bugs you've encountered.",
                fontSize = 16.sp,
                fontWeight = FontWeight.Normal,
                color = colors.mutedText,
                lineHeight = 22.sp,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(2.dp))

            // YOUR MESSAGE Section
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "YOUR MESSAGE",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.8.sp,
                    color = colors.mutedText
                )

                // Message text area
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp)
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                ) {
                    BasicTextField(
                        value = feedbackText,
                        onValueChange = {
                            if (it.length <= textLimit) {
                                feedbackText = it
                            }
                        },
                        modifier = Modifier.fillMaxSize(),
                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText),
                        decorationBox = { innerTextField ->
                            if (feedbackText.isEmpty()) {
                                Text(
                                    text = "Write your feedback here...",
                                    color = colors.quietText,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            innerTextField()
                        }
                    )
                }

                // Character counter
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    Text(
                        text = "${feedbackText.length}/$textLimit",
                        fontSize = 12.sp,
                        color = colors.mutedText
                    )
                }
            }

            // CONTACT EMAIL Section
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "CONTACT EMAIL (OPTIONAL)",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.8.sp,
                    color = colors.mutedText
                )

                // Email text area
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 14.dp)
                ) {
                    BasicTextField(
                        value = contactEmail,
                        onValueChange = { contactEmail = it },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText),
                        decorationBox = { innerTextField ->
                            if (contactEmail.isEmpty()) {
                                Text(
                                    text = "Enter your email",
                                    color = colors.quietText,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            innerTextField()
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Submit Button
            Button(
                onClick = {
                    isLoading = true
                    errorMessage = null
                    coroutineScope.launch {
                        try {
                            firestoreService.submitFeedback(
                                text = feedbackText.trim(),
                                email = contactEmail.trim().takeIf { it.isNotBlank() }
                            )
                            Toast.makeText(context, "Feedback submitted successfully!", Toast.LENGTH_SHORT).show()
                            onDismiss()
                        } catch (e: Exception) {
                            errorMessage = e.localizedMessage ?: "Failed to submit feedback."
                            isLoading = false
                        }
                    }
                },
                enabled = !isSubmitDisabled,
                shape = CircleShape,
                colors = ButtonDefaults.buttonColors(
                    containerColor = colors.primaryGreen,
                    contentColor = Color.White,
                    disabledContainerColor = colors.cardBorder,
                    disabledContentColor = colors.quietText
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .run {
                        if (!isSubmitDisabled) {
                            shadow(
                                elevation = 4.dp,
                                shape = CircleShape,
                                ambientColor = colors.shadowColor,
                                spotColor = colors.shadowColor
                            )
                        } else this
                    }
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Submit Feedback",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                }
            }

            if (errorMessage != null) {
                Text(
                    text = errorMessage!!,
                    color = colors.dangerRed,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }
}
