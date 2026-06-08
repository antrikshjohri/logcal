package com.serene.logcal

import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.data.repository.AppGraph
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
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val auth: FirebaseAuth by lazy { FirebaseAuth.getInstance() }
    private val syncService by lazy { AppGraph.cloudSyncService(this) }
    private val prefManager by lazy { AppGraph.preferenceManager(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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

                if (currentUser == null) {
                    AuthScreen(onAuthSuccess = {
                        currentUser = auth.currentUser
                    })
                } else {
                    AppRoot()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val user = auth.currentUser
        if (user != null && !user.isAnonymous) {
            lifecycleScope.launch {
                try {
                    syncService.migrateLocalToCloud()
                } catch (e: Exception) {
                    DebugLogger.e("DEBUG: [MainActivity] migrateLocalToCloud failed", e)
                }
                syncService.syncFromCloud()
            }
        }
    }
}

private enum class RootTab { HOME, LOG, HISTORY, PROFILE }

@Composable
private fun AppRoot() {
    var selectedTab by rememberSaveable { mutableStateOf(RootTab.HOME) }
    val dashboardViewModel: DashboardViewModel = viewModel()
    val logViewModel: LogViewModel = viewModel()
    val historyViewModel: HistoryViewModel = viewModel()

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = selectedTab == RootTab.HOME,
                    onClick = { selectedTab = RootTab.HOME },
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Home") }
                )
                NavigationBarItem(
                    selected = selectedTab == RootTab.LOG,
                    onClick = { selectedTab = RootTab.LOG },
                    icon = { Icon(Icons.Default.Restaurant, contentDescription = "Log") },
                    label = { Text("Log") }
                )
                NavigationBarItem(
                    selected = selectedTab == RootTab.HISTORY,
                    onClick = { selectedTab = RootTab.HISTORY },
                    icon = { Icon(Icons.Default.History, contentDescription = "History") },
                    label = { Text("History") }
                )
                NavigationBarItem(
                    selected = selectedTab == RootTab.PROFILE,
                    onClick = { selectedTab = RootTab.PROFILE },
                    icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
                    label = { Text("Profile") }
                )
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            when (selectedTab) {
                RootTab.HOME -> DashboardScreen(viewModel = dashboardViewModel)
                RootTab.LOG -> LogMealScreen(viewModel = logViewModel)
                RootTab.HISTORY -> HistoryScreen(
                    viewModel = historyViewModel,
                    onNavigateToLogTab = { selectedTab = RootTab.LOG },
                )
                RootTab.PROFILE -> ProfileScreen()
            }
        }
    }
}
