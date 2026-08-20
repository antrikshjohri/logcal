package com.serene.logcal.ui.profile

import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.ui.draw.shadow
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
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Message
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.QuestionMark
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.TextFields
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.health.connect.client.PermissionController
import com.serene.logcal.service.HealthConnectService
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Flag
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material.icons.filled.Warning
import kotlin.math.roundToInt
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.ui.res.painterResource
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.DietStyle
import com.serene.logcal.service.FirestoreService
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.ui.auth.AuthDialog
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger

private enum class ProfileSubScreen {
    MAIN,
    EDIT_PROFILE,
    DAILY_GOAL,
    DIET_STYLE_HELPER,
    SAVED_MEALS,
    NOTIFICATIONS,
    WHATS_APP_LINK,
    HELP_FAQ
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen() {
    val context = LocalContext.current
    val auth = remember { FirebaseAuth.getInstance() }
    val firestoreService = remember { FirestoreService() }
    val prefManager = remember { AppGraph.preferenceManager(context) }
    val colors = LogCalTheme.colors

    var activeScreen by rememberSaveable { mutableStateOf(ProfileSubScreen.MAIN) }
    var recommendedDietStyle by remember { mutableStateOf<DietStyle?>(null) }

    // Dialog states
    var showAuthDialog by remember { mutableStateOf(false) }
    var showFeedbackDialog by remember { mutableStateOf(false) }
    var showThemeSelector by remember { mutableStateOf(false) }

    // User details state
    var isAnonymous by remember { mutableStateOf(true) }
    var userName by remember { mutableStateOf("Guest User") }
    var userEmail by remember { mutableStateOf("Logs are saved locally") }
    var profilePhotoUrl by remember { mutableStateOf<String?>(null) }
    var isWhatsAppLinked by remember { mutableStateOf(false) }
    var dailyGoalCalories by remember { mutableStateOf(2000.0) }

    val healthConnectService = remember { HealthConnectService.getInstance(context) }
    var isHealthConnectEnabled by remember { mutableStateOf(prefManager.isHealthConnectEnabled) }

    val healthPermissionLauncher = rememberLauncherForActivityResult(
        contract = PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions ->
        if (grantedPermissions.containsAll(HealthConnectService.PERMISSIONS)) {
            prefManager.isHealthConnectEnabled = true
            isHealthConnectEnabled = true
            Toast.makeText(context, "Google Health Connect connected", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(context, "Health Connect permissions required", Toast.LENGTH_SHORT).show()
        }
    }

    fun refreshUserDetails() {
        val currentUser = auth.currentUser
        if (currentUser != null) {
            isAnonymous = currentUser.isAnonymous
            userName = if (isAnonymous) "Guest User" else (currentUser.displayName ?: "User")
            userEmail = if (isAnonymous) "Logs are saved locally" else (currentUser.email ?: "No email")
            profilePhotoUrl = if (isAnonymous) null else currentUser.photoUrl?.toString()
        } else {
            isAnonymous = true
            userName = "Guest User"
            userEmail = "Logs are saved locally"
            profilePhotoUrl = null
        }
        dailyGoalCalories = prefManager.dailyGoal
    }

    LaunchedEffect(activeScreen) {
        refreshUserDetails()
        // Fetch WhatsApp linkage status from Firestore
        if (activeScreen == ProfileSubScreen.MAIN) {
            try {
                val info = firestoreService.fetchWhatsAppLinkageInfo()
                isWhatsAppLinked = info.phoneNumber != null
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Failed to load WhatsApp status in profile", e)
            }
        }
    }

    BackHandler(enabled = activeScreen != ProfileSubScreen.MAIN) {
        if (activeScreen == ProfileSubScreen.DIET_STYLE_HELPER) {
            activeScreen = ProfileSubScreen.DAILY_GOAL
        } else {
            activeScreen = ProfileSubScreen.MAIN
        }
    }

    if (showAuthDialog) {
        AuthDialog(
            onDismiss = { showAuthDialog = false },
            onAuthSuccess = {
                refreshUserDetails()
                Toast.makeText(context, "Welcome back!", Toast.LENGTH_SHORT).show()
            }
        )
    }

    if (showFeedbackDialog) {
        FeedbackDialog(onDismiss = { showFeedbackDialog = false })
    }

    if (showThemeSelector) {
        var selectedTheme by remember { mutableStateOf(prefManager.appTheme) }

        ModalBottomSheet(
            onDismissRequest = { showThemeSelector = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = colors.cardBackground,
            dragHandle = { BottomSheetDefaults.DragHandle(color = colors.cardBorder) }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
                    .padding(bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "Choose Theme",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryText
                )

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(colors.insetBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                ) {
                    ThemeOptionRow(
                        label = "System Default",
                        isSelected = selectedTheme == "system",
                        onSelect = { 
                            selectedTheme = "system" 
                            prefManager.appTheme = "system"
                            AnalyticsService.trackThemeChanged("system")
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder, thickness = 0.8.dp)
                    ThemeOptionRow(
                        label = "Light Mode",
                        isSelected = selectedTheme == "light",
                        onSelect = { 
                            selectedTheme = "light" 
                            prefManager.appTheme = "light"
                            AnalyticsService.trackThemeChanged("light")
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder, thickness = 0.8.dp)
                    ThemeOptionRow(
                        label = "Dark Mode",
                        isSelected = selectedTheme == "dark",
                        onSelect = { 
                            selectedTheme = "dark" 
                            prefManager.appTheme = "dark"
                            AnalyticsService.trackThemeChanged("dark")
                        }
                    )
                }
            }
        }
    }

    AnimatedContent(
        targetState = activeScreen,
        transitionSpec = {
            if (targetState.ordinal > initialState.ordinal) {
                slideInHorizontally(initialOffsetX = { width -> width }) togetherWith
                        slideOutHorizontally(targetOffsetX = { width -> -width })
            } else {
                slideInHorizontally(initialOffsetX = { width -> -width }) togetherWith
                        slideOutHorizontally(targetOffsetX = { width -> width })
            }
        },
        label = "ProfileTabNavigation"
    ) { screen ->
        when (screen) {
            ProfileSubScreen.MAIN -> MainProfileView(
                isAnonymous = isAnonymous,
                userName = userName,
                userEmail = userEmail,
                profilePhotoUrl = profilePhotoUrl,
                isWhatsAppLinked = isWhatsAppLinked,
                isHealthConnectEnabled = isHealthConnectEnabled,
                dailyGoalCalories = dailyGoalCalories,
                currentThemeName = prefManager.appTheme.replaceFirstChar { it.uppercase() },
                onNavigate = { activeScreen = it },
                onShowAuth = { showAuthDialog = true },
                onShowFeedback = { showFeedbackDialog = true },
                onShowTheme = { showThemeSelector = true },
                onToggleHealthConnect = {
                    if (healthConnectService.isAvailable()) {
                        if (prefManager.isHealthConnectEnabled) {
                            prefManager.isHealthConnectEnabled = false
                            isHealthConnectEnabled = false
                            Toast.makeText(context, "Health Connect sync disabled", Toast.LENGTH_SHORT).show()
                        } else {
                            healthPermissionLauncher.launch(HealthConnectService.PERMISSIONS)
                        }
                    } else {
                        Toast.makeText(context, "Google Health Connect is not available on this device", Toast.LENGTH_SHORT).show()
                    }
                }
            )
            ProfileSubScreen.EDIT_PROFILE -> EditProfileScreen(
                onBack = { activeScreen = ProfileSubScreen.MAIN },
                onSignOut = {
                    refreshUserDetails()
                    activeScreen = ProfileSubScreen.MAIN
                }
            )
            ProfileSubScreen.DAILY_GOAL -> DailyGoalScreen(
                onBack = {
                    recommendedDietStyle = null
                    activeScreen = ProfileSubScreen.MAIN
                },
                onNavigateToQuestionnaire = { activeScreen = ProfileSubScreen.DIET_STYLE_HELPER },
                dietStyleOverride = recommendedDietStyle
            )
            ProfileSubScreen.DIET_STYLE_HELPER -> DietStyleHelperScreen(
                calorieGoal = dailyGoalCalories,
                onApply = { style ->
                    recommendedDietStyle = style
                    activeScreen = ProfileSubScreen.DAILY_GOAL
                },
                onDismiss = { activeScreen = ProfileSubScreen.DAILY_GOAL }
            )
            ProfileSubScreen.SAVED_MEALS -> SavedMealsScreen(
                onBack = { activeScreen = ProfileSubScreen.MAIN }
            )
            ProfileSubScreen.NOTIFICATIONS -> NotificationsScreen(
                onBack = { activeScreen = ProfileSubScreen.MAIN }
            )
            ProfileSubScreen.WHATS_APP_LINK -> WhatsAppLinkScreen(
                onBack = { activeScreen = ProfileSubScreen.MAIN }
            )
            ProfileSubScreen.HELP_FAQ -> HelpFAQScreen(
                onBack = { activeScreen = ProfileSubScreen.MAIN }
            )
        }
    }
}

@Composable
private fun MainProfileView(
    isAnonymous: Boolean,
    userName: String,
    userEmail: String,
    profilePhotoUrl: String?,
    isWhatsAppLinked: Boolean,
    isHealthConnectEnabled: Boolean,
    dailyGoalCalories: Double,
    currentThemeName: String,
    onNavigate: (ProfileSubScreen) -> Unit,
    onShowAuth: () -> Unit,
    onShowFeedback: () -> Unit,
    onShowTheme: () -> Unit,
    onToggleHealthConnect: () -> Unit
) {
    val colors = LogCalTheme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Profile",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Guest Warning Banner
            if (isAnonymous) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(12.dp),
                            ambientColor = colors.shadowColor,
                            spotColor = colors.shadowColor
                        )
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.warningAmber.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = colors.warningAmber,
                            modifier = Modifier.size(28.dp)
                        )
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Guest Session", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
                            Text(
                                "Your logs are saved only on this device. Sign in to back them up to the cloud.",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.mutedText
                            )
                        }
                    }

                    Button(
                        onClick = {
                            AnalyticsService.trackProfileSignInToSyncTapped()
                            onShowAuth()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                    ) {
                        Text("Sign In to Sync", fontWeight = FontWeight.Bold, color = Color.White)
                    }
                }
            }

            // User Info Card
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(
                        elevation = 6.dp,
                        shape = RoundedCornerShape(16.dp),
                        ambientColor = colors.shadowColor,
                        spotColor = colors.shadowColor
                    )
                    .background(colors.cardBackground, RoundedCornerShape(16.dp))
                    .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(60.dp)
                        .clip(CircleShape)
                        .background(if (profilePhotoUrl.isNullOrBlank()) colors.softAccentBackground else Color.Transparent),
                    contentAlignment = Alignment.Center
                ) {
                    if (!profilePhotoUrl.isNullOrBlank()) {
                        AsyncImage(
                            model = profilePhotoUrl,
                            contentDescription = "Profile Photo",
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = colors.primaryGreen,
                            modifier = Modifier.size(36.dp)
                        )
                    }
                }

                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(userName, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
                    Text(userEmail, style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                }

                if (!isAnonymous) {
                    Text(
                        "Edit",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryGreen,
                        modifier = Modifier
                            .clickable {
                                AnalyticsService.trackProfileEditProfileTapped()
                                onNavigate(ProfileSubScreen.EDIT_PROFILE)
                            }
                            .padding(8.dp)
                    )
                }
            }

            // 1. Account & Preferences Card Group
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("ACCOUNT & PREFERENCES", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = colors.mutedText, modifier = Modifier.padding(horizontal = 6.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(12.dp),
                            ambientColor = colors.shadowColor,
                            spotColor = colors.shadowColor
                        )
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                ) {
                    // Daily Goal Row
                    SettingsActionRow(
                        title = "Daily Goal",
                        icon = Icons.Default.Flag,
                        trailingValue = "${dailyGoalCalories.roundToInt()} cal",
                        onClick = {
                            AnalyticsService.trackProfileDailyGoalTapped()
                            onNavigate(ProfileSubScreen.DAILY_GOAL)
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    // Favorites Row
                    SettingsActionRow(
                        title = "Favourite meals",
                        icon = Icons.Default.Bookmark,
                        onClick = {
                            AnalyticsService.trackProfileFavouriteMealsTapped()
                            onNavigate(ProfileSubScreen.SAVED_MEALS)
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    // Theme Row
                    SettingsActionRow(
                        title = "Theme",
                        icon = Icons.Default.Palette,
                        trailingValue = currentThemeName,
                        onClick = {
                            AnalyticsService.trackProfileThemeTapped()
                            onShowTheme()
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    // Reminders Row
                    SettingsActionRow(
                        title = "Meal Reminders",
                        icon = Icons.Default.Notifications,
                        onClick = {
                            AnalyticsService.trackProfileMealRemindersTapped()
                            onNavigate(ProfileSubScreen.NOTIFICATIONS)
                        }
                    )
                }
            }

            // 2. Integrations & Shortcuts Card Group
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("INTEGRATIONS & SHORTCUTS", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = colors.mutedText, modifier = Modifier.padding(horizontal = 6.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(12.dp),
                            ambientColor = colors.shadowColor,
                            spotColor = colors.shadowColor
                        )
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                ) {
                    SettingsActionRow(
                        title = "Google Health Connect",
                        icon = Icons.Default.Favorite,
                        trailingValue = if (isHealthConnectEnabled) "Connected" else "Not Connected",
                        onClick = onToggleHealthConnect
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    SettingsActionRow(
                        title = "Log using Whatsapp",
                        iconPainter = painterResource(id = com.serene.logcal.R.drawable.ic_whatsapp),
                        trailingValue = if (isWhatsAppLinked) "Linked" else "Not Linked",
                        onClick = {
                            AnalyticsService.trackProfileLogWhatsAppTapped()
                            onNavigate(ProfileSubScreen.WHATS_APP_LINK)
                        }
                    )
                }
            }

            // 3. Support Card Group
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("SUPPORT", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = colors.mutedText, modifier = Modifier.padding(horizontal = 6.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(12.dp),
                            ambientColor = colors.shadowColor,
                            spotColor = colors.shadowColor
                        )
                        .background(colors.cardBackground, RoundedCornerShape(12.dp))
                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                ) {
                    SettingsActionRow(
                        title = "Help & FAQ",
                        icon = Icons.Default.HelpOutline,
                        onClick = {
                            AnalyticsService.trackProfileHelpFAQTapped()
                            onNavigate(ProfileSubScreen.HELP_FAQ)
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    SettingsActionRow(
                        title = "Send Feedback",
                        icon = Icons.Default.Send,
                        onClick = {
                            AnalyticsService.trackProfileSendFeedbackTapped()
                            onShowFeedback()
                        }
                    )
                    HorizontalDivider(color = colors.cardBorder.copy(alpha = 0.5f), modifier = Modifier.padding(horizontal = 16.dp))

                    val ctx = LocalContext.current
                    SettingsActionRow(
                        title = "Privacy Policy",
                        icon = Icons.Default.Security,
                        onClick = {
                            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://logcalai.com/privacy/"))
                            ctx.startActivity(browserIntent)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(100.dp))
        }
    }
}

@Composable
private fun SettingsActionRow(
    title: String,
    icon: ImageVector? = null,
    iconPainter: androidx.compose.ui.graphics.painter.Painter? = null,
    trailingValue: String? = null,
    onClick: () -> Unit
) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (iconPainter != null) {
            Image(
                painter = iconPainter,
                contentDescription = null,
                modifier = Modifier
                    .size(20.dp)
                    .clip(RoundedCornerShape(4.dp))
            )
        } else if (icon != null) {
            Icon(icon, contentDescription = null, tint = colors.primaryGreen, modifier = Modifier.size(20.dp))
        }
        Text(title, style = MaterialTheme.typography.bodyLarge, color = colors.primaryText, modifier = Modifier.weight(1f))
        
        if (trailingValue != null) {
            Text(trailingValue, style = MaterialTheme.typography.bodyMedium, color = colors.mutedText)
        }
        
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = colors.mutedText, modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun ThemeOptionRow(
    label: String,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect() }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, style = MaterialTheme.typography.bodyLarge, color = colors.primaryText)
        RadioButton(
            selected = isSelected,
            onClick = onSelect,
            colors = RadioButtonDefaults.colors(selectedColor = colors.primaryGreen)
        )
    }
}
