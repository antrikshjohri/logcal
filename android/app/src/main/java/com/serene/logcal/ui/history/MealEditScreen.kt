package com.serene.logcal.ui.history

import android.app.DatePickerDialog
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.gson.Gson
import com.serene.logcal.data.local.HistoryMeal
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.service.FirebaseMealRepository
import com.serene.logcal.ui.components.MealSourcesRow
import com.serene.logcal.ui.components.CalendarBottomSheet
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.NumberUtils
import com.serene.logcal.viewmodel.history.HistoryViewModel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val json = Json { ignoreUnknownKeys = true; isLenient = true }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MealEditScreen(
    mealId: String,
    viewModel: HistoryViewModel,
    onBack: () -> Unit
) {
    val colors = LogCalTheme.colors
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var mealState by remember { mutableStateOf<HistoryMeal?>(null) }
    var loaded by remember { mutableStateOf(false) }

    var showCalendar by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }

    // Form inputs state
    var editedDateMillis by remember { mutableStateOf(0L) }
    var editedMealType by remember { mutableStateOf("snack") }
    var editedCalories by remember { mutableStateOf(0.0) }

    // Modifiers/overrides state
    var isEditingCalories by remember { mutableStateOf(false) }
    var caloriesText by remember { mutableStateOf("") }
    var caloriesManuallyOverridden by remember { mutableStateOf(false) }
    var originalResponseJson by remember { mutableStateOf("") }
    var modifiedResponseJson by remember { mutableStateOf("") }

    // Dialog flags
    var showDeleteConfirm by remember { mutableStateOf(false) }
    var showCalorieOverrideConfirm by remember { mutableStateOf(false) }
    var isSavingFavoriteAlert by remember { mutableStateOf(false) }
    var favoriteTitleText by remember { mutableStateOf("") }
    var showFavoriteDeleteConfirm by remember { mutableStateOf(false) }

    // Quick edit prompt
    var showQuickEdit by remember { mutableStateOf(false) }
    var quickEditPrompt by remember { mutableStateOf("") }
    var isQuickEditLoading by remember { mutableStateOf(false) }
    var quickEditErrorMessage by remember { mutableStateOf<String?>(null) }

    // Favorites linkage check
    var isSavedToFavorites by remember { mutableStateOf(false) }
    var linkedFavoriteId by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(mealId) {
        val m = viewModel.getMealById(mealId)
        if (m != null) {
            mealState = m
            editedDateMillis = m.timestampMillis
            editedMealType = m.mealType
            editedCalories = m.totalCalories
            originalResponseJson = json.encodeToString(MealLogResponse.serializer(), m.response)
            modifiedResponseJson = json.encodeToString(MealLogResponse.serializer(), m.response)

            // Check override status
            caloriesManuallyOverridden = kotlin.math.abs(m.response.totalCalories - m.totalCalories) > 0.01

            // Check favorites link
            val fav = viewModel.getLinkedFavorite(mealId)
            isSavedToFavorites = fav != null
            linkedFavoriteId = fav?.id
        }
        loaded = true
    }

    LaunchedEffect(isEditingCalories) {
        if (isEditingCalories) {
            focusRequester.requestFocus()
        }
    }

    // Auto save changes whenever date or meal type changes
    fun autoSaveChanges(newDate: Long = editedDateMillis, newType: String = editedMealType, newCal: Double = editedCalories) {
        viewModel.updateMeal(
            mealId = mealId,
            timestampMillis = newDate,
            mealType = newType,
            totalCalories = newCal,
            rawResponseJson = modifiedResponseJson
        )
    }

    if (!loaded) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = colors.primaryGreen)
        }
        return
    }

    val activeMeal = mealState
    if (activeMeal == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Meal not found.", color = colors.primaryText)
        }
        return
    }

    val displayDateFormatter = remember { DateTimeFormatter.ofPattern("dd MMM yyyy") }
    val displayTimeFormatter = remember { DateTimeFormatter.ofPattern("h:mm a") }
    val activeLocalDate = Instant.ofEpochMilli(editedDateMillis).atZone(ZoneId.systemDefault()).toLocalDate()
    val activeTimeText = Instant.ofEpochMilli(activeMeal.timestampMillis).atZone(ZoneId.systemDefault()).toLocalTime().format(displayTimeFormatter)

    var mealTypeDropdownExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Meal Details", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colors.background,
                    titleContentColor = colors.primaryText,
                    navigationIconContentColor = colors.primaryText
                )
            )
        },
        containerColor = colors.background
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Success indicator header
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = colors.primaryGreen,
                    modifier = Modifier.size(44.dp)
                )
                Text(
                    "Meal Logged!",
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.titleLarge,
                    color = colors.primaryText
                )
            }

            // Calorie Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
                border = BorderStroke(1.dp, colors.cardBorder)
            ) {
                Box(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        if (isEditingCalories) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(colors.softAccentBackground)
                                        .padding(horizontal = 16.dp, vertical = 8.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    BasicTextField(
                                        value = caloriesText,
                                        onValueChange = { caloriesText = it.filter { c -> c.isDigit() }.take(5) },
                                        singleLine = true,
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                        textStyle = MaterialTheme.typography.displaySmall.copy(
                                            fontSize = 32.sp,
                                            fontWeight = FontWeight.Black,
                                            color = colors.primaryGreen,
                                            textAlign = TextAlign.Center
                                        ),
                                        modifier = Modifier
                                            .width(100.dp)
                                            .focusRequester(focusRequester)
                                    )
                                }
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    "cal",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = colors.primaryGreen
                                )
                            }
                        } else {
                            Text(
                                "${NumberUtils.formatNumber(editedCalories.toInt())} cal",
                                style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Black),
                                color = colors.primaryText
                            )
                        }

                        Text(
                            "ESTIMATED CALORIES",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = colors.mutedText
                        )
                    }

                    if (!isEditingCalories) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(12.dp)
                                .size(26.dp)
                                .clip(CircleShape)
                                .background(colors.softAccentBackground)
                                .clickable {
                                    caloriesText = editedCalories.toInt().toString()
                                    isEditingCalories = true
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Edit,
                                contentDescription = "Edit calories",
                                tint = colors.primaryGreen,
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }
                }
            }

            // Calorie edit confirm buttons
            if (isEditingCalories) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = { isEditingCalories = false },
                        colors = ButtonDefaults.buttonColors(containerColor = colors.insetBackground),
                        modifier = Modifier
                            .weight(1f)
                            .height(44.dp),
                        shape = RoundedCornerShape(22.dp)
                    ) {
                        Text("Cancel", color = colors.primaryText, fontWeight = FontWeight.Bold)
                    }

                    Button(
                        onClick = {
                            val newCals = caloriesText.toDoubleOrNull()
                            if (newCals != null && newCals > 0) {
                                val originalResponse = activeMeal.response
                                if (originalResponse.items.size == 1) {
                                    val updatedItems = originalResponse.items.map { it.copy(calories = newCals) }
                                    val updatedResponse = originalResponse.copy(
                                        totalCalories = newCals,
                                        items = updatedItems
                                    )
                                    modifiedResponseJson = json.encodeToString(MealLogResponse.serializer(), updatedResponse)
                                    editedCalories = newCals
                                    isEditingCalories = false
                                    autoSaveChanges(newCal = newCals)
                                } else if (originalResponse.items.size > 1) {
                                    showCalorieOverrideConfirm = true
                                } else {
                                    editedCalories = newCals
                                    isEditingCalories = false
                                    autoSaveChanges(newCal = newCals)
                                }
                            } else {
                                isEditingCalories = false
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen),
                        modifier = Modifier
                            .weight(1f)
                            .height(44.dp),
                        shape = RoundedCornerShape(22.dp)
                    ) {
                        Text("Save", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Macros Row
            val protein = activeMeal.response.protein ?: 0.0
            val carbs = activeMeal.response.carbs ?: 0.0
            val fat = activeMeal.response.fat ?: 0.0
            val fiber = activeMeal.response.fiber
            if (protein > 0.0 || carbs > 0.0 || fat > 0.0) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    MacroBlockItem("Protein", "${protein.toInt()}g", colors.protein)
                    Spacer(modifier = Modifier.width(8.dp))
                    MacroBlockItem("Carbs", "${carbs.toInt()}g", colors.carbs)
                    Spacer(modifier = Modifier.width(8.dp))
                    MacroBlockItem("Fat", "${fat.toInt()}g", colors.fat)
                    if (fiber != null) {
                        Spacer(modifier = Modifier.width(8.dp))
                        MacroBlockItem("Fiber", "${fiber.toInt()}g", colors.fiber)
                    }
                }
            }

            // Manual override notification
            if (caloriesManuallyOverridden) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(colors.warningAmber.copy(alpha = 0.08f))
                        .border(1.dp, colors.warningAmber.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            Icons.Default.Warning,
                            contentDescription = null,
                            tint = colors.warningAmber,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            "Calories manually overridden",
                            color = colors.warningAmber,
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                    Text(
                        "Reset",
                        color = colors.primaryGreen,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.clickable {
                            caloriesManuallyOverridden = false
                            modifiedResponseJson = originalResponseJson
                            val decoded = json.decodeFromString(MealLogResponse.serializer(), originalResponseJson)
                            editedCalories = decoded.totalCalories
                            autoSaveChanges(newCal = decoded.totalCalories)
                        }
                    )
                }
            }

            // Details card (Date, Meal Type, Logged At, What you ate)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
                border = BorderStroke(1.dp, colors.cardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    // Date row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = colors.mutedText, modifier = Modifier.size(16.dp))
                            Text("Date", fontWeight = FontWeight.SemiBold, color = colors.mutedText, style = MaterialTheme.typography.bodyMedium)
                        }
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            modifier = Modifier.clickable {
                                showCalendar = true
                            }
                        ) {
                            Text(activeLocalDate.format(displayDateFormatter), fontWeight = FontWeight.Bold, color = colors.primaryText)
                            Box(
                                modifier = Modifier
                                    .size(26.dp)
                                    .background(colors.softAccentBackground, CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    Icons.Default.Edit,
                                    contentDescription = "Edit date",
                                    tint = colors.primaryGreen,
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }
                    }

                    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(colors.cardBorder))

                    // Meal Type row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.Restaurant, contentDescription = null, tint = colors.mutedText, modifier = Modifier.size(16.dp))
                            Text("Meal Type", fontWeight = FontWeight.SemiBold, color = colors.mutedText, style = MaterialTheme.typography.bodyMedium)
                        }
                        Box {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                modifier = Modifier.clickable { mealTypeDropdownExpanded = true }
                            ) {
                                Text(editedMealType.replaceFirstChar { it.uppercase() }, fontWeight = FontWeight.Bold, color = colors.primaryGreen)
                                Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = colors.primaryGreen, modifier = Modifier.size(14.dp))
                            }
                            DropdownMenu(
                                expanded = mealTypeDropdownExpanded,
                                onDismissRequest = { mealTypeDropdownExpanded = false },
                                modifier = Modifier.background(colors.cardBackground)
                            ) {
                                MealType.entries.forEach { mt ->
                                    DropdownMenuItem(
                                        text = { Text(mt.displayName, color = colors.primaryText) },
                                        onClick = {
                                            mealTypeDropdownExpanded = false
                                            editedMealType = mt.rawValue
                                            autoSaveChanges(newType = mt.rawValue)
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(colors.cardBorder))

                    // Logged At row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.AccessTime, contentDescription = null, tint = colors.mutedText, modifier = Modifier.size(16.dp))
                            Text("Logged At", fontWeight = FontWeight.SemiBold, color = colors.mutedText, style = MaterialTheme.typography.bodyMedium)
                        }
                        Text(activeTimeText, fontWeight = FontWeight.Medium, color = colors.primaryText)
                    }

                    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(colors.cardBorder))

                    // What you ate row + inline quick edit
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("What you ate", fontWeight = FontWeight.SemiBold, color = colors.mutedText, style = MaterialTheme.typography.bodyMedium)
                            Box(
                                modifier = Modifier
                                    .size(26.dp)
                                    .clip(CircleShape)
                                    .background(colors.softAccentBackground)
                                    .clickable { showQuickEdit = !showQuickEdit },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = if (showQuickEdit) Icons.Default.Close else Icons.Default.Edit,
                                    contentDescription = "Quick edit",
                                    tint = colors.primaryGreen,
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }

                        Text(
                            activeMeal.foodText,
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.primaryText,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(colors.insetBackground)
                                .padding(12.dp)
                        )

                        AnimatedVisibility(visible = showQuickEdit) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                OutlinedTextField(
                                    value = quickEditPrompt,
                                    onValueChange = { quickEditPrompt = it },
                                    placeholder = { Text("Type correction...", color = colors.quietText) },
                                    singleLine = true,
                                    textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = colors.primaryGreen,
                                        unfocusedBorderColor = colors.cardBorder,
                                        focusedContainerColor = colors.insetBackground,
                                        unfocusedContainerColor = colors.insetBackground
                                    ),
                                    modifier = Modifier.weight(1f),
                                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                                    keyboardActions = KeyboardActions(
                                        onSend = {
                                            if (quickEditPrompt.isNotBlank() && !isQuickEditLoading) {
                                                isQuickEditLoading = true
                                                quickEditErrorMessage = null
                                                coroutineScope.launch {
                                                    try {
                                                        val repo = FirebaseMealRepository()
                                                        val result = repo.refineMealLog(
                                                            foodText = activeMeal.foodText,
                                                            mealType = MealType.entries.find { it.rawValue == editedMealType } ?: MealType.BREAKFAST,
                                                            previousEstimate = activeMeal.response,
                                                            correctionPrompt = quickEditPrompt
                                                        )
                                                        result.fold(
                                                            onSuccess = { response ->
                                                                modifiedResponseJson = json.encodeToString(MealLogResponse.serializer(), response)
                                                                editedCalories = response.totalCalories
                                                                editedMealType = response.mealType
                                                                viewModel.updateMeal(
                                                                    mealId = mealId,
                                                                    timestampMillis = editedDateMillis,
                                                                    mealType = response.mealType,
                                                                    totalCalories = response.totalCalories,
                                                                    rawResponseJson = modifiedResponseJson
                                                                )
                                                                mealState = activeMeal.copy(
                                                                    mealType = response.mealType,
                                                                    totalCalories = response.totalCalories,
                                                                    response = response
                                                                )
                                                                quickEditPrompt = ""
                                                                showQuickEdit = false
                                                            },
                                                            onFailure = { t ->
                                                                quickEditErrorMessage = t.localizedMessage
                                                            }
                                                        )
                                                    } catch (e: Exception) {
                                                        quickEditErrorMessage = e.localizedMessage
                                                    } finally {
                                                        isQuickEditLoading = false
                                                    }
                                                }
                                            }
                                        }
                                    )
                                )

                                IconButton(
                                    onClick = {
                                        if (quickEditPrompt.isNotBlank() && !isQuickEditLoading) {
                                            isQuickEditLoading = true
                                            quickEditErrorMessage = null
                                            coroutineScope.launch {
                                                try {
                                                    val repo = FirebaseMealRepository()
                                                    val result = repo.refineMealLog(
                                                        foodText = activeMeal.foodText,
                                                        mealType = MealType.entries.find { it.rawValue == editedMealType } ?: MealType.BREAKFAST,
                                                        previousEstimate = activeMeal.response,
                                                        correctionPrompt = quickEditPrompt
                                                    )
                                                    result.fold(
                                                        onSuccess = { response ->
                                                            modifiedResponseJson = json.encodeToString(MealLogResponse.serializer(), response)
                                                            editedCalories = response.totalCalories
                                                            editedMealType = response.mealType
                                                            viewModel.updateMeal(
                                                                mealId = mealId,
                                                                timestampMillis = editedDateMillis,
                                                                mealType = response.mealType,
                                                                totalCalories = response.totalCalories,
                                                                rawResponseJson = modifiedResponseJson
                                                            )
                                                            mealState = activeMeal.copy(
                                                                mealType = response.mealType,
                                                                totalCalories = response.totalCalories,
                                                                response = response
                                                            )
                                                            quickEditPrompt = ""
                                                            showQuickEdit = false
                                                        },
                                                        onFailure = { t ->
                                                            quickEditErrorMessage = t.localizedMessage
                                                        }
                                                    )
                                                } catch (e: Exception) {
                                                    quickEditErrorMessage = e.localizedMessage
                                                } finally {
                                                    isQuickEditLoading = false
                                                }
                                            }
                                        }
                                    },
                                    enabled = !isQuickEditLoading && quickEditPrompt.isNotBlank(),
                                    modifier = Modifier
                                        .size(44.dp)
                                        .background(colors.primaryGreen, CircleShape)
                                ) {
                                    if (isQuickEditLoading) {
                                        CircularProgressIndicator(modifier = Modifier.size(16.dp), color = Color.White, strokeWidth = 2.dp)
                                    } else {
                                        Icon(Icons.Default.Send, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                                    }
                                }
                            }
                        }

                        quickEditErrorMessage?.let { err ->
                            Text(err, color = colors.dangerRed, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }

            // Items Breakdown List
            if (!caloriesManuallyOverridden && activeMeal.response.items.isNotEmpty()) {
                Text(
                    "Items Breakdown",
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.titleMedium,
                    color = colors.mutedText
                )

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
                    border = BorderStroke(1.dp, colors.cardBorder)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        activeMeal.response.items.forEachIndexed { index, item ->
                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(item.name, fontWeight = FontWeight.Bold, color = colors.primaryText)
                                    Text("${item.calories.toInt()} cal", fontWeight = FontWeight.Bold, color = colors.primaryGreen)
                                }
                                Text(item.quantity, style = MaterialTheme.typography.bodySmall, color = colors.mutedText)
                                if (item.protein != null && item.carbs != null && item.fat != null) {
                                    val itemMacros = if (item.fiber != null) {
                                        "Protein: ${item.protein.toInt()}g · Carbs: ${item.carbs.toInt()}g · Fat: ${item.fat.toInt()}g · Fiber: ${item.fiber.toInt()}g"
                                    } else {
                                        "Protein: ${item.protein.toInt()}g · Carbs: ${item.carbs.toInt()}g · Fat: ${item.fat.toInt()}g"
                                    }
                                    Text(
                                        itemMacros,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = colors.quietText
                                    )
                                }
                                if (!item.assumptions.isNullOrBlank()) {
                                    Text("Assumptions: ${item.assumptions}", style = MaterialTheme.typography.bodySmall, color = colors.quietText)
                                }
                            }
                            if (index < activeMeal.response.items.size - 1) {
                                Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(colors.cardBorder.copy(alpha = 0.5f)))
                            }
                        }
                        MealSourcesRow(
                            sources = activeMeal.response.sources,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }

            // Favorites and Delete buttons row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Favorites Bookmark Button
                Button(
                    onClick = {
                        if (isSavedToFavorites) {
                            showFavoriteDeleteConfirm = true
                        } else {
                            favoriteTitleText = activeMeal.foodText
                            isSavingFavoriteAlert = true
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = colors.softAccentBackground),
                    modifier = Modifier
                        .weight(1f)
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                    border = BorderStroke(1.dp, colors.cardBorder)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isSavedToFavorites) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                            contentDescription = null,
                            tint = colors.primaryGreen,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (isSavedToFavorites) "Saved" else "Save Favourite",
                            color = colors.primaryGreen,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // Delete Button
                Button(
                    onClick = { showDeleteConfirm = true },
                    colors = ButtonDefaults.buttonColors(containerColor = colors.dangerRed),
                    modifier = Modifier
                        .weight(1f)
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Delete", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }

    // Alert: Confirm calorie edit override
    if (showCalorieOverrideConfirm) {
        AlertDialog(
            onDismissRequest = { showCalorieOverrideConfirm = false },
            title = { Text("Remove Items Breakdown?") },
            text = { Text("Editing calories will remove the items breakdown. You can reset to default later.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        val newCals = caloriesText.toDoubleOrNull() ?: editedCalories
                        caloriesManuallyOverridden = true
                        modifiedResponseJson = ""
                        editedCalories = newCals
                        isEditingCalories = false
                        showCalorieOverrideConfirm = false
                        autoSaveChanges(newCal = newCals)
                    }
                ) { Text("Yes", color = colors.dangerRed) }
            },
            dismissButton = {
                TextButton(onClick = { showCalorieOverrideConfirm = false }) { Text("Cancel") }
            }
        )
    }

    // Alert: Delete meal confirm
    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Delete Meal") },
            text = { Text("Are you sure you want to delete this meal? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirm = false
                        viewModel.deleteMeal(mealId)
                        onBack()
                    }
                ) { Text("Delete", color = colors.dangerRed) }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) { Text("Cancel") }
            }
        )
    }

    // Alert: Save Favorite Dialog
    if (isSavingFavoriteAlert) {
        Dialog(onDismissRequest = { isSavingFavoriteAlert = false }) {
            Surface(
                shape = RoundedCornerShape(24.dp),
                color = colors.cardBackground,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                border = BorderStroke(1.dp, colors.cardBorder)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Header Icon
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(colors.softAccentBackground),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Bookmark,
                            contentDescription = null,
                            tint = colors.primaryGreen,
                            modifier = Modifier.size(28.dp)
                        )
                    }

                    // Titles
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "Save to Favorites",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryText,
                            textAlign = TextAlign.Center
                        )
                        Text(
                            text = "Give this meal a name so you can quickly log it later.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.mutedText,
                            textAlign = TextAlign.Center
                        )
                    }

                    // Input Field (Modern, rounded, premium border)
                    OutlinedTextField(
                        value = favoriteTitleText,
                        onValueChange = { favoriteTitleText = it },
                        singleLine = true,
                        placeholder = { Text("e.g. Grandma's Lasagna", color = colors.quietText) },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = colors.primaryGreen,
                            unfocusedBorderColor = colors.cardBorder,
                            focusedContainerColor = colors.insetBackground,
                            unfocusedContainerColor = colors.insetBackground,
                            focusedTextColor = colors.primaryText,
                            unfocusedTextColor = colors.primaryText
                        ),
                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Buttons Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Cancel button
                        TextButton(
                            onClick = { isSavingFavoriteAlert = false },
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp),
                            shape = RoundedCornerShape(24.dp),
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = colors.mutedText
                            )
                        ) {
                            Text(
                                "Cancel",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }

                        // Save button
                        Button(
                            onClick = {
                                if (favoriteTitleText.isNotBlank()) {
                                    viewModel.saveMealAsFavorite(mealId, favoriteTitleText)
                                    isSavedToFavorites = true
                                }
                                isSavingFavoriteAlert = false
                            },
                            modifier = Modifier
                                .weight(1.5f)
                                .height(48.dp),
                            shape = RoundedCornerShape(24.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = colors.primaryGreen,
                                contentColor = Color.White
                            ),
                            enabled = favoriteTitleText.isNotBlank()
                        ) {
                            Text(
                                "Save",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }
        }
    }

    // Alert: Delete Favorite confirm
    if (showFavoriteDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showFavoriteDeleteConfirm = false },
            title = { Text("Delete Favorite Meal") },
            text = { Text("Are you sure you want to delete this favourite meal? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (linkedFavoriteId != null) {
                            viewModel.deleteFavoriteMeal(linkedFavoriteId!!)
                            isSavedToFavorites = false
                            linkedFavoriteId = null
                        }
                        showFavoriteDeleteConfirm = false
                    }
                ) { Text("Delete", color = colors.dangerRed) }
            },
            dismissButton = {
                TextButton(onClick = { showFavoriteDeleteConfirm = false }) { Text("Cancel") }
            }
        )
    }

    if (showCalendar) {
        CalendarBottomSheet(
            initialDate = activeLocalDate,
            onDateSelected = { date ->
                val newMillis = date.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
                editedDateMillis = newMillis
                autoSaveChanges(newDate = newMillis)
            },
            onDismiss = { showCalendar = false }
        )
    }
}

@Composable
private fun MacroBlockItem(label: String, value: String, barColor: Color) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(barColor.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(modifier = Modifier.size(6.dp).background(barColor, CircleShape))
        Text(
            "$value $label",
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = LogCalTheme.colors.primaryText,
            maxLines = 1,
            softWrap = false
        )
    }
}
