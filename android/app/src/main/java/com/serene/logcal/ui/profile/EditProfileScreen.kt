package com.serene.logcal.ui.profile

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.UserProfileChangeRequest
import com.google.firebase.storage.FirebaseStorage
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.FirestoreService
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.net.URL
import java.util.Locale

data class CountryInfo(val code: String, val name: String)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    onBack: () -> Unit,
    onSignOut: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val auth = remember { FirebaseAuth.getInstance() }
    val firestoreService = remember { FirestoreService() }
    val prefManager = remember { AppGraph.preferenceManager(context) }
    val syncService = remember { AppGraph.cloudSyncService(context) }
    val colors = LogCalTheme.colors

    var fullName by remember { mutableStateOf("") }
    var userEmail by remember { mutableStateOf("") }
    var userCountryCode by remember { mutableStateOf("") }
    var profilePhotoUrl by remember { mutableStateOf<String?>(null) }
    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }
    var selectedImageBitmap by remember { mutableStateOf<Bitmap?>(null) }

    var originalFullName by remember { mutableStateOf("") }
    var originalCountryCode by remember { mutableStateOf("") }
    var hasPhotoChanged by remember { mutableStateOf(false) }

    var isLoading by remember { mutableStateOf(false) }
    var showCountryPicker by remember { mutableStateOf(false) }
    var showDeleteConfirmation by remember { mutableStateOf(false) }
    var showDeleteError by remember { mutableStateOf<String?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Load country list
    val countries = remember {
        Locale.getISOCountries().map { code ->
            CountryInfo(code, Locale("", code).displayCountry)
        }.sortedBy { it.name }
    }

    fun countryName(code: String): String {
        return countries.find { it.code.lowercase() == code.lowercase() }?.name ?: code
    }

    // Load current values
    LaunchedEffect(Unit) {
        val user = auth.currentUser ?: return@LaunchedEffect
        fullName = user.displayName ?: ""
        originalFullName = fullName
        userEmail = user.email ?: ""
        profilePhotoUrl = user.photoUrl?.toString()
        
        try {
            isLoading = true
            val country = firestoreService.fetchUserCountry()
            if (!country.isNullOrBlank()) {
                userCountryCode = country
                prefManager.userCountry = country
            } else {
                userCountryCode = prefManager.userCountry
            }
            originalCountryCode = userCountryCode
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: Failed to load country", e)
            userCountryCode = prefManager.userCountry
            originalCountryCode = userCountryCode
        } finally {
            isLoading = false
        }
    }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            selectedImageUri = uri
            hasPhotoChanged = true
            coroutineScope.launch(Dispatchers.IO) {
                try {
                    context.contentResolver.openInputStream(uri)?.use { stream ->
                        val bitmap = BitmapFactory.decodeStream(stream)
                        withContext(Dispatchers.Main) {
                            selectedImageBitmap = bitmap
                        }
                    }
                } catch (e: Exception) {
                    DebugLogger.e("DEBUG: Failed to decode selected image", e)
                }
            }
        }
    }

    val hasChanges = fullName != originalFullName || userCountryCode != originalCountryCode || hasPhotoChanged
    val canSave = hasChanges && !isLoading

    suspend fun uploadPhotoAndGetUrl(uri: Uri, userId: String): String {
        val storageRef = FirebaseStorage.getInstance().reference.child("users/$userId/profile.jpg")
        val inputStream = context.contentResolver.openInputStream(uri)
        val bytes = inputStream?.readBytes() ?: throw Exception("Failed to read image bytes")
        
        // Compress image
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
        val compressedBytes = outputStream.toByteArray()

        storageRef.putBytes(compressedBytes).await()
        return storageRef.downloadUrl.await().toString()
    }

    fun saveChanges() {
        val user = auth.currentUser ?: return
        isLoading = true
        errorMessage = null

        coroutineScope.launch {
            try {
                var photoUrlToSave = profilePhotoUrl
                
                // 1. Upload photo if changed
                if (hasPhotoChanged) {
                    selectedImageUri?.let { uri ->
                        photoUrlToSave = uploadPhotoAndGetUrl(uri, user.uid)
                    }
                }

                // 2. Commit profile changes (displayName & photoUri)
                if (fullName != originalFullName || hasPhotoChanged) {
                    val profileUpdates = UserProfileChangeRequest.Builder()
                        .setDisplayName(fullName.trim().takeIf { it.isNotBlank() })
                        .setPhotoUri(photoUrlToSave?.let { Uri.parse(it) })
                        .build()
                    user.updateProfile(profileUpdates).await()
                    user.reload().await()
                }

                // 3. Save country code to Firestore & Prefs
                if (userCountryCode != originalCountryCode) {
                    firestoreService.saveUserCountry(userCountryCode)
                    prefManager.userCountry = userCountryCode
                }

                Toast.makeText(context, "Profile updated successfully!", Toast.LENGTH_SHORT).show()
                isLoading = false
                onBack()
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Failed to save changes", e)
                errorMessage = e.localizedMessage ?: "Failed to save changes."
                isLoading = false
            }
        }
    }

    if (showCountryPicker) {
        var searchQuery by remember { mutableStateOf("") }
        val filteredCountries = remember(searchQuery) {
            if (searchQuery.isBlank()) countries
            else countries.filter { it.name.contains(searchQuery, ignoreCase = true) }
        }

        Dialog(onDismissRequest = { showCountryPicker = false }) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = colors.background,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(500.dp)
                    .padding(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Select Country", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
                        IconButton(onClick = { showCountryPicker = false }) {
                            Icon(Icons.Default.Close, contentDescription = "Close", tint = colors.primaryText)
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Search country...", color = colors.quietText) },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = colors.mutedText) },
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

                    Spacer(modifier = Modifier.height(16.dp))

                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        filteredCountries.forEach { country ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        userCountryCode = country.code
                                        showCountryPicker = false
                                    }
                                    .padding(vertical = 12.dp, horizontal = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(country.name, style = MaterialTheme.typography.bodyMedium, color = colors.primaryText)
                                if (userCountryCode.lowercase() == country.code.lowercase()) {
                                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = colors.primaryGreen)
                                }
                            }
                            HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f))
                        }
                    }
                }
            }
        }
    }

    if (showDeleteConfirmation) {
        Dialog(onDismissRequest = { showDeleteConfirmation = false }) {
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
                        "Delete Account",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )

                    Text(
                        "Are you sure you want to delete your account? This action cannot be undone. All your meal data, goals, and account information will be permanently deleted.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center
                    )

                    if (showDeleteError != null) {
                        Text(showDeleteError!!, color = colors.dangerRed, style = MaterialTheme.typography.bodySmall)
                    }

                    Button(
                        onClick = {
                            coroutineScope.launch {
                                try {
                                    isLoading = true
                                    val user = auth.currentUser
                                    if (user != null) {
                                        // 1. Delete user from Firestore
                                        firestoreService.deleteUserData()
                                        // 2. Clear Room DB & settings
                                        syncService.clearLocalMeals()
                                        // 3. Delete Firebase Auth account
                                        user.delete().await()
                                    }
                                    showDeleteConfirmation = false
                                    onSignOut()
                                } catch (e: Exception) {
                                    DebugLogger.e("DEBUG: Account deletion failed", e)
                                    showDeleteError = e.localizedMessage ?: "Failed to delete account. Please try re-authenticating."
                                } finally {
                                    isLoading = false
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(24.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = colors.dangerRed)
                    ) {
                        Text("Delete", fontWeight = FontWeight.Bold, color = Color.White)
                    }

                    TextButton(onClick = { showDeleteConfirmation = false }) {
                        Text("Cancel", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.mutedText)
                    }
                }
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
                Icon(Icons.Default.Close, contentDescription = "Cancel", tint = colors.primaryText)
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(
                "Edit Profile",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                "Save",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (canSave) colors.primaryGreen else colors.mutedText,
                modifier = Modifier
                    .clickable(enabled = canSave) { saveChanges() }
                    .padding(8.dp)
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Photo Picker
            Box(
                contentAlignment = Alignment.BottomEnd,
                modifier = Modifier
                    .padding(top = 16.dp)
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(colors.softAccentBackground)
                    .clickable {
                        photoPickerLauncher.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    }
            ) {
                if (selectedImageBitmap != null) {
                    Image(
                        bitmap = selectedImageBitmap!!.asImageBitmap(),
                        contentDescription = "Profile Photo",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else if (!profilePhotoUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = profilePhotoUrl,
                        contentDescription = "Profile Photo",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(60.dp)
                        )
                    }
                }

                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(colors.cardBackground, CircleShape)
                        .border(2.dp, colors.cardBorder, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.CameraAlt,
                        contentDescription = "Change photo",
                        tint = colors.primaryText,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Text(
                "Change Profile Photo",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.primaryGreen,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.clickable {
                    photoPickerLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                }
            )

            if (errorMessage != null) {
                Text(
                    errorMessage!!,
                    color = colors.dangerRed,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center
                )
            }

            if (isLoading) {
                CircularProgressIndicator(color = colors.primaryGreen)
            }

            // Full Name Input
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                Text("Full Name", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = colors.primaryText)
                OutlinedTextField(
                    value = fullName,
                    onValueChange = { fullName = it },
                    placeholder = { Text("Enter your name", color = colors.quietText) },
                    trailingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = colors.mutedText) },
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

            // Email Address read-only Input
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                Text("Email Address", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = colors.primaryText)
                OutlinedTextField(
                    value = userEmail,
                    onValueChange = {},
                    placeholder = { Text("Email address", color = colors.quietText) },
                    trailingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = colors.mutedText) },
                    singleLine = true,
                    enabled = false,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        disabledBorderColor = colors.cardBorder,
                        disabledContainerColor = colors.cardBackground.copy(alpha = 0.5f)
                    ),
                    textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.mutedText)
                )
                Text(
                    "Email cannot be changed",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.mutedText
                )
            }

            // Country Selector Button
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                Text("Country", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = colors.primaryText)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(colors.cardBackground, RoundedCornerShape(8.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(8.dp))
                        .clickable { showCountryPicker = true }
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (userCountryCode.isBlank()) "Select your country" else countryName(userCountryCode),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (userCountryCode.isBlank()) colors.quietText else colors.primaryText
                    )
                    Icon(Icons.Default.Language, contentDescription = null, tint = colors.mutedText)
                }
                Text(
                    "Providing your country helps us better identify regional meals and portion sizes",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.mutedText
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            HorizontalDivider(color = colors.cardBorder)

            // Sign Out Button
            Button(
                onClick = {
                    coroutineScope.launch {
                        auth.signOut()
                        syncService.clearLocalMeals()
                        onSignOut()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = colors.cardBackground,
                    contentColor = colors.dangerRed
                ),
                border = androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder)
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.Logout, contentDescription = null, tint = colors.dangerRed)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sign Out", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyLarge)
                }
            }

            // Delete Account text
            Text(
                "Delete Account",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.mutedText,
                modifier = Modifier
                    .clickable { showDeleteConfirmation = true }
                    .padding(vertical = 12.dp)
            )

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}
