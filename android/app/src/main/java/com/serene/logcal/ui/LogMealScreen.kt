package com.serene.logcal.ui

import android.app.DatePickerDialog
import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.serene.logcal.model.MealType
import java.time.LocalDate
import com.serene.logcal.viewmodel.LogViewModel
import java.time.format.DateTimeFormatter
import com.serene.logcal.model.MealLogResponse

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogMealScreen(viewModel: LogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    var lastErrorShown: String? by remember { mutableStateOf(null) }
    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    val displayFormatter = remember { DateTimeFormatter.ofPattern("MMM d, yyyy") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Log Calories") }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            if (!uiState.isAuthReady) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator()
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("Signing in anonymously...")
                }
            } else {
                // Date picker + meal type
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    Button(
                        onClick = {
                            val year = uiState.selectedDate.year
                            val month = uiState.selectedDate.monthValue - 1
                            val day = uiState.selectedDate.dayOfMonth

                            DatePickerDialog(
                                context,
                                { _, y, m, d ->
                                    val newDate = LocalDate.of(y, m + 1, d)
                                    viewModel.setSelectedDate(newDate)
                                },
                                year,
                                month,
                                day
                            ).show()
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(uiState.selectedDate.format(displayFormatter))
                    }

                    var expanded by remember { mutableStateOf(false) }
                    Column(modifier = Modifier.weight(1f)) {
                        ExposedDropdownMenuBox(
                            expanded = expanded,
                            onExpandedChange = { expanded = !expanded }
                        ) {
                            Button(
                                onClick = { expanded = true },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text(uiState.selectedMealType.displayName)
                            }

                            DropdownMenu(
                                expanded = expanded,
                                onDismissRequest = { expanded = false }
                            ) {
                                MealType.entries.forEach { mealType ->
                                    DropdownMenuItem(
                                        text = { Text(mealType.displayName) },
                                        onClick = {
                                            expanded = false
                                            viewModel.setMealType(mealType)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                // Text input
                Text(
                    text = "What did you eat?",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = uiState.foodText,
                    onValueChange = viewModel::onFoodTextChanged,
                    modifier = Modifier
                        .fillMaxWidth(),
                    placeholder = { Text("e.g. chicken sandwich and fries") },
                    maxLines = 6
                )

                Button(
                    onClick = { viewModel.logMeal() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = uiState.foodText.trim().isNotEmpty() && !uiState.isLoading
                ) {
                    if (uiState.isLoading) {
                        CircularProgressIndicator(modifier = Modifier.height(18.dp), strokeWidth = 2.dp)
                    } else {
                        Text("Log Meal")
                    }
                }

                uiState.latestResult?.let { result ->
                    ResultCard(result = result)
                }
            }
        }
    }
}

@Composable
private fun ResultCard(result: MealLogResponse) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Logged Successfully", fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    result.mealType.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() },
                    style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                )
            }

            Text(
                text = "Total Calories: ${result.totalCalories.toInt()}",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )

            val hasMacros = result.protein != null && result.carbs != null && result.fat != null
            if (hasMacros) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    MacroBlock(label = "Protein", value = "${result.protein!!.toInt()}g")
                    MacroBlock(label = "Carbs", value = "${result.carbs!!.toInt()}g")
                    MacroBlock(label = "Fat", value = "${result.fat!!.toInt()}g")
                }
            }

            if (result.needsClarification) {
                Text(
                    text = result.clarifyingQuestion ?: "We need a bit more info about your meal.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error
                )
            }

            if (result.items.isNotEmpty()) {
                Text("Items:", fontWeight = FontWeight.SemiBold)
                result.items.forEachIndexed { index, item ->
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Row(modifier = Modifier.fillMaxWidth()) {
                            Text(item.name, fontWeight = FontWeight.Medium)
                            Spacer(modifier = Modifier.weight(1f))
                            Text("${item.calories.toInt()} cal")
                        }
                        Text("Qty: ${item.quantity}", style = MaterialTheme.typography.bodySmall)
                        if (!item.assumptions.isNullOrBlank()) {
                            Text("Assumptions: ${item.assumptions}", style = MaterialTheme.typography.bodySmall)
                        }
                        if (index != result.items.lastIndex) {
                            Spacer(modifier = Modifier.height(10.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RowScope.MacroBlock(label: String, value: String) {
    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.labelSmall)
    }
}

