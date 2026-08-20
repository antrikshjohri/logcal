package com.serene.logcal.ui

import android.app.Activity
import com.serene.logcal.ui.profile.FeedbackDialog
import android.Manifest
import com.serene.logcal.ui.components.CalendarBottomSheet
import android.content.Context
import com.serene.logcal.service.RatingService
import android.content.pm.PackageManager
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material.icons.filled.UnfoldMore
import com.serene.logcal.ui.auth.AuthDialog
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.UTurnLeft
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material3.OutlinedButton
import com.serene.logcal.viewmodel.SpeechTarget
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.ui.draw.scale
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog

import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.ui.text.style.TextDecoration

import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.animateLottieCompositionAsState
import com.airbnb.lottie.compose.rememberLottieComposition
import com.google.firebase.auth.FirebaseAuth
import com.serene.logcal.R
import kotlinx.serialization.json.Json
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.ui.components.MealSourcesRow
import com.serene.logcal.ui.components.PendingMealsTray
import com.serene.logcal.ui.components.MealPreviewCard
import com.serene.logcal.ui.components.RenameFavoriteDialog
import com.serene.logcal.ui.components.ModernConfirmationDialog
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.util.NumberUtils
import com.serene.logcal.viewmodel.LogViewModel
import kotlinx.coroutines.delay
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

private const val LOG_MEAL_LOADING_LABEL = "Analyzing your meal…"

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun LogMealScreen(viewModel: LogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val savedMeals by viewModel.savedMeals.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    val composerFocusRequester = remember { FocusRequester() }

    var dropdownExpanded by remember { mutableStateOf(false) }
    var showCustomDatePicker by remember { mutableStateOf(false) }
    var lastErrorShown by remember { mutableStateOf<String?>(null) }
    var density = LocalDensity.current
    var mealTypeButtonWidth by remember { mutableStateOf(0.dp) }
    var pendingCameraUri by remember { mutableStateOf<Uri?>(null) }

    var showConfetti by remember { mutableStateOf(false) }
    var wasLoading by remember { mutableStateOf(false) }

    // Dialog state variables
    var selectedSavedMealForDialog by remember { mutableStateOf<SavedMealEntity?>(null) }
    var renameTargetMeal by remember { mutableStateOf<SavedMealEntity?>(null) }
    var isRenamingResultMeal by remember { mutableStateOf(false) }
    var renameTitleText by remember { mutableStateOf("") }
    var showAllFavoritesSheet by remember { mutableStateOf(false) }
    var showFeedbackDialog by remember { mutableStateOf(false) }
    var showAuthDialog by remember { mutableStateOf(false) }

    val confettiComposition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.confetti_animation)
    )
    val confettiProgress by animateLottieCompositionAsState(
        composition = confettiComposition,
        isPlaying = showConfetti,
        iterations = 1
    )
    val loadingComposition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.loading_animation)
    )
    val loadingProgress by animateLottieCompositionAsState(
        composition = loadingComposition,
        isPlaying = uiState.isLoading,
        iterations = Int.MAX_VALUE,
        restartOnPlay = true
    )

    // Launchers
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && pendingCameraUri != null) {
            viewModel.addAttachedImageUri(pendingCameraUri.toString())
        }
    }

    val cameraPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            val uri = createTempImageUri(context)
            pendingCameraUri = uri
            cameraLauncher.launch(uri)
        } else {
            Toast.makeText(context, "Camera permission is required.", Toast.LENGTH_SHORT).show()
        }
    }

    val galleryLauncher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            viewModel.addAttachedImageUri(uri.toString())
        }
    }

    val micPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            viewModel.toggleSpeechRecognition()
        } else {
            Toast.makeText(context, "Microphone permission is required.", Toast.LENGTH_SHORT).show()
        }
    }

    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    LaunchedEffect(uiState.speechErrorMessage) {
        val msg = uiState.speechErrorMessage
        if (msg != null) {
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    LaunchedEffect(uiState.showRatingPrompt) {
        if (uiState.showRatingPrompt) {
            var currentContext = context
            var activity: Activity? = null
            while (currentContext is android.content.ContextWrapper) {
                if (currentContext is Activity) {
                    activity = currentContext
                    break
                }
                currentContext = currentContext.baseContext
            }
            if (activity != null) {
                RatingService.requestRating(activity)
            }
            viewModel.onRatingPromptShown()
        }
    }

    LaunchedEffect(uiState.isLoading, uiState.latestResult) {
        if (uiState.isLoading) {
            wasLoading = true
            return@LaunchedEffect
        }
        if (wasLoading && uiState.latestResult != null) {
            showConfetti = true
            delay(2500)
            showConfetti = false
            wasLoading = false
        } else if (!uiState.isLoading) {
            wasLoading = false
        }
    }

    val colors = LogCalTheme.colors
    val dateDisplayFormatter = remember { DateTimeFormatter.ofPattern("dd MMM yyyy") }
    val currentUser = FirebaseAuth.getInstance().currentUser
    val isAnonymous = currentUser?.isAnonymous == true
    val name = if (currentUser != null && !isAnonymous) {
        currentUser.displayName ?: "there"
    } else {
        null
    }

    Scaffold(containerColor = colors.background) { innerPadding ->
        Box(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize()
                .background(colors.background)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .imePadding()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp, vertical = 20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Spacer(modifier = Modifier.height(24.dp))
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text(
                        text = "Log",
                        style = MaterialTheme.typography.headlineLarge.copy(fontSize = 32.sp),
                        fontWeight = FontWeight.ExtraBold,
                        color = colors.primaryText
                    )
                    val greeting = if (name != null) "What's on your plate, $name?" else "What's on your plate?"
                    Text(
                        text = greeting,
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        ),
                        color = colors.mutedText
                    )
                }

                if (!uiState.isAuthReady) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(color = colors.primaryGreen)
                        Spacer(modifier = Modifier.width(10.dp))
                        Text("Signing in...", color = colors.primaryText)
                    }
                } else {
                    // Date & Meal Type row selector
                    val dateText = when (uiState.selectedDate) {
                        LocalDate.now() -> "Today"
                        LocalDate.now().minusDays(1) -> "Yesterday"
                        LocalDate.now().plusDays(1) -> "Tomorrow"
                        else -> uiState.selectedDate.format(DateTimeFormatter.ofPattern("d MMM yyyy"))
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Date selector
                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "DATE",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, letterSpacing = 1.2.sp),
                                    fontWeight = FontWeight.Bold,
                                    color = colors.quietText
                                )
                                if (uiState.selectedDate != java.time.LocalDate.now()) {
                                    Row(
                                        modifier = Modifier.clickable {
                                            viewModel.setSelectedDate(java.time.LocalDate.now())
                                        },
                                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.UTurnLeft,
                                            contentDescription = null,
                                            tint = colors.primaryGreen,
                                            modifier = Modifier
                                                .size(10.dp)
                                                .rotate(90f)
                                        )
                                        Text(
                                            "Today",
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold
                                            ),
                                            color = colors.primaryGreen
                                        )
                                    }
                                }
                            }
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(38.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(colors.cardBackground)
                                    .border(0.8.dp, colors.cardBorder.copy(alpha = 0.6f), RoundedCornerShape(10.dp))
                                    .padding(horizontal = 2.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(28.dp)
                                        .clip(CircleShape)
                                        .clickable { viewModel.setSelectedDate(uiState.selectedDate.minusDays(1)) },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        Icons.Default.ChevronLeft,
                                        contentDescription = null,
                                        tint = colors.mutedText,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                Row(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable { showCustomDatePicker = true },
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = dateText,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = colors.primaryText
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Icon(
                                        Icons.Default.CalendarMonth,
                                        contentDescription = null,
                                        tint = colors.primaryGreen,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                                Box(
                                    modifier = Modifier
                                        .size(28.dp)
                                        .clip(CircleShape)
                                        .clickable { viewModel.setSelectedDate(uiState.selectedDate.plusDays(1)) },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        Icons.Default.ChevronRight,
                                        contentDescription = null,
                                        tint = colors.mutedText,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }

                        // Meal Type selector
                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Text(
                                "MEAL TYPE",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, letterSpacing = 1.2.sp),
                                fontWeight = FontWeight.Bold,
                                color = colors.quietText
                            )
                            Box {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(38.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(colors.cardBackground)
                                        .border(
                                            if (dropdownExpanded) BorderStroke(1.2.dp, colors.primaryGreen)
                                            else BorderStroke(0.8.dp, colors.cardBorder.copy(alpha = 0.6f)),
                                            RoundedCornerShape(10.dp)
                                        )
                                        .onGloballyPositioned { coordinates ->
                                            mealTypeButtonWidth = with(density) { coordinates.size.width.toDp() }
                                        }
                                        .padding(horizontal = 2.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(28.dp)
                                            .clip(CircleShape)
                                            .clickable {
                                                val types = MealType.entries
                                                val idx = (types.indexOf(uiState.selectedMealType) - 1 + types.size) % types.size
                                                viewModel.setMealType(types[idx])
                                            },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Default.ChevronLeft,
                                            contentDescription = null,
                                            tint = colors.mutedText,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                    Row(
                                        modifier = Modifier
                                            .weight(1f)
                                            .clickable { dropdownExpanded = !dropdownExpanded },
                                        horizontalArrangement = Arrangement.Center,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = uiState.selectedMealType.displayName,
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.Bold,
                                            color = colors.primaryText
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Icon(
                                            Icons.Default.UnfoldMore,
                                            contentDescription = null,
                                            tint = colors.primaryGreen,
                                            modifier = Modifier.size(14.dp)
                                        )
                                    }
                                    Box(
                                        modifier = Modifier
                                            .size(28.dp)
                                            .clip(CircleShape)
                                            .clickable {
                                                val types = MealType.entries
                                                val idx = (types.indexOf(uiState.selectedMealType) + 1) % types.size
                                                viewModel.setMealType(types[idx])
                                            },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Default.ChevronRight,
                                            contentDescription = null,
                                            tint = colors.mutedText,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                }

                                DropdownMenu(
                                    expanded = dropdownExpanded,
                                    onDismissRequest = { dropdownExpanded = false },
                                    modifier = Modifier
                                        .width(mealTypeButtonWidth)
                                        .clip(RoundedCornerShape(14.dp))
                                        .background(colors.cardBackground)
                                        .border(1.dp, colors.cardBorder, RoundedCornerShape(14.dp))
                                ) {
                                    Column(modifier = Modifier.fillMaxWidth()) {
                                        MealType.entries.forEachIndexed { index, mt ->
                                            val isSelected = uiState.selectedMealType == mt
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .height(56.dp)
                                                    .clickable {
                                                        dropdownExpanded = false
                                                        viewModel.setMealType(mt)
                                                    }
                                                    .padding(horizontal = 16.dp),
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Text(
                                                    text = mt.displayName,
                                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                                    color = if (isSelected) colors.primaryGreen else colors.primaryText,
                                                    fontSize = 16.sp
                                                )
                                                if (isSelected) {
                                                    Icon(
                                                        Icons.Default.Check,
                                                        contentDescription = null,
                                                        tint = colors.primaryGreen,
                                                        modifier = Modifier.size(18.dp)
                                                    )
                                                }
                                            }
                                            if (index < MealType.entries.size - 1) {
                                                Box(
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .height(1.dp)
                                                        .background(colors.cardBorder)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Favourites horizontal section
                    if (savedMeals.isNotEmpty()) {
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "Favourites",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp),
                                    color = colors.mutedText
                                )
                                Text(
                                    "See all",
                                    color = colors.primaryGreen,
                                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp),
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.clickable { showAllFavoritesSheet = true }
                                )
                            }
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                items(savedMeals.take(8)) { fav ->
                                    Row(
                                        modifier = Modifier
                                            .height(42.dp)
                                            .clip(CircleShape)
                                            .background(colors.cardBackground)
                                            .border(0.8.dp, colors.cardBorder.copy(alpha = 0.6f), CircleShape)
                                            .shadow(
                                                elevation = 0.5.dp,
                                                shape = CircleShape,
                                                ambientColor = colors.shadowColor,
                                                spotColor = colors.shadowColor
                                            ),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Row(
                                            modifier = Modifier
                                                .clickable { selectedSavedMealForDialog = fav }
                                                .padding(start = 12.dp, end = 8.dp, top = 8.dp, bottom = 8.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            Icon(
                                                Icons.Default.Bookmark,
                                                contentDescription = null,
                                                tint = colors.primaryGreen,
                                                modifier = Modifier.size(12.dp)
                                            )
                                            Text(
                                                text = fav.title,
                                                style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp),
                                                fontWeight = FontWeight.Bold,
                                                color = colors.primaryText,
                                                maxLines = 1,
                                                softWrap = false
                                            )
                                            Text(
                                                text = "${NumberUtils.formatNumber(fav.totalCalories.toInt())} cal",
                                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                                                fontWeight = FontWeight.SemiBold,
                                                color = colors.quietText,
                                                maxLines = 1,
                                                softWrap = false
                                            )
                                        }

                                        Box(
                                            modifier = Modifier
                                                .width(1.dp)
                                                .height(18.dp)
                                                .background(colors.cardBorder.copy(alpha = 0.8f))
                                        )

                                        Box(
                                            modifier = Modifier
                                                .clickable { viewModel.logSavedMealAsIs(fav, 1.0) }
                                                .padding(horizontal = 10.dp, vertical = 8.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                Icons.Default.Add,
                                                contentDescription = "Quick log",
                                                tint = colors.primaryGreen,
                                                modifier = Modifier.size(16.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Composer view + Submit Button grouped to control spacing
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "What did you eat?",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp),
                                color = colors.mutedText
                            )

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Text(
                                    "Preview",
                                    fontWeight = FontWeight.SemiBold,
                                    style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp),
                                    color = if (uiState.isPreviewMode) colors.accentBlue else colors.mutedText
                                )
                                Switch(
                                    checked = uiState.isPreviewMode,
                                    onCheckedChange = { viewModel.setPreviewMode(it) },
                                    colors = SwitchDefaults.colors(
                                        checkedThumbColor = Color.White,
                                        checkedTrackColor = colors.accentBlue,
                                        uncheckedThumbColor = Color.White,
                                        uncheckedTrackColor = colors.cardBorder
                                    ),
                                    modifier = Modifier.scale(0.75f)
                                )
                            }
                        }

                        if (uiState.isPreviewMode) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(colors.accentBlue.copy(alpha = 0.12f))
                                    .border(1.dp, colors.accentBlue.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                                    .padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Info,
                                        contentDescription = null,
                                        tint = colors.accentBlue,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Text(
                                        "Preview mode active — estimates calories without logging.",
                                        style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                                        color = colors.primaryText,
                                        maxLines = 1
                                    )
                                }
                                IconButton(
                                    onClick = { viewModel.setPreviewMode(false) },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = "Dismiss",
                                        tint = colors.mutedText,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                            }
                        }

                        val cardHeight = if (uiState.attachedImageUris.isNotEmpty()) 230.dp else 170.dp
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(cardHeight)
                                .shadow(
                                    elevation = 1.5.dp,
                                    shape = RoundedCornerShape(16.dp),
                                    ambientColor = colors.shadowColor,
                                    spotColor = colors.shadowColor
                                )
                                .clip(RoundedCornerShape(16.dp))
                                .background(colors.cardBackground)
                                .border(0.8.dp, colors.cardBorder.copy(alpha = 0.6f), RoundedCornerShape(16.dp))
                        ) {
                            // Text Input Area + Image Thumbnail
                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth()
                                    .padding(start = 20.dp, end = 20.dp, top = 12.dp),
                                verticalArrangement = Arrangement.SpaceBetween
                            ) {
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxWidth()
                                ) {
                                    if (uiState.foodText.isBlank() && uiState.attachedImageUris.isEmpty() && !uiState.isListening && !uiState.isTranscribingSpeech) {
                                        Text(
                                            "Write or speak naturally about what you ate...",
                                            color = colors.quietText,
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                    }
                                    BasicTextField(
                                        value = uiState.foodText,
                                        onValueChange = viewModel::onFoodTextChanged,
                                        enabled = !uiState.isListening && !uiState.isTranscribingSpeech,
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .focusRequester(composerFocusRequester),
                                        textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText)
                                    )
                                }

                                if (uiState.attachedImageUris.isNotEmpty()) {
                                    Spacer(modifier = Modifier.height(10.dp))
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(bottom = 10.dp),
                                        horizontalArrangement = Arrangement.Start
                                    ) {
                                        uiState.attachedImageUris.forEach { imageUri ->
                                            Box(modifier = Modifier.size(60.dp)) {
                                                AsyncImage(
                                                    model = imageUri,
                                                    contentDescription = null,
                                                    modifier = Modifier
                                                        .fillMaxSize()
                                                        .clip(RoundedCornerShape(8.dp))
                                                        .background(colors.insetBackground)
                                                )
                                                Box(
                                                    modifier = Modifier
                                                        .align(Alignment.TopEnd)
                                                        .offset(x = 4.dp, y = (-4).dp)
                                                        .size(16.dp)
                                                        .background(colors.cardBackground, CircleShape)
                                                        .border(0.8.dp, colors.cardBorder, CircleShape)
                                                        .clickable { viewModel.removeAttachedImageUri(imageUri) },
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Icon(
                                                        Icons.Default.Close,
                                                        contentDescription = "Remove",
                                                        tint = colors.primaryText,
                                                        modifier = Modifier.size(10.dp)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Divider
                            Box(
                                modifier = Modifier
                                    .padding(horizontal = 20.dp)
                                    .fillMaxWidth()
                                    .height(0.5.dp)
                                    .background(colors.cardBorder.copy(alpha = 0.5f))
                            )

                            // Action panel (mic, camera, gallery or dictation waveform HUD)
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(58.dp)
                                    .padding(horizontal = 20.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                if (uiState.isListening && uiState.speechTarget == SpeechTarget.MAIN) {
                                    // Cancel button
                                    Box(
                                        modifier = Modifier
                                            .size(36.dp)
                                            .clip(CircleShape)
                                            .background(colors.dangerRed)
                                            .clickable { viewModel.cancelSpeechRecognition() },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Default.Close,
                                            contentDescription = "Cancel",
                                            tint = Color.White,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(12.dp))

                                    // Dynamic Pulsing Audio Waveform HUD
                                    androidx.compose.foundation.Canvas(
                                        modifier = Modifier
                                            .weight(1f)
                                            .height(32.dp)
                                    ) {
                                        val barWidth = 3.dp.toPx()
                                        val gap = 3.dp.toPx()
                                        val totalBarSlot = barWidth + gap
                                        val numBars = (size.width / totalBarSlot).toInt().coerceAtLeast(1)
                                        val samples = uiState.waveformSamples
                                        val sampleStep = (samples.size.toFloat() / numBars).coerceAtLeast(1f)

                                        for (i in 0 until numBars) {
                                            val sampleIndex = (i * sampleStep).toInt().coerceIn(0, samples.lastIndex)
                                            val amplitude = samples.getOrElse(sampleIndex) { 0.15f }
                                            val barHeight = (size.height * amplitude).coerceIn(4.dp.toPx(), size.height)
                                            val x = i * totalBarSlot
                                            val y = (size.height - barHeight) / 2f
                                            drawRoundRect(
                                                color = Color(0xFFFFA33C),
                                                topLeft = Offset(x, y),
                                                size = Size(barWidth, barHeight),
                                                cornerRadius = CornerRadius(barWidth / 2, barWidth / 2)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.width(12.dp))

                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        // Confirm checkmark button
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(CircleShape)
                                                .background(colors.primaryGreen)
                                                .clickable { viewModel.stopSpeechRecognition() },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                Icons.Default.Check,
                                                contentDescription = "Done",
                                                tint = Color.White,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }

                                        // Submit upload button (orange, upward arrow icon)
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(CircleShape)
                                                .background(
                                                    brush = Brush.linearGradient(
                                                        colors = listOf(Color(0xFFFFA33C), Color(0xFFFF5E00))
                                                    )
                                                )
                                                .clickable {
                                                    viewModel.stopSpeechRecognition()
                                                    viewModel.logMeal()
                                                },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                Icons.Default.ArrowUpward,
                                                contentDescription = "Log",
                                                tint = Color.White,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }
                                } else {
                                    // Regular modes
                                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(colors.softAccentBackground)
                                                .clickable {
                                                    val hasCameraPermission = ContextCompat.checkSelfPermission(
                                                        context,
                                                        Manifest.permission.CAMERA
                                                    ) == PackageManager.PERMISSION_GRANTED
                                                    if (hasCameraPermission) {
                                                        val uri = createTempImageUri(context)
                                                        pendingCameraUri = uri
                                                        cameraLauncher.launch(uri)
                                                    } else {
                                                        cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                                                    }
                                                },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                Icons.Default.CameraAlt,
                                                contentDescription = "Camera",
                                                tint = colors.primaryGreen,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }

                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(colors.softAccentBackground)
                                                .clickable {
                                                    galleryLauncher.launch(
                                                        PickVisualMediaRequest(
                                                            mediaType = ActivityResultContracts.PickVisualMedia.ImageOnly
                                                        )
                                                    )
                                                },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                Icons.Default.Image,
                                                contentDescription = "Gallery",
                                                tint = colors.primaryGreen,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.weight(1f))

                                    if (uiState.isTranscribingSpeech && uiState.speechTarget == SpeechTarget.MAIN) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                                            modifier = Modifier.padding(end = 10.dp)
                                        ) {
                                            CircularProgressIndicator(
                                                modifier = Modifier.size(14.dp),
                                                color = colors.mutedText,
                                                strokeWidth = 2.dp
                                            )
                                            Text(
                                                "Transcribing...",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = colors.mutedText
                                            )
                                        }
                                    }

                                    // Orange Mic button
                                    Box(
                                        modifier = Modifier
                                            .size(42.dp)
                                            .shadow(
                                                elevation = 2.dp,
                                                shape = CircleShape,
                                                ambientColor = colors.shadowColor,
                                                spotColor = colors.shadowColor
                                            )
                                            .clip(CircleShape)
                                            .background(
                                                brush = Brush.linearGradient(
                                                    colors = listOf(Color(0xFFFFA33C), Color(0xFFFF5E00))
                                                )
                                            )
                                            .clickable(enabled = !uiState.isTranscribingSpeech) {
                                                val hasRecordPermission = ContextCompat.checkSelfPermission(
                                                    context,
                                                    Manifest.permission.RECORD_AUDIO
                                                ) == PackageManager.PERMISSION_GRANTED
                                                if (hasRecordPermission) {
                                                    viewModel.toggleSpeechRecognition()
                                                } else {
                                                    micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                                }
                                            },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Default.Mic,
                                            contentDescription = "Record voice",
                                            tint = Color.White,
                                            modifier = Modifier.size(22.dp)
                                        )
                                    }
                                }
                            }
                        }

                        // Log Meal Submit Button
                        Spacer(modifier = Modifier.height(2.dp))
                        val canSubmit = (uiState.foodText.trim().isNotEmpty() || uiState.attachedImageUris.isNotEmpty()) && !uiState.isLoading
                        val isPreview = uiState.isPreviewMode
                        val primaryButtonColor = if (isPreview) colors.accentBlue else colors.primaryGreen
                        val submitButtonTitle = if (isPreview) "Preview Meal" else "Log Meal"

                        Button(
                            onClick = {
                                focusManager.clearFocus()
                                viewModel.logMeal()
                            },
                            enabled = canSubmit,
                            shape = CircleShape,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (canSubmit) primaryButtonColor else primaryButtonColor.copy(alpha = 0.12f),
                                contentColor = if (canSubmit) Color.White else primaryButtonColor.copy(alpha = 0.4f),
                                disabledContainerColor = if (uiState.isLoading) Color.Gray.copy(alpha = 0.3f) else primaryButtonColor.copy(alpha = 0.12f),
                                disabledContentColor = if (uiState.isLoading) Color.White else primaryButtonColor.copy(alpha = 0.4f)
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp)
                                .run {
                                    if (canSubmit) {
                                        shadow(
                                            elevation = 3.dp,
                                            shape = CircleShape,
                                            ambientColor = primaryButtonColor.copy(alpha = 0.3f),
                                            spotColor = primaryButtonColor.copy(alpha = 0.4f)
                                        )
                                    } else this
                                }
                        ) {
                            if (uiState.isLoading) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(18.dp),
                                        color = Color.White,
                                        strokeWidth = 2.dp
                                    )
                                    Text(
                                        if (isPreview) "Estimating..." else "Logging...",
                                        fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.bodyMedium.copy(fontSize = 16.sp)
                                    )
                                }
                            } else {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    if (isPreview) {
                                        Icon(
                                            Icons.Default.Visibility,
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                    Text(submitButtonTitle, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium.copy(fontSize = 16.sp))
                                }
                            }
                        }
                    }

                    // In-progress / Queued meals tray
                    PendingMealsTray(
                        pendingLogs = uiState.pendingLogs,
                        onRetry = { viewModel.retryPendingMeal(it) },
                        onDismiss = { viewModel.removePendingMeal(it) }
                    )

                    // Stacked Result card section
                    uiState.completedPreviews.forEach { preview ->
                        val isSaved = savedMeals.any { it.sourceMealId == preview.id }
                        MealPreviewCard(
                            preview = preview,
                            isSaved = isSaved,
                            onLogMeal = { viewModel.logPreviewMeal(preview.id) },
                            onDismiss = { viewModel.dismissCompletedPreview(preview.id) },
                            onBookmark = {
                                val existing = savedMeals.firstOrNull { it.sourceMealId == preview.id }
                                if (existing != null) {
                                    renameTargetMeal = existing
                                } else {
                                    val saved = viewModel.saveLatestMealAsFavorite()
                                    if (saved != null) {
                                        renameTargetMeal = saved
                                        renameTitleText = saved.title
                                        isRenamingResultMeal = true
                                    }
                                }
                            },
                            onQuickEdit = { prompt ->
                                viewModel.quickRefineCompletedPreview(preview.id, prompt)
                            },
                            isListening = uiState.isListening && uiState.speechTarget == SpeechTarget.QUICK_EDIT,
                            onToggleListening = { viewModel.toggleSpeechRecognition(SpeechTarget.QUICK_EDIT) },
                            onCancelListening = { viewModel.cancelSpeechRecognition() }
                        )
                    }

                    // Send feedback link
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        Text(
                            "Send feedback",
                            style = MaterialTheme.typography.bodySmall.copy(
                                textDecoration = TextDecoration.Underline
                            ),
                            fontWeight = FontWeight.Medium,
                            color = colors.mutedText,
                            modifier = Modifier
                                .clickable { showFeedbackDialog = true }
                                .padding(vertical = 4.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(100.dp))
                }
            }

            // Confetti Lottie Overlay
            if (showConfetti) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    LottieAnimation(
                        composition = confettiComposition,
                        progress = { confettiProgress },
                        modifier = Modifier.size(360.dp)
                    )
                }
            }
        }
    }

    // SavedMealLogSheet Dialog implementation
    // SavedMealLogSheet BottomSheet implementation
    selectedSavedMealForDialog?.let { savedMeal ->
        val json = remember { Json { ignoreUnknownKeys = true } }
        var servingMultiplier by remember { mutableStateOf(1.0) }
        var isRenamingFav by remember { mutableStateOf(false) }
        var favRenameText by remember { mutableStateOf("") }
        var showDeleteConfirm by remember { mutableStateOf(false) }

        ModalBottomSheet(
            onDismissRequest = { selectedSavedMealForDialog = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = colors.cardBackground,
            dragHandle = { BottomSheetDefaults.DragHandle(color = colors.cardBorder) }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .navigationBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
                    .padding(bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Centered Header with Close Pill
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Spacer(modifier = Modifier.width(60.dp))
                    Text(
                        text = "Favourite Meal",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(colors.cardBackground)
                            .border(1.dp, colors.cardBorder, CircleShape)
                            .clickable { selectedSavedMealForDialog = null }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                            .shadow(2.dp, CircleShape, ambientColor = colors.shadowColor, spotColor = colors.shadowColor),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "Close",
                            color = colors.primaryGreen,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                    }
                }

                // Meal Summary Section
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                savedMeal.title,
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleLarge,
                                color = colors.primaryText
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Icon(
                                Icons.Default.Edit,
                                contentDescription = "Rename",
                                tint = colors.primaryGreen,
                                modifier = Modifier
                                    .size(16.dp)
                                    .clickable {
                                        favRenameText = savedMeal.title
                                        isRenamingFav = true
                                    }
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        val scaledCals = (savedMeal.totalCalories * servingMultiplier).toInt()
                        Text(
                            "${NumberUtils.formatNumber(scaledCals)} cal · ${savedMeal.mealType.replaceFirstChar { it.uppercase() }}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.mutedText,
                            fontWeight = FontWeight.Bold
                        )

                        // Parse macros if available
                        val response = remember(savedMeal.rawResponseJson) {
                            try {
                                json.decodeFromString(MealLogResponse.serializer(), savedMeal.rawResponseJson)
                            } catch (e: Exception) {
                                null
                            }
                        }
                        if (response != null) {
                            val protein = ((response.protein ?: 0.0) * servingMultiplier).toInt()
                            val carbs = ((response.carbs ?: 0.0) * servingMultiplier).toInt()
                            val fat = ((response.fat ?: 0.0) * servingMultiplier).toInt()
                            val fiber = response.fiber?.let { (it * servingMultiplier).toInt() }
                            if (protein > 0 || carbs > 0 || fat > 0) {
                                Spacer(modifier = Modifier.height(2.dp))
                                val macrosText = if (fiber != null) {
                                    "P: ${protein}g  C: ${carbs}g  F: ${fat}g  Fib: ${fiber}g"
                                } else {
                                    "P: ${protein}g  C: ${carbs}g  F: ${fat}g"
                                }
                                Text(
                                    macrosText,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = colors.mutedText
                                )
                            }
                        }

                        response?.let {
                            MealSourcesRow(
                                sources = it.sources,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }
                }

                // Serving section
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        "Serving",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium,
                        color = colors.primaryText
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp)
                            .clip(CircleShape)
                            .background(colors.insetBackground)
                            .padding(2.dp)
                    ) {
                        listOf(0.5, 1.0, 1.5, 2.0).forEach { mult ->
                            val label = when (mult) {
                                0.5 -> "0.5x"
                                1.0 -> "1x"
                                1.5 -> "1.5x"
                                2.0 -> "2x"
                                else -> "${mult}x"
                            }
                            val selected = servingMultiplier == mult
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxHeight()
                                    .clip(CircleShape)
                                    .background(if (selected) colors.cardBackground else Color.Transparent)
                                    .clickable { servingMultiplier = mult }
                                    .run {
                                        if (selected) {
                                            border(1.dp, colors.cardBorder, CircleShape)
                                                .shadow(2.dp, CircleShape, ambientColor = colors.shadowColor, spotColor = colors.shadowColor)
                                        } else this
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = label,
                                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = if (selected) colors.primaryText else colors.mutedText
                                )
                            }
                        }
                    }
                }

                // Items list section
                val response = remember(savedMeal.rawResponseJson) {
                    try {
                        json.decodeFromString(MealLogResponse.serializer(), savedMeal.rawResponseJson)
                    } catch (e: Exception) {
                        null
                    }
                }
                if (response != null && response.items.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            "Items",
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.primaryText
                        )
                        Column(
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(16.dp))
                                .background(colors.insetBackground)
                                .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                                .padding(14.dp)
                        ) {
                            response.items.forEachIndexed { index, item ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = item.name,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 15.sp,
                                            color = colors.primaryText
                                        )
                                        Text(
                                            text = item.quantity,
                                            fontSize = 12.sp,
                                            color = colors.mutedText
                                        )
                                    }
                                    val scaledItemCals = (item.calories * servingMultiplier).toInt()
                                    Text(
                                        text = "${NumberUtils.formatNumber(scaledItemCals)} cal",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 15.sp,
                                        color = colors.primaryGreen
                                    )
                                }
                                if (index < response.items.size - 1) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(1.dp)
                                            .background(colors.cardBorder)
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Sticky Actions
                Button(
                    onClick = {
                        viewModel.logSavedMealAsIs(savedMeal, servingMultiplier)
                        selectedSavedMealForDialog = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                ) {
                    Text("Log", fontWeight = FontWeight.Bold, color = Color.White)
                }

                Button(
                    onClick = {
                        viewModel.prepareSavedMealForEditing(savedMeal)
                        selectedSavedMealForDialog = null
                        composerFocusRequester.requestFocus()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = colors.insetBackground),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                ) {
                    Text("Edit before logging", fontWeight = FontWeight.Bold, color = colors.primaryGreen)
                }
            }
        }

        // Rename Dialog (1:1 with iOS)
        if (isRenamingFav) {
            RenameFavoriteDialog(
                title = "Rename Favourite Meal",
                initialText = favRenameText,
                placeholder = "Name",
                onDismiss = { isRenamingFav = false },
                onSave = { newName ->
                    viewModel.renameFavoriteMeal(savedMeal.id, newName)
                    isRenamingFav = false
                    selectedSavedMealForDialog = null
                }
            )
        }

        // Delete Confirm Dialog (Modern Confirmation)
        if (showDeleteConfirm) {
            ModernConfirmationDialog(
                title = "Remove from Favorites?",
                message = "Are you sure you want to remove this meal from your favourites?",
                confirmText = "Remove",
                onConfirm = {
                    viewModel.deleteFavoriteMeal(savedMeal.id)
                    showDeleteConfirm = false
                    selectedSavedMealForDialog = null
                },
                onDismiss = { showDeleteConfirm = false }
            )
        }
    }

    // Rename / Remove prompt for recently logged meal bookmarking (1:1 with iOS)
    renameTargetMeal?.let { savedMeal ->
        if (isRenamingResultMeal) {
            RenameFavoriteDialog(
                title = "Rename Favourite Meal",
                initialText = renameTitleText,
                placeholder = "Name",
                onDismiss = {
                    renameTargetMeal = null
                    isRenamingResultMeal = false
                },
                onSave = { newName ->
                    viewModel.renameFavoriteMeal(savedMeal.id, newName)
                    renameTargetMeal = null
                    isRenamingResultMeal = false
                }
            )
        } else {
            ModernConfirmationDialog(
                title = "Remove Favourite Meal",
                message = "Are you sure you want to remove this meal from your favourites?",
                confirmText = "Remove",
                onConfirm = {
                    viewModel.deleteFavoriteMeal(savedMeal.id)
                    renameTargetMeal = null
                },
                onDismiss = { renameTargetMeal = null }
            )
        }
    }

    // See all favorites overlay sheet BottomSheet implementation
    if (showAllFavoritesSheet) {
        ModalBottomSheet(
            onDismissRequest = { showAllFavoritesSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = colors.background,
            dragHandle = { BottomSheetDefaults.DragHandle(color = colors.cardBorder) }
        ) {
            var searchText by remember { mutableStateOf("") }
            val filtered = savedMeals.filter {
                it.title.lowercase().contains(searchText.lowercase())
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
                    .padding(bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Spacer(modifier = Modifier.width(60.dp))
                    Text(
                        text = "Favourites",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(colors.cardBackground)
                            .border(1.dp, colors.cardBorder, CircleShape)
                            .clickable { showAllFavoritesSheet = false }
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                            .shadow(2.dp, CircleShape, ambientColor = colors.shadowColor, spotColor = colors.shadowColor),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "Close",
                            color = colors.primaryGreen,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                    }
                }

                // iOS Search Bar
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(38.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(colors.insetBackground)
                        .border(0.8.dp, colors.cardBorder.copy(alpha = 0.6f), RoundedCornerShape(10.dp))
                        .padding(horizontal = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Search",
                        tint = colors.mutedText,
                        modifier = Modifier.size(16.dp)
                    )
                    Box(modifier = Modifier.weight(1f)) {
                        if (searchText.isEmpty()) {
                            Text(
                                text = "Search favorites",
                                color = colors.quietText,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        BasicTextField(
                            value = searchText,
                            onValueChange = { searchText = it },
                            singleLine = true,
                            textStyle = MaterialTheme.typography.bodyMedium.copy(color = colors.primaryText),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    if (searchText.isNotEmpty()) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Clear",
                            tint = colors.mutedText,
                            modifier = Modifier
                                .size(16.dp)
                                .clickable { searchText = "" }
                        )
                    }
                }

                // List of items
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 400.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (filtered.isEmpty()) {
                        Text(
                            "No favourites found.",
                            color = colors.mutedText,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 24.dp),
                            textAlign = TextAlign.Center,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    } else {
                        filtered.forEach { meal ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(colors.cardBackground)
                                    .border(0.8.dp, colors.cardBorder.copy(alpha = 0.6f), RoundedCornerShape(12.dp))
                                    .clickable {
                                        showAllFavoritesSheet = false
                                        selectedSavedMealForDialog = meal
                                    }
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
                                        Icons.Default.Bookmark,
                                        contentDescription = null,
                                        tint = colors.primaryGreen,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Column {
                                        Text(
                                            meal.title,
                                            fontWeight = FontWeight.Bold,
                                            color = colors.primaryText
                                        )
                                        Text(
                                            meal.mealType.replaceFirstChar { it.uppercase() },
                                            style = MaterialTheme.typography.bodySmall,
                                            color = colors.mutedText
                                        )
                                    }
                                }
                                Text(
                                    "${meal.totalCalories.toInt()} cal",
                                    fontWeight = FontWeight.Bold,
                                    color = colors.primaryGreen
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Feedback Dialog overlay
    if (showFeedbackDialog) {
        FeedbackDialog(onDismiss = { showFeedbackDialog = false })
    }

    // Auth Dialog overlay
    if (showAuthDialog) {
        AuthDialog(
            onDismiss = { showAuthDialog = false },
            onAuthSuccess = {
                showAuthDialog = false
                viewModel.refreshAuth()
            }
        )
    }

    if (showCustomDatePicker) {
        CalendarBottomSheet(
            initialDate = uiState.selectedDate,
            onDateSelected = { viewModel.setSelectedDate(it) },
            onDismiss = { showCustomDatePicker = false }
        )
    }
}


@Composable
private fun MacroIndicatorBlock(label: String, value: String, barColor: Color) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(barColor.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .background(barColor, CircleShape)
        )
        Text(
            "$value $label",
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = colors.primaryText,
            maxLines = 1,
            softWrap = false
        )
    }
}

private fun createTempImageUri(context: Context): Uri {
    val imagesDir = File(context.cacheDir, "images").apply {
        if (!exists()) mkdirs()
    }
    val imageFile = File(imagesDir, "meal_${System.currentTimeMillis()}.jpg")
    return FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        imageFile
    )
}
