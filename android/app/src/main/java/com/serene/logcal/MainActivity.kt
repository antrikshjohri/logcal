package com.serene.logcal

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.viewmodel.compose.viewModel
import com.serene.logcal.ui.LogMealScreen
import com.serene.logcal.ui.dashboard.DashboardScreen
import com.serene.logcal.ui.history.HistoryScreen
import com.serene.logcal.ui.profile.ProfileScreen
import com.serene.logcal.viewmodel.LogViewModel
import com.serene.logcal.viewmodel.dashboard.DashboardViewModel
import com.serene.logcal.viewmodel.history.HistoryViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                AppRoot()
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
        when (selectedTab) {
            RootTab.HOME -> {
                androidx.compose.foundation.layout.Box(modifier = Modifier.padding(innerPadding)) {
                    DashboardScreen(viewModel = dashboardViewModel)
                }
            }
            RootTab.LOG -> {
                androidx.compose.foundation.layout.Box(modifier = Modifier.padding(innerPadding)) {
                    LogMealScreen(viewModel = logViewModel)
                }
            }
            RootTab.HISTORY -> {
                androidx.compose.foundation.layout.Box(modifier = Modifier.padding(innerPadding)) {
                    HistoryScreen(
                        viewModel = historyViewModel,
                        onNavigateToLogTab = { selectedTab = RootTab.LOG },
                    )
                }
            }
            RootTab.PROFILE -> {
                androidx.compose.foundation.layout.Box(modifier = Modifier.padding(innerPadding)) {
                    ProfileScreen()
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun PreviewMain() {
    MaterialTheme {
        Text("LogCal Android")
    }
}

