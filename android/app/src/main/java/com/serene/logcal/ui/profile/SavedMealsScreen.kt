package com.serene.logcal.ui.profile

import android.widget.Toast
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
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
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
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.util.Locale
import kotlin.math.roundToInt

@Composable
fun SavedMealsScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val favRepo = remember { AppGraph.localSavedMealsRepository(context) }
    val syncService = remember { AppGraph.cloudSyncService(context) }
    val colors = LogCalTheme.colors

    val savedMeals by favRepo.observeAll().collectAsState(initial = emptyList())

    var mealBeingRenamed by remember { mutableStateOf<SavedMealEntity?>(null) }
    var mealPendingDeletion by remember { mutableStateOf<SavedMealEntity?>(null) }
    var renameText by remember { mutableStateOf("") }

    val json = remember { Json { ignoreUnknownKeys = true } }

    if (mealBeingRenamed != null) {
        Dialog(onDismissRequest = { mealBeingRenamed = null }) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = colors.background,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        "Rename Favourite Meal",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )

                    OutlinedTextField(
                        value = renameText,
                        onValueChange = { renameText = it },
                        placeholder = { Text("Name", color = colors.quietText) },
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

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "Cancel",
                            modifier = Modifier
                                .clickable { mealBeingRenamed = null }
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = colors.mutedText
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Button(
                            onClick = {
                                val savedMeal = mealBeingRenamed ?: return@Button
                                val trimmed = renameText.trim()
                                if (trimmed.isNotEmpty()) {
                                    coroutineScope.launch {
                                        try {
                                            val updated = savedMeal.copy(
                                                title = trimmed.take(140),
                                                updatedAtMillis = System.currentTimeMillis()
                                            )
                                            favRepo.save(updated)
                                            syncService.syncSavedMealsToCloud()
                                        } catch (e: Exception) {
                                            DebugLogger.e("DEBUG: Failed to rename", e)
                                        } finally {
                                            mealBeingRenamed = null
                                        }
                                    }
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                        ) {
                            Text("Save", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }

    if (mealPendingDeletion != null) {
        Dialog(onDismissRequest = { mealPendingDeletion = null }) {
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
                        "Delete Favourite Meal",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )

                    Text(
                        "Are you sure you want to delete this favourite meal? This action cannot be undone.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Button(
                            onClick = { mealPendingDeletion = null },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = colors.cardBackground, contentColor = colors.primaryText),
                            border = androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder)
                        ) {
                            Text("Cancel", fontWeight = FontWeight.Bold)
                        }

                        Button(
                            onClick = {
                                val savedMeal = mealPendingDeletion ?: return@Button
                                coroutineScope.launch {
                                    try {
                                        favRepo.delete(savedMeal.id)
                                        syncService.syncSavedMealsToCloud()
                                    } catch (e: Exception) {
                                        DebugLogger.e("DEBUG: Failed to delete", e)
                                    } finally {
                                        mealPendingDeletion = null
                                    }
                                }
                            },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = colors.dangerRed, contentColor = Color.White)
                        ) {
                            Text("Delete", fontWeight = FontWeight.Bold)
                        }
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
                Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = colors.primaryText)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "Favourites",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        if (savedMeals.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.BookmarkBorder,
                        contentDescription = null,
                        tint = colors.mutedText,
                        modifier = Modifier.size(64.dp)
                    )
                    Text(
                        "No Favourites",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )
                    Text(
                        "Save meals after logging them to make repeat logging faster.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center
                    )
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                savedMeals.forEach { fav ->
                    val response = remember(fav.rawResponseJson) {
                        try {
                            json.decodeFromString(MealLogResponse.serializer(), fav.rawResponseJson)
                        } catch (e: Exception) {
                            null
                        }
                    }
                    val itemsText = response?.items?.take(3)?.joinToString(", ") { it.name } ?: ""

                    // Card representing Favourite meal
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.cardBackground, RoundedCornerShape(12.dp))
                            .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    fav.title,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = colors.primaryText,
                                    modifier = Modifier.weight(1f, fill = false)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                IconButton(
                                    onClick = {
                                        renameText = fav.title
                                        mealBeingRenamed = fav
                                    },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Edit,
                                        contentDescription = "Rename",
                                        tint = colors.primaryGreen,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Text(
                                    "${fav.totalCalories.roundToInt()} cal",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = colors.primaryText,
                                    fontWeight = FontWeight.Bold
                                )

                                IconButton(
                                    onClick = { mealPendingDeletion = fav },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "Delete",
                                        tint = colors.dangerRed,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                fav.mealType.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() },
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.primaryGreen,
                                fontWeight = FontWeight.Bold
                            )

                            if (response != null) {
                                val protein = response.protein ?: 0.0
                                val carbs = response.carbs ?: 0.0
                                val fat = response.fat ?: 0.0
                                if (protein > 0.0 || carbs > 0.0 || fat > 0.0) {
                                    Text("·", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                                    Text(
                                        "P: ${protein.roundToInt()}g  C: ${carbs.roundToInt()}g  F: ${fat.roundToInt()}g",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = colors.mutedText
                                    )
                                }
                            }
                        }

                        if (itemsText.isNotEmpty()) {
                            Text(
                                itemsText,
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.mutedText,
                                maxLines = 1
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}
