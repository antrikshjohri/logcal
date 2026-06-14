package com.serene.logcal

import android.Manifest
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealType
import com.serene.logcal.service.MealReminderService
import com.serene.logcal.ui.LogMealScreen
import com.serene.logcal.ui.dashboard.DashboardScreen
import com.serene.logcal.ui.history.HistoryScreen
import com.serene.logcal.ui.profile.ProfileScreen
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.viewmodel.LogViewModel
import com.serene.logcal.viewmodel.dashboard.DashboardViewModel
import com.serene.logcal.viewmodel.history.HistoryViewModel
import com.serene.logcal.ui.auth.AuthScreen
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.service.AnalyticsService
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val auth: FirebaseAuth by lazy { FirebaseAuth.getInstance() }
    private val syncService by lazy { AppGraph.cloudSyncService(this) }
    private val reminderService by lazy { AppGraph.mealReminderService(this) }
    private val prefManager by lazy { AppGraph.preferenceManager(this) }
    private var requestedRootTab by mutableStateOf<RootTab?>(null)
    private var requestedLogTarget by mutableStateOf<LogNotificationTarget?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AnalyticsService.initialize(this)
        applyLaunchIntent(intent)
        setContent {
            var themeState by rememberSaveable { mutableStateOf(prefManager.appTheme) }

            DisposableEffect(Unit) {
                val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
                    if (key == "appTheme") {
                        themeState = prefManager.appTheme
                    }
                }
                val sharedPrefs = getSharedPreferences("logcal_prefs", MODE_PRIVATE)
                sharedPrefs.registerOnSharedPreferenceChangeListener(listener)
                onDispose {
                    sharedPrefs.unregisterOnSharedPreferenceChangeListener(listener)
                }
            }

            LogCalTheme(theme = themeState) {
                val notificationPermissionLauncher = rememberLauncherForActivityResult(
                    ActivityResultContracts.RequestPermission()
                ) { granted ->
                    prefManager.hasRequestedNotificationPermission = true
                    if (granted) {
                        AnalyticsService.trackNotificationPermissionGranted()
                    } else {
                        prefManager.mealRemindersEnabled = false
                        AnalyticsService.trackNotificationPermissionDenied()
                    }
                    lifecycleScope.launch {
                        reminderService.scheduleAll()
                    }
                }

                var currentUser by remember { mutableStateOf(auth.currentUser) }

                DisposableEffect(Unit) {
                    val authListener = FirebaseAuth.AuthStateListener { firebaseAuth ->
                        currentUser = firebaseAuth.currentUser
                    }
                    auth.addAuthStateListener(authListener)
                    onDispose {
                        auth.removeAuthStateListener(authListener)
                    }
                }

                LaunchedEffect(currentUser?.uid) {
                    if (currentUser != null) {
                        handleInitialNotificationPermissionRequest(
                            launchPermissionRequest = {
                                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            }
                        )
                    }
                }

                if (currentUser == null) {
                    AuthScreen(onAuthSuccess = {
                        val newUser = auth.currentUser
                        currentUser = newUser
                        if (newUser != null) {
                            lifecycleScope.launch {
                                if (newUser.isAnonymous) {
                                    syncService.initializeAnonymousSession()
                                } else {
                                    try {
                                        syncService.migrateLocalToCloud()
                                    } catch (e: Exception) {
                                        DebugLogger.e("DEBUG: [MainActivity] migrateLocalToCloud failed", e)
                                    }
                                    syncService.syncFromCloud()
                                }
                                reminderService.scheduleAll()
                            }
                        }
                    })
                } else {
                    AppRoot(
                        requestedTab = requestedRootTab,
                        requestedLogTarget = requestedLogTarget,
                        onRequestedTabConsumed = { requestedRootTab = null },
                        onRequestedLogTargetConsumed = { requestedLogTarget = null }
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyLaunchIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        val user = auth.currentUser
        lifecycleScope.launch {
            if (user != null && !user.isAnonymous) {
                try {
                    syncService.migrateLocalToCloud()
                } catch (e: Exception) {
                    DebugLogger.e("DEBUG: [MainActivity] migrateLocalToCloud failed", e)
                }
                syncService.syncFromCloud()
            }
            reminderService.scheduleAll()
        }
    }

    companion object {
        const val EXTRA_OPEN_TAB = "open_tab"
        const val OPEN_TAB_LOG = "log"
    }

    private fun handleInitialNotificationPermissionRequest(launchPermissionRequest: () -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            prefManager.hasRequestedNotificationPermission = true
            return
        }

        if (prefManager.hasRequestedNotificationPermission) return

        if (hasPostNotificationPermission()) {
            prefManager.hasRequestedNotificationPermission = true
            lifecycleScope.launch {
                reminderService.scheduleAll()
            }
        } else {
            AnalyticsService.trackNotificationPermissionRequested()
            launchPermissionRequest()
        }
    }

    private fun hasPostNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun applyLaunchIntent(intent: Intent?) {
        val logTarget = intent.requestedLogTarget()
        requestedRootTab = logTarget?.let { RootTab.LOG } ?: intent.requestedRootTab()
        requestedLogTarget = logTarget
        DebugLogger.d(
            "DEBUG: [MainActivity] applyLaunchIntent openTab=${intent?.getStringExtra(EXTRA_OPEN_TAB)} " +
                "mealType=${intent?.getStringExtra(MealReminderService.EXTRA_MEAL_TYPE)} " +
                "parsedTarget=${logTarget?.mealType?.rawValue} requestedTab=$requestedRootTab"
        )
    }
}

private enum class RootTab { HOME, LOG, HISTORY, PROFILE }

private data class LogNotificationTarget(
    val mealType: MealType,
    val token: Long = System.nanoTime()
)

@Composable
private fun AppRoot(
    requestedTab: RootTab?,
    requestedLogTarget: LogNotificationTarget?,
    onRequestedTabConsumed: () -> Unit,
    onRequestedLogTargetConsumed: () -> Unit
) {
    var selectedTab by rememberSaveable { mutableStateOf(requestedTab ?: RootTab.HOME) }
    val dashboardViewModel: DashboardViewModel = viewModel()
    val logViewModel: LogViewModel = viewModel()
    val historyViewModel: HistoryViewModel = viewModel()

    LaunchedEffect(selectedTab) {
        val tabName = when (selectedTab) {
            RootTab.HOME -> "Dashboard"
            RootTab.LOG -> "Log"
            RootTab.HISTORY -> "History"
            RootTab.PROFILE -> "Profile"
        }
        AnalyticsService.trackTabChanged(tabName)
        AnalyticsService.trackViewOpened(tabName)
    }

    LaunchedEffect(requestedTab) {
        requestedTab?.let {
            selectedTab = it
            onRequestedTabConsumed()
        }
    }

    LaunchedEffect(requestedLogTarget?.token) {
        requestedLogTarget?.let { target ->
            DebugLogger.d("DEBUG: [MainActivity] Applying notification target mealType=${target.mealType.rawValue}")
            selectedTab = RootTab.LOG
            logViewModel.applyNotificationTarget(target.mealType)
            onRequestedLogTargetConsumed()
        }
    }

    Scaffold(
        containerColor = LogCalTheme.colors.background
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = innerPadding.calculateTopPadding())
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
            ) {
                when (selectedTab) {
                    RootTab.HOME -> DashboardScreen(
                        viewModel = dashboardViewModel,
                        onNavigateToHistory = { selectedTab = RootTab.HISTORY }
                    )
                    RootTab.LOG -> LogMealScreen(viewModel = logViewModel)
                    RootTab.HISTORY -> HistoryScreen(
                        viewModel = historyViewModel,
                        onNavigateToLogTab = { selectedTab = RootTab.LOG },
                    )
                    RootTab.PROFILE -> ProfileScreen()
                }
            }

            // Translucent gradient background for bottom navigation area (covering sides & bottom)
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(110.dp)
                    .background(
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                LogCalTheme.colors.background.copy(alpha = 0.5f)
                            )
                        )
                    )
            )

            CustomFloatingBottomNavigation(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it },
                modifier = Modifier.align(Alignment.BottomCenter)
            )
        }
    }
}

private fun Intent?.requestedRootTab(): RootTab? {
    return when (this?.getStringExtra(MainActivity.EXTRA_OPEN_TAB)) {
        MainActivity.OPEN_TAB_LOG -> RootTab.LOG
        else -> null
    }
}

private fun Intent?.requestedLogTarget(): LogNotificationTarget? {
    val rawMealType = this?.getStringExtra(MealReminderService.EXTRA_MEAL_TYPE) ?: return null
    val mealType = MealType.entries.firstOrNull { it.rawValue == rawMealType } ?: return null
    return LogNotificationTarget(mealType)
}

@Composable
private fun CustomFloatingBottomNavigation(
    selectedTab: RootTab,
    onTabSelected: (RootTab) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LogCalTheme.colors
    Card(
        modifier = modifier
            .padding(horizontal = 24.dp, vertical = 10.dp)
            .fillMaxWidth()
            .height(72.dp)
            .shadow(
                elevation = 4.dp,
                shape = CircleShape,
                ambientColor = colors.shadowColor,
                spotColor = colors.shadowColor
            ),
        shape = CircleShape,
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground.copy(alpha = 0.95f)),
        border = BorderStroke(0.8.dp, colors.cardBorder.copy(alpha = 0.6f))
    ) {
        Row(
            modifier = Modifier.fillMaxSize().padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            RootTab.entries.forEach { tab ->
                val isActive = selectedTab == tab

                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight(),
                    contentAlignment = Alignment.Center
                ) {
                    val contentColor = if (isActive) colors.primaryGreen else colors.primaryText
                    val fontWeight = if (isActive) FontWeight.ExtraBold else FontWeight.Bold

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                        modifier = Modifier
                            .fillMaxSize()
                            .clickable { onTabSelected(tab) }
                    ) {
                        val icon = when (tab) {
                            RootTab.HOME -> if (isActive) Icons.Default.Home else Icons.Outlined.Home
                            RootTab.LOG -> if (isActive) Icons.Default.AddCircle else Icons.Outlined.AddCircle
                            RootTab.HISTORY -> if (isActive) Icons.Default.List else Icons.Outlined.List
                            RootTab.PROFILE -> if (isActive) Icons.Default.Person else Icons.Outlined.Person
                        }

                        Box(
                            modifier = Modifier
                                .width(54.dp)
                                .height(32.dp)
                                .clip(CircleShape)
                                .background(if (isActive) colors.softAccentBackground else Color.Transparent),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = icon,
                                contentDescription = tab.name,
                                tint = contentColor,
                                modifier = Modifier.size(26.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = when (tab) {
                                RootTab.HOME -> "Home"
                                RootTab.LOG -> "Log"
                                RootTab.HISTORY -> "History"
                                RootTab.PROFILE -> "Profile"
                            },
                            fontWeight = fontWeight,
                            fontSize = 10.sp,
                            color = contentColor
                        )
                    }
                }
            }
        }
    }
}
