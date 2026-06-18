package com.serene.logcal.ui.history

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.viewmodel.history.HistoryViewModel
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MealDetailScreen(
    mealId: String,
    viewModel: HistoryViewModel,
    onBack: () -> Unit,
) {
    var meal by remember { mutableStateOf<HistoryMeal?>(null) }
    var loaded by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    LaunchedEffect(mealId) {
        DebugLogger.d("DEBUG: [MealDetailScreen] LaunchedEffect load mealId=$mealId")
        meal = viewModel.getMealById(mealId)
        loaded = true
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Meal") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        if (!loaded) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        val m = meal
        if (m == null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Meal not found", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.padding(8.dp))
                Button(onClick = onBack) { Text("Go back") }
            }
            return@Scaffold
        }

        val zone = ZoneId.systemDefault()
        val dateFmt = remember { DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.getDefault()) }
        val timeFmt = remember { DateTimeFormatter.ofPattern("h:mm a", Locale.getDefault()) }
        val zdt = Instant.ofEpochMilli(m.timestampMillis).atZone(zone)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF2F2F6))
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            DetailSection(title = "Date") {
                Text(zdt.toLocalDate().format(dateFmt), style = MaterialTheme.typography.bodyLarge)
            }
            DetailSection(title = "Time") {
                Text(zdt.toLocalTime().format(timeFmt), style = MaterialTheme.typography.bodyLarge)
            }
            DetailSection(title = "Meal type") {
                Text(
                    m.mealType.replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
            DetailSection(title = "What you ate") {
                Text(m.foodText, style = MaterialTheme.typography.bodyLarge)
            }
            DetailSection(title = "Total calories") {
                Text(
                    "${m.totalCalories.toInt()} cal",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF007AFF),
                )
            }
            val p = m.response.protein
            val c = m.response.carbs
            val f = m.response.fat
            val fib = m.response.fiber
            if (p != null && c != null && f != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                ) {
                    MacroColumn(label = "Protein", value = "${p.toInt()}g")
                    MacroColumn(label = "Carbs", value = "${c.toInt()}g")
                    MacroColumn(label = "Fat", value = "${f.toInt()}g")
                    if (fib != null) {
                        MacroColumn(label = "Fiber", value = "${fib.toInt()}g")
                    }
                }
            }
            if (m.response.items.isNotEmpty()) {
                Text("Items breakdown", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                m.response.items.forEach { item ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.White, MaterialTheme.shapes.medium)
                            .padding(12.dp),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(item.name, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            Text("${item.calories.toInt()} cal", fontWeight = FontWeight.SemiBold)
                        }
                        Text(
                            item.quantity,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            Button(
                onClick = {
                    DebugLogger.d("DEBUG: [MealDetailScreen] Delete tapped mealId=$mealId")
                    showDeleteDialog = true
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF3B30)),
            ) {
                Text("Delete meal")
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete meal?") },
            text = { Text("This cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        DebugLogger.d("DEBUG: [MealDetailScreen] delete confirmed mealId=$mealId")
                        viewModel.deleteMeal(mealId)
                        onBack()
                    },
                ) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") }
            },
        )
    }
}

@Composable
private fun DetailSection(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.White, MaterialTheme.shapes.medium)
                .padding(12.dp),
        ) {
            content()
        }
    }
}

@Composable
private fun MacroColumn(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
