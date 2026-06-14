package com.serene.logcal.ui.auth

import android.app.Activity
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Link
import androidx.compose.foundation.BorderStroke
import androidx.compose.ui.res.painterResource
import com.serene.logcal.R
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.AuthCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.GoogleAuthProvider
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.launch

@Composable
fun AuthDialog(
    onDismiss: () -> Unit,
    onAuthSuccess: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val auth = remember { FirebaseAuth.getInstance() }
    val syncService = remember { AppGraph.cloudSyncService(context) }
    val colors = LogCalTheme.colors

    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showConflictDialog by remember { mutableStateOf(false) }
    var pendingCredential by remember { mutableStateOf<AuthCredential?>(null) }

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        isLoading = false
        if (result.resultCode == Activity.RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            try {
                val account = task.getResult(ApiException::class.java)!!
                val credential = GoogleAuthProvider.getCredential(account.idToken, null)
                
                val user = auth.currentUser
                if (user != null && user.isAnonymous) {
                    isLoading = true
                    user.linkWithCredential(credential)
                        .addOnSuccessListener {
                            DebugLogger.d("DEBUG: Successfully linked anonymous guest to Google account")
                            coroutineScope.launch {
                                try {
                                    syncService.migrateLocalToCloud()
                                    syncService.syncFromCloud()
                                } catch (e: Exception) {
                                    DebugLogger.e("DEBUG: Migration after link failed", e)
                                }
                                isLoading = false
                                onAuthSuccess()
                                onDismiss()
                            }
                        }
                        .addOnFailureListener { e ->
                            DebugLogger.e("DEBUG: Linking failed", e)
                            isLoading = false
                            if (e is FirebaseAuthUserCollisionException) {
                                pendingCredential = credential
                                showConflictDialog = true
                            } else {
                                errorMessage = e.localizedMessage ?: "Failed to link account."
                            }
                        }
                } else {
                    // Fallback to normal sign in if not guest
                    isLoading = true
                    auth.signInWithCredential(credential)
                        .addOnSuccessListener {
                            DebugLogger.d("DEBUG: Google sign-in successful: ${it.user?.email}")
                            coroutineScope.launch {
                                syncService.syncFromCloud()
                                isLoading = false
                                onAuthSuccess()
                                onDismiss()
                            }
                        }
                        .addOnFailureListener { e ->
                            isLoading = false
                            errorMessage = e.localizedMessage ?: "Sign-in failed."
                        }
                }
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Google sign-in launcher exception", e)
                errorMessage = e.localizedMessage ?: "Google sign-in error."
            }
        }
    }

    if (showConflictDialog) {
        Dialog(onDismissRequest = { 
            showConflictDialog = false
            pendingCredential = null
        }) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = colors.background,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Account Already Exists",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText,
                        textAlign = TextAlign.Center
                    )

                    Text(
                        text = "The Google account you selected is already linked to another LogCal user. How would you like to proceed?",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center
                    )

                    Button(
                        onClick = {
                            isLoading = true
                            showConflictDialog = false
                            coroutineScope.launch {
                                try {
                                    // Switch account (Firebase will automatically switch user)
                                    pendingCredential?.let { credential ->
                                        auth.signInWithCredential(credential).awaitTask()
                                        // Merge local Room meals to cloud Firestore for the new user
                                        syncService.migrateLocalToCloud()
                                        syncService.syncFromCloud()
                                    }
                                    onAuthSuccess()
                                    onDismiss()
                                } catch (e: Exception) {
                                    errorMessage = e.localizedMessage
                                } finally {
                                    isLoading = false
                                    pendingCredential = null
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(24.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                    ) {
                        Text("Merge Guest Logs", fontWeight = FontWeight.Bold)
                    }

                    Button(
                        onClick = {
                            isLoading = true
                            showConflictDialog = false
                            coroutineScope.launch {
                                try {
                                    // Discard guest data -> Clear Room DB
                                    syncService.clearLocalMeals()
                                    // Switch user
                                    pendingCredential?.let { credential ->
                                        auth.signInWithCredential(credential).awaitTask()
                                        syncService.syncFromCloud()
                                    }
                                    onAuthSuccess()
                                    onDismiss()
                                } catch (e: Exception) {
                                    errorMessage = e.localizedMessage
                                } finally {
                                    isLoading = false
                                    pendingCredential = null
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(24.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = colors.dangerRed)
                    ) {
                        Text("Discard Guest Logs", fontWeight = FontWeight.Bold, color = Color.White)
                    }

                    Text(
                        text = "Cancel",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.mutedText,
                        modifier = Modifier
                            .clickable {
                                showConflictDialog = false
                                pendingCredential = null
                            }
                            .padding(vertical = 8.dp)
                    )
                }
            }
        }
    }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = colors.background,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = colors.primaryText)
                    }
                }

                // Header icon
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .background(colors.softAccentBackground, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Link,
                        contentDescription = "Link",
                        tint = colors.primaryGreen,
                        modifier = Modifier.size(44.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Link Your Account",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryText,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "Sign in with Google to back up your calorie logs to the cloud and sync them across devices.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.mutedText,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )

                Spacer(modifier = Modifier.height(32.dp))

                if (isLoading) {
                    CircularProgressIndicator(color = colors.primaryGreen)
                    Spacer(modifier = Modifier.height(20.dp))
                } else {
                    if (errorMessage != null) {
                        Text(
                            text = errorMessage!!,
                            color = colors.dangerRed,
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }

                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                            .clickable {
                                isLoading = true
                                errorMessage = null
                                val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                    .requestIdToken("1023141890322-i5ob5lajc097qdfs3fg22ebc6bapfboe.apps.googleusercontent.com")
                                    .requestEmail()
                                    .build()
                                val googleSignInClient = GoogleSignIn.getClient(context, gso)
                                googleSignInClient.signOut().addOnCompleteListener {
                                    val intent = googleSignInClient.signInIntent
                                    googleSignInLauncher.launch(intent)
                                }
                            },
                        shape = RoundedCornerShape(25.dp),
                        color = Color.White,
                        border = BorderStroke(1.dp, Color(0xFFE0E0E0)),
                        shadowElevation = 2.dp
                    ) {
                        Row(
                            modifier = Modifier.fillMaxSize(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                painter = painterResource(id = R.drawable.ic_google),
                                contentDescription = null,
                                tint = Color.Unspecified,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "Sign in with Google",
                                color = Color(0xFF1F1F1F),
                                fontWeight = FontWeight.Medium,
                                style = MaterialTheme.typography.titleMedium
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "Maybe Later",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.mutedText,
                        modifier = Modifier
                            .clickable { onDismiss() }
                            .padding(vertical = 8.dp)
                    )
                }
            }
        }
    }
}

// Extension function to await task with Coroutine
private suspend fun <T> com.google.android.gms.tasks.Task<T>.awaitTask(): T {
    return kotlinx.coroutines.suspendCancellableCoroutine { cont ->
        addOnCompleteListener { task ->
            if (task.isSuccessful) {
                cont.resume(task.result, onCancellation = null)
            } else {
                cont.resumeWith(Result.failure(task.exception ?: Exception("Task failed")))
            }
        }
    }
}
