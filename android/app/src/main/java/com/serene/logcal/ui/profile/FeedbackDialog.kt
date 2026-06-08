package com.serene.logcal.ui.profile

import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
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
import androidx.compose.ui.window.Dialog
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

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = colors.background,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "Feedback",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Close",
                            tint = colors.primaryText
                        )
                    }
                }

                Text(
                    "We would love to hear your thoughts, feature requests, or bugs you've encountered.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.mutedText
                )

                // Message Text Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        "YOUR MESSAGE",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = colors.mutedText
                    )
                    Box(modifier = Modifier.fillMaxWidth()) {
                        OutlinedTextField(
                            value = feedbackText,
                            onValueChange = {
                                if (it.length <= textLimit) {
                                    feedbackText = it
                                }
                            },
                            placeholder = { Text("Write your feedback here...", color = colors.quietText) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(140.dp),
                            maxLines = 10,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = colors.primaryGreen,
                                unfocusedBorderColor = colors.cardBorder,
                                focusedContainerColor = colors.cardBackground,
                                unfocusedContainerColor = colors.cardBackground
                            ),
                            textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText)
                        )
                    }
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        Text(
                            "${feedbackText.length}/$textLimit",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.quietText
                        )
                    }
                }

                // Email Text Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        "CONTACT EMAIL (OPTIONAL)",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = colors.mutedText
                    )
                    OutlinedTextField(
                        value = contactEmail,
                        onValueChange = { contactEmail = it },
                        placeholder = { Text("Enter your email", color = colors.quietText) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = colors.primaryGreen,
                            unfocusedBorderColor = colors.cardBorder,
                            focusedContainerColor = colors.cardBackground,
                            unfocusedContainerColor = colors.cardBackground
                        ),
                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText)
                    )
                }

                if (errorMessage != null) {
                    Text(
                        text = errorMessage!!,
                        color = colors.dangerRed,
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold
                    )
                }

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
                    shape = RoundedCornerShape(22.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colors.primaryGreen,
                        contentColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(44.dp)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Submit Feedback", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
