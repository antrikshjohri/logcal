package com.serene.logcal.ui

import android.app.DatePickerDialog
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.viewmodel.LogViewModel
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogMealScreen(viewModel: LogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var expanded by remember { mutableStateOf(false) }
    var lastErrorShown: String? by remember { mutableStateOf(null) }
    val density = LocalDensity.current
    var mealTypeButtonWidth by remember { mutableStateOf(0.dp) }

    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    val displayFormatter = remember { DateTimeFormatter.ofPattern("dd MMM yyyy") }

    Scaffold(containerColor = Color(0xFFF2F2F6)) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .background(Color(0xFFF2F2F6))
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))
            Text("Log Calories", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
            Text("Welcome Antriksh Johri", color = Color(0xFF1E9BFF), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)

            if (!uiState.isAuthReady) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator()
                    Spacer(modifier = Modifier.width(10.dp))
                    Text("Signing in anonymously...")
                }
            } else {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Date", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                        Button(
                            onClick = {
                                val d = uiState.selectedDate
                                DatePickerDialog(
                                    context,
                                    { _, y, m, day -> viewModel.setSelectedDate(LocalDate.of(y, m + 1, day)) },
                                    d.year,
                                    d.monthValue - 1,
                                    d.dayOfMonth
                                ).show()
                            },
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEBEBEF), contentColor = Color(0xFF222222)),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                Text(uiState.selectedDate.format(displayFormatter))
                                Spacer(modifier = Modifier.weight(1f))
                                Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = Color(0xFF1E9BFF))
                            }
                        }
                    }

                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Meal Type", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                        Box {
                            Button(
                                onClick = {
                                    expanded = !expanded
                                    DebugLogger.d("LogMealScreen meal type menu expanded: $expanded")
                                },
                                shape = RoundedCornerShape(10.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEBEBEF), contentColor = Color(0xFF1E9BFF)),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .onGloballyPositioned { coordinates ->
                                        mealTypeButtonWidth = with(density) { coordinates.size.width.toDp() }
                                    }
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        uiState.selectedMealType.displayName,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Spacer(modifier = Modifier.weight(1f))
                                    Icon(
                                        imageVector = Icons.Default.KeyboardArrowDown,
                                        contentDescription = "Open meal type options",
                                        tint = Color(0xFF1E9BFF)
                                    )
                                }
                            }
                            DropdownMenu(
                                expanded = expanded,
                                onDismissRequest = { expanded = false },
                                modifier = Modifier
                                    .width(mealTypeButtonWidth)
                                    .background(Color.White, RoundedCornerShape(16.dp))
                            ) {
                                MealType.entries.forEach { mt ->
                                    val isSelected = uiState.selectedMealType == mt
                                    DropdownMenuItem(
                                        text = {
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                if (isSelected) {
                                                    Icon(
                                                        imageVector = Icons.Default.Check,
                                                        contentDescription = null,
                                                        tint = Color(0xFF1E9BFF),
                                                        modifier = Modifier.size(18.dp)
                                                    )
                                                } else {
                                                    Spacer(modifier = Modifier.width(18.dp))
                                                }
                                                Spacer(modifier = Modifier.width(10.dp))
                                                Text(
                                                    mt.displayName,
                                                    style = MaterialTheme.typography.titleMedium,
                                                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                                    color = if (isSelected) Color(0xFF1A1A1A) else Color(0xFF3C3C43)
                                                )
                                            }
                                        },
                                        onClick = {
                                            expanded = false
                                            DebugLogger.d("LogMealScreen meal type selected: ${mt.name}")
                                            viewModel.setMealType(mt)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                Text("What did you eat?", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(185.dp)
                        .background(Color.White, RoundedCornerShape(12.dp))
                        .border(1.dp, Color(0xFFDADAE0), RoundedCornerShape(12.dp))
                        .padding(14.dp)
                ) {
                    BasicTextField(
                        value = uiState.foodText,
                        onValueChange = viewModel::onFoodTextChanged,
                        modifier = Modifier.fillMaxWidth().height(128.dp),
                        textStyle = MaterialTheme.typography.titleLarge.copy(color = Color(0xFF202020))
                    )
                    if (uiState.foodText.isBlank()) {
                        Text("Speak naturally about your meal...", color = Color(0xFF9A9AA1), style = MaterialTheme.typography.titleLarge)
                    }
                    Row(
                        modifier = Modifier.align(Alignment.BottomEnd),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        LogIconButton(Icons.Default.CameraAlt)
                        LogIconButton(Icons.Default.Image)
                        LogIconButton(Icons.Default.Mic)
                    }
                }

                Button(
                    onClick = { viewModel.logMeal() },
                    enabled = uiState.foodText.trim().isNotEmpty() && !uiState.isLoading,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (uiState.foodText.trim().isNotEmpty() && !uiState.isLoading) Color(0xFF168CED) else Color(0xFF9A9AA1),
                        contentColor = Color.White
                    ),
                    modifier = Modifier.fillMaxWidth().height(58.dp)
                ) {
                    if (uiState.isLoading) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            LoadingDot(Color(0xFF7D8CE6))
                            LoadingDot(Color(0xFF95A5EA))
                            LoadingDot(Color(0xFFB09EDB))
                            LoadingDot(Color(0xFFC68FCC))
                            LoadingDot(Color(0xFFE08FB9))
                        }
                    } else {
                        Text("Log Meal", fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleMedium)
                    }
                }

                uiState.latestResult?.let { ResultCard(it) }
            }
        }
    }
}

@Composable
private fun LogIconButton(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Box(
        modifier = Modifier.size(36.dp).background(Color(0xFFE5F4FF), RoundedCornerShape(18.dp)),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = Color(0xFF1E9BFF), modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun ResultCard(result: MealLogResponse) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFFFFFFF))
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Logged Successfully", fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleLarge)
                Spacer(modifier = Modifier.weight(1f))
                Box(modifier = Modifier.background(Color(0xFFD9EBFF), RoundedCornerShape(8.dp)).padding(horizontal = 10.dp, vertical = 6.dp)) {
                    Text(result.mealType.replaceFirstChar { it.uppercase() }, color = Color(0xFF285F93))
                }
            }
            Text("Total Calories: ${result.totalCalories.toInt()}", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)

            if (result.protein != null && result.carbs != null && result.fat != null) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    MacroBlock("Protein", "${result.protein!!.toInt()}g")
                    MacroBlock("Carbs", "${result.carbs!!.toInt()}g")
                    MacroBlock("Fat", "${result.fat!!.toInt()}g")
                }
            }

            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(Color(0xFFE6E6EA)))

            if (result.items.isNotEmpty()) {
                Text("Items:", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                result.items.forEach { item ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(item.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Medium)
                            Text(item.quantity, color = Color(0xFF7E7E86))
                            if (!item.assumptions.isNullOrBlank()) {
                                Text("Assumptions: ${item.assumptions}", color = Color(0xFF7E7E86))
                            }
                        }
                        Text("${item.calories.toInt()} cal", color = Color(0xFF7E7E86), style = MaterialTheme.typography.titleLarge)
                    }
                }
            }
        }
    }
}

@Composable
private fun RowScope.MacroBlock(label: String, value: String) {
    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.titleSmall, color = Color(0xFF8A8A91))
    }
}

@Composable
private fun LoadingDot(color: Color) {
    Box(
        modifier = Modifier
            .size(10.dp)
            .offset(y = (-1).dp)
            .background(color, RoundedCornerShape(5.dp))
    )
}

