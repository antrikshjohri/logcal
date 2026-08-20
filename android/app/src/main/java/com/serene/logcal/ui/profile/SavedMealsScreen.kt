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
import androidx.compose.foundation.BorderStroke
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import com.serene.logcal.ui.components.RenameFavoriteDialog
import com.serene.logcal.ui.components.ModernConfirmationDialog
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Menu
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.zIndex
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.material3.TextButton
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

@OptIn(ExperimentalFoundationApi::class)
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
    var isEditMode by remember { mutableStateOf(false) }

    var activeList by remember { mutableStateOf<List<SavedMealEntity>>(emptyList()) }
    var draggingItemId by remember { mutableStateOf<String?>(null) }
    var dragOffsetY by remember { mutableStateOf(0f) }

    androidx.compose.runtime.LaunchedEffect(savedMeals, draggingItemId) {
        if (draggingItemId == null) {
            activeList = savedMeals
        }
    }

    val json = remember { Json { ignoreUnknownKeys = true } }

    if (mealBeingRenamed != null) {
        val savedMeal = mealBeingRenamed!!
        RenameFavoriteDialog(
            title = "Rename Favourite Meal",
            initialText = renameText.ifBlank { savedMeal.title },
            placeholder = "Name",
            onDismiss = { mealBeingRenamed = null },
            onSave = { newName ->
                coroutineScope.launch {
                    try {
                        val updated = savedMeal.copy(
                            title = newName.take(140),
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
        )
    }

    if (mealPendingDeletion != null) {
        val savedMeal = mealPendingDeletion!!
        ModernConfirmationDialog(
            title = "Delete Favourite Meal?",
            message = "Are you sure you want to delete this favourite meal? This action cannot be undone.",
            confirmText = "Delete Favorite",
            onConfirm = {
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
            onDismiss = { mealPendingDeletion = null }
        )
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
            Spacer(modifier = Modifier.weight(1f))
            if (savedMeals.isNotEmpty()) {
                TextButton(
                    onClick = { isEditMode = !isEditMode }
                ) {
                    Text(
                        text = if (isEditMode) "Done" else "Edit",
                        color = colors.primaryGreen,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
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
            val density = androidx.compose.ui.platform.LocalDensity.current
            val lazyListState = rememberLazyListState()

            LazyColumn(
                state = lazyListState,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                itemsIndexed(activeList, key = { _, fav -> fav.id }) { index, fav ->
                    val response = remember(fav.rawResponseJson) {
                        try {
                            json.decodeFromString(MealLogResponse.serializer(), fav.rawResponseJson)
                        } catch (e: Exception) {
                            null
                        }
                    }
                    val itemsText = response?.items?.take(3)?.joinToString(", ") { it.name } ?: ""

                    val isDragging = draggingItemId == fav.id
                    val dragOffset = if (isDragging) with(density) { dragOffsetY.toDp() } else 0.dp

                    // Card representing Favourite meal
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .zIndex(if (isDragging) 10f else 1f)
                            .offset(y = dragOffset)
                            .animateItemPlacement()
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
                                if (!isEditMode) {
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

                                if (isEditMode) {
                                    Icon(
                                        imageVector = Icons.Default.Menu,
                                        contentDescription = "Drag to reorder",
                                        tint = colors.mutedText,
                                        modifier = Modifier
                                            .size(24.dp)
                                            .pointerInput(fav.id) {
                                                detectDragGestures(
                                                    onDragStart = {
                                                        draggingItemId = fav.id
                                                        dragOffsetY = 0f
                                                    },
                                                    onDragEnd = {
                                                        coroutineScope.launch {
                                                            try {
                                                                val updated = activeList.mapIndexed { idx, item ->
                                                                    item.copy(displayOrder = idx, updatedAtMillis = System.currentTimeMillis())
                                                                }
                                                                favRepo.saveAll(updated)
                                                                syncService.syncSavedMealsToCloud()
                                                            } catch (e: Exception) {
                                                                DebugLogger.e("DEBUG: Failed to save drag order", e)
                                                            } finally {
                                                                draggingItemId = null
                                                            }
                                                        }
                                                    },
                                                    onDragCancel = {
                                                        draggingItemId = null
                                                    },
                                                    onDrag = { change, dragAmount ->
                                                        change.consume()
                                                        dragOffsetY += dragAmount.y
                                                        
                                                        val currentList = activeList
                                                        val dragId = draggingItemId
                                                        if (dragId != null) {
                                                            val idx = currentList.indexOfFirst { it.id == dragId }
                                                            if (idx != -1) {
                                                                val layoutInfo = lazyListState.layoutInfo
                                                                val draggingItemInfo = layoutInfo.visibleItemsInfo.firstOrNull { it.key == dragId }
                                                                if (draggingItemInfo != null) {
                                                                    val currentVisualTop = draggingItemInfo.offset + dragOffsetY
                                                                    val currentVisualCenter = currentVisualTop + draggingItemInfo.size / 2
                                                                    
                                                                    if (dragOffsetY > 0 && idx < currentList.size - 1) {
                                                                        val nextItem = currentList[idx + 1]
                                                                        val nextItemInfo = layoutInfo.visibleItemsInfo.firstOrNull { it.key == nextItem.id }
                                                                        if (nextItemInfo != null) {
                                                                            val nextItemCenter = nextItemInfo.offset + nextItemInfo.size / 2
                                                                            if (currentVisualCenter > nextItemCenter) {
                                                                                val newList = currentList.toMutableList()
                                                                                newList[idx] = nextItem
                                                                                newList[idx + 1] = currentList[idx]
                                                                                activeList = newList
                                                                                dragOffsetY -= nextItemInfo.size
                                                                            }
                                                                        }
                                                                    } else if (dragOffsetY < 0 && idx > 0) {
                                                                        val prevItem = currentList[idx - 1]
                                                                        val prevItemInfo = layoutInfo.visibleItemsInfo.firstOrNull { it.key == prevItem.id }
                                                                        if (prevItemInfo != null) {
                                                                            val prevItemCenter = prevItemInfo.offset + prevItemInfo.size / 2
                                                                            if (currentVisualCenter < prevItemCenter) {
                                                                                val newList = currentList.toMutableList()
                                                                                newList[idx] = prevItem
                                                                                newList[idx - 1] = currentList[idx]
                                                                                activeList = newList
                                                                                dragOffsetY += prevItemInfo.size
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                )
                                            }
                                    )
                                } else {
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
                                val fiber = response.fiber
                                if (protein > 0.0 || carbs > 0.0 || fat > 0.0) {
                                    Text("·", style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                                    val macrosText = if (fiber != null) {
                                        "P: ${protein.roundToInt()}g  C: ${carbs.roundToInt()}g  F: ${fat.roundToInt()}g  Fib: ${fiber.roundToInt()}g"
                                    } else {
                                        "P: ${protein.roundToInt()}g  C: ${carbs.roundToInt()}g  F: ${fat.roundToInt()}g"
                                    }
                                    Text(
                                        macrosText,
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

                item {
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
        }
    }
}
