package com.serene.logcal.ui

import com.serene.logcal.ui.profile.FeedbackDialog
import android.Manifest
import android.app.DatePickerDialog
import android.content.Context
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
import androidx.compose.material.icons.filled.ArrowUpward
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
import com.serene.logcal.data.local.SavedMealEntity
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.viewmodel.LogViewModel
import kotlinx.coroutines.delay
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

private const val LOG_MEAL_LOADING_LABEL = "Analyzing your meal…"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogMealScreen(viewModel: LogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val savedMeals by viewModel.savedMeals.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    val composerFocusRequester = remember { FocusRequester() }

    var dropdownExpanded by remember { mutableStateOf(false) }
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

    val confettiComposition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.confetti_animation)
    )
    val confettiProgress by animateLottieCompositionAsState(
        composition = confettiComposition,
        isPlaying = showConfetti,
        iterations = 1
    )

    // Launchers
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && pendingCameraUri != null) {
            viewModel.setAttachedImageUri(pendingCameraUri.toString())
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
            viewModel.setAttachedImageUri(uri.toString())
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
    val isAnonymous = FirebaseAuth.getInstance().currentUser?.isAnonymous == true

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
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Log Calories",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryText
                )

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
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Date selector
                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                "DATE",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = colors.mutedText
                            )
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(44.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(colors.cardBackground)
                                    .border(1.dp, colors.cardBorder, RoundedCornerShape(10.dp))
                                    .padding(horizontal = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                IconButton(
                                    onClick = { viewModel.setSelectedDate(uiState.selectedDate.minusDays(1)) }
                                ) {
                                    Icon(
                                        Icons.Default.ChevronLeft,
                                        contentDescription = null,
                                        tint = colors.mutedText,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                Row(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            val d = uiState.selectedDate
                                            DatePickerDialog(
                                                context,
                                                { _, y, m, day -> viewModel.setSelectedDate(LocalDate.of(y, m + 1, day)) },
                                                d.year,
                                                d.monthValue - 1,
                                                d.dayOfMonth
                                            ).show()
                                        },
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = uiState.selectedDate.format(dateDisplayFormatter),
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold,
                                        color = colors.primaryText
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Icon(
                                        Icons.Default.CalendarMonth,
                                        contentDescription = null,
                                        tint = colors.primaryGreen,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                                IconButton(
                                    onClick = { viewModel.setSelectedDate(uiState.selectedDate.plusDays(1)) }
                                ) {
                                    Icon(
                                        Icons.Default.ChevronRight,
                                        contentDescription = null,
                                        tint = colors.mutedText,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }

                        // Meal Type selector
                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                "MEAL TYPE",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = colors.mutedText
                            )
                            Box {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(44.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(colors.cardBackground)
                                        .border(1.dp, colors.cardBorder, RoundedCornerShape(10.dp))
                                        .onGloballyPositioned { coordinates ->
                                            mealTypeButtonWidth = with(density) { coordinates.size.width.toDp() }
                                        }
                                        .padding(horizontal = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    IconButton(
                                        onClick = {
                                            val types = MealType.entries
                                            val idx = (types.indexOf(uiState.selectedMealType) - 1 + types.size) % types.size
                                            viewModel.setMealType(types[idx])
                                        }
                                    ) {
                                        Icon(
                                            Icons.Default.ChevronLeft,
                                            contentDescription = null,
                                            tint = colors.mutedText,
                                            modifier = Modifier.size(20.dp)
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
                                            Icons.Default.KeyboardArrowDown,
                                            contentDescription = null,
                                            tint = colors.primaryGreen,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                    IconButton(
                                        onClick = {
                                            val types = MealType.entries
                                            val idx = (types.indexOf(uiState.selectedMealType) + 1) % types.size
                                            viewModel.setMealType(types[idx])
                                        }
                                    ) {
                                        Icon(
                                            Icons.Default.ChevronRight,
                                            contentDescription = null,
                                            tint = colors.mutedText,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }

                                DropdownMenu(
                                    expanded = dropdownExpanded,
                                    onDismissRequest = { dropdownExpanded = false },
                                    modifier = Modifier
                                        .width(mealTypeButtonWidth)
                                        .background(colors.cardBackground)
                                ) {
                                    MealType.entries.forEach { mt ->
                                        val isSelected = uiState.selectedMealType == mt
                                        DropdownMenuItem(
                                            text = {
                                                Text(
                                                    text = mt.displayName,
                                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                                    color = if (isSelected) colors.primaryGreen else colors.primaryText
                                                )
                                            },
                                            onClick = {
                                                dropdownExpanded = false
                                                viewModel.setMealType(mt)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Favourites horizontal section
                    if (savedMeals.isNotEmpty()) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "Favourites",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = colors.mutedText
                                )
                                Text(
                                    "See all",
                                    color = colors.primaryGreen,
                                    style = MaterialTheme.typography.bodyMedium,
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
                                            .clip(RoundedCornerShape(19.dp))
                                            .background(colors.cardBackground)
                                            .border(1.dp, colors.cardBorder, RoundedCornerShape(19.dp))
                                            .clickable { selectedSavedMealForDialog = fav }
                                            .padding(horizontal = 14.dp, vertical = 8.dp),
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
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.SemiBold,
                                            color = colors.primaryText
                                        )
                                        Text(
                                            text = "${fav.totalCalories.toInt()} cal",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = colors.mutedText
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Composer view
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            "What did you eat?",
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.mutedText
                        )

                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(16.dp))
                                .background(colors.cardBackground)
                                .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                                .padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            // Attached image thumbnail
                            uiState.attachedImageUri?.let { imageUri ->
                                Box(modifier = Modifier.size(80.dp)) {
                                    AsyncImage(
                                        model = imageUri,
                                        contentDescription = null,
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(colors.insetBackground)
                                    )
                                    Box(
                                        modifier = Modifier
                                            .align(Alignment.TopEnd)
                                            .offset(x = 6.dp, y = (-6).dp)
                                            .size(24.dp)
                                            .background(Color.White, CircleShape)
                                            .border(1.dp, Color(0xFFCCCCCC), CircleShape)
                                            .clickable { viewModel.clearAttachedImage() },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Default.Close,
                                            contentDescription = null,
                                            tint = Color.DarkGray,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }
                            }

                            // Text area
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(100.dp)
                            ) {
                                if (uiState.foodText.isBlank() && !uiState.isListening && !uiState.isTranscribingSpeech) {
                                    Text(
                                        "Write or speak naturally about what you ate...",
                                        color = colors.quietText,
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }
                                BasicTextField(
                                    value = uiState.foodText,
                                    onValueChange = viewModel::onFoodTextChanged,
                                    enabled = !uiState.isListening && !uiState.isTranscribingSpeech,
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .focusRequester(composerFocusRequester),
                                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = colors.primaryText)
                                )
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(1.dp)
                                    .background(colors.cardBorder)
                            )

                            // Action panel (mic, camera, gallery or dictation waveform HUD)
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                if (uiState.isListening) {
                                    // Recording speech Waveform HUD
                                    IconButton(
                                        onClick = { viewModel.cancelSpeechRecognition() },
                                        modifier = Modifier
                                            .size(36.dp)
                                            .background(colors.dangerRed, CircleShape)
                                    ) {
                                        Icon(
                                            Icons.Default.Close,
                                            contentDescription = "Cancel",
                                            tint = Color.White,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(12.dp))

                                    // Graphical Waveform
                                    Row(
                                        modifier = Modifier
                                            .weight(1f)
                                            .height(36.dp)
                                            .padding(horizontal = 8.dp),
                                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        uiState.waveformSamples.forEach { sample ->
                                            val barHeight = (32.dp * sample).coerceAtLeast(4.dp)
                                            Box(
                                                modifier = Modifier
                                                    .width(3.dp)
                                                    .height(barHeight)
                                                    .clip(RoundedCornerShape(1.dp))
                                                    .background(colors.primaryGreen)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.width(12.dp))

                                    // Finish button (tick)
                                    IconButton(
                                        onClick = { viewModel.stopSpeechRecognition() },
                                        modifier = Modifier
                                            .size(36.dp)
                                            .background(colors.primaryGreen, CircleShape)
                                    ) {
                                        Icon(
                                            Icons.Default.Check,
                                            contentDescription = "Done",
                                            tint = Color.White,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(8.dp))

                                    // Immediate Log button (up arrow)
                                    IconButton(
                                        onClick = {
                                            viewModel.stopSpeechRecognition()
                                            viewModel.logMeal()
                                        },
                                        modifier = Modifier
                                            .size(36.dp)
                                            .background(colors.warningAmber, CircleShape)
                                    ) {
                                        Icon(
                                            Icons.Default.ArrowUpward,
                                            contentDescription = "Log",
                                            tint = Color.White,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                } else {
                                    // Regular modes
                                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                        IconButton(
                                            onClick = {
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
                                            modifier = Modifier
                                                .size(36.dp)
                                                .background(colors.softAccentBackground, CircleShape)
                                        ) {
                                            Icon(
                                                Icons.Default.CameraAlt,
                                                contentDescription = "Camera",
                                                tint = colors.primaryGreen,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }

                                        IconButton(
                                            onClick = {
                                                galleryLauncher.launch(
                                                    PickVisualMediaRequest(
                                                        mediaType = ActivityResultContracts.PickVisualMedia.ImageOnly
                                                    )
                                                )
                                            },
                                            modifier = Modifier
                                                .size(36.dp)
                                                .background(colors.softAccentBackground, CircleShape)
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

                                    if (uiState.isTranscribingSpeech) {
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
                                    IconButton(
                                        onClick = {
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
                                        modifier = Modifier
                                            .size(44.dp)
                                            .background(colors.warningAmber, CircleShape),
                                        enabled = !uiState.isTranscribingSpeech
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
                    }

                    // Log Meal Submit Button
                    val canSubmit = (uiState.foodText.trim().isNotEmpty() || uiState.attachedImageUri != null) && !uiState.isLoading
                    Button(
                        onClick = {
                            focusManager.clearFocus()
                            viewModel.logMeal()
                        },
                        enabled = canSubmit,
                        shape = RoundedCornerShape(25.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (canSubmit) colors.primaryGreen else colors.primaryGreen.copy(alpha = 0.12f),
                            contentColor = if (canSubmit) Color.White else colors.primaryGreen.copy(alpha = 0.4f)
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                    ) {
                        if (uiState.isLoading) {
                            Row(
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(18.dp),
                                    color = Color.White,
                                    strokeWidth = 2.dp
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(LOG_MEAL_LOADING_LABEL, color = Color.White)
                            }
                        } else {
                            Text("Log Meal", fontWeight = FontWeight.Bold)
                        }
                    }

                    // Result card section
                    uiState.latestResult?.let { result ->
                        var isSaved by remember(savedMeals, uiState.lastLoggedMealId) {
                            mutableStateOf(savedMeals.any { it.sourceMealId == uiState.lastLoggedMealId })
                        }
                        var quickEditVal by remember { mutableStateOf("") }

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
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Text(
                                            "Logged Successfully",
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.titleMedium,
                                            color = colors.primaryText
                                        )
                                        Box(
                                            modifier = Modifier
                                                .background(
                                                    colors.softAccentBackground,
                                                    RoundedCornerShape(6.dp)
                                                )
                                                .padding(horizontal = 8.dp, vertical = 4.dp)
                                        ) {
                                            Text(
                                                result.mealType.replaceFirstChar { it.uppercase() },
                                                color = colors.primaryGreen,
                                                style = MaterialTheme.typography.labelSmall,
                                                fontWeight = FontWeight.Bold
                                            )
                                        }
                                    }

                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        IconButton(
                                            onClick = {
                                                val existing = savedMeals.firstOrNull { it.sourceMealId == uiState.lastLoggedMealId }
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
                                            }
                                        ) {
                                            Icon(
                                                imageVector = if (isSaved) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                                                contentDescription = "Bookmark favourite",
                                                tint = colors.primaryGreen
                                            )
                                        }

                                        IconButton(
                                            onClick = { viewModel.clearLatestResult() }
                                        ) {
                                            Icon(
                                                Icons.Default.Close,
                                                contentDescription = "Dismiss summary",
                                                tint = colors.mutedText
                                            )
                                        }
                                    }
                                }

                                if (isAnonymous) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(colors.warningAmber.copy(alpha = 0.08f))
                                            .border(1.dp, colors.warningAmber.copy(alpha = 0.2f), RoundedCornerShape(10.dp))
                                            .padding(10.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.Warning,
                                            contentDescription = null,
                                            tint = colors.warningAmber,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                "Guest Session",
                                                fontWeight = FontWeight.Bold,
                                                style = MaterialTheme.typography.bodySmall,
                                                color = colors.primaryText
                                            )
                                            Text(
                                                "Sign in to back up your meals to the cloud.",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = colors.mutedText
                                            )
                                        }
                                    }
                                }

                                Text(
                                    "${result.totalCalories.toInt()} cal",
                                    style = MaterialTheme.typography.displaySmall,
                                    fontWeight = FontWeight.Black,
                                    color = colors.primaryText
                                )

                                // Macros chips
                                if (result.protein != null && result.carbs != null && result.fat != null) {
                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        MacroIndicatorBlock("Protein", "${result.protein.toInt()}g", colors.protein)
                                        MacroIndicatorBlock("Carbs", "${result.carbs.toInt()}g", colors.carbs)
                                        MacroIndicatorBlock("Fat", "${result.fat.toInt()}g", colors.fat)
                                    }
                                }

                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(1.dp)
                                        .background(colors.cardBorder)
                                )

                                Text(
                                    "Items Breakdown",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = colors.mutedText
                                )

                                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    result.items.forEachIndexed { idx, item ->
                                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Text(
                                                    item.name,
                                                    fontWeight = FontWeight.Bold,
                                                    color = colors.primaryText
                                                )
                                                Text(
                                                    "${item.calories.toInt()} cal",
                                                    fontWeight = FontWeight.Bold,
                                                    color = colors.primaryGreen
                                                )
                                            }
                                            Text(
                                                item.quantity,
                                                style = MaterialTheme.typography.bodySmall,
                                                color = colors.mutedText
                                            )
                                            if (item.protein != null && item.carbs != null && item.fat != null) {
                                                Text(
                                                    "Protein: ${item.protein.toInt()}g · Carbs: ${item.carbs.toInt()}g · Fat: ${item.fat.toInt()}g",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = colors.quietText
                                                )
                                            }
                                            if (!item.assumptions.isNullOrBlank()) {
                                                Text(
                                                    "Assumptions: ${item.assumptions}",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = colors.quietText
                                                )
                                            }
                                        }
                                        if (idx < result.items.size - 1) {
                                            Box(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .height(1.dp)
                                                    .background(colors.cardBorder.copy(alpha = 0.5f))
                                                    .padding(vertical = 4.dp)
                                            )
                                        }
                                    }
                                }

                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(1.dp)
                                        .background(colors.cardBorder)
                                )

                                // Inline quick edit correction field
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedTextField(
                                        value = quickEditVal,
                                        onValueChange = { quickEditVal = it },
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
                                                if (quickEditVal.isNotBlank() && !uiState.isRefiningMeal) {
                                                    viewModel.quickRefineLoggedMeal(quickEditVal)
                                                    quickEditVal = ""
                                                }
                                            }
                                        )
                                    )
                                    IconButton(
                                        onClick = {
                                            if (quickEditVal.isNotBlank() && !uiState.isRefiningMeal) {
                                                viewModel.quickRefineLoggedMeal(quickEditVal)
                                                quickEditVal = ""
                                            }
                                        },
                                        enabled = !uiState.isRefiningMeal && quickEditVal.isNotBlank(),
                                        modifier = Modifier
                                            .size(44.dp)
                                            .background(colors.primaryGreen, CircleShape)
                                    ) {
                                        if (uiState.isRefiningMeal) {
                                            CircularProgressIndicator(
                                                modifier = Modifier.size(16.dp),
                                                color = Color.White,
                                                strokeWidth = 2.dp
                                            )
                                        } else {
                                            Icon(
                                                Icons.Default.Send,
                                                contentDescription = "Send refinement",
                                                tint = Color.White,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Send feedback link
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        Text(
                            "Send feedback",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium,
                            color = colors.mutedText,
                            modifier = Modifier
                                .clickable { showFeedbackDialog = true }
                                .padding(vertical = 4.dp)
                        )
                    }
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
    selectedSavedMealForDialog?.let { savedMeal ->
        var servingMultiplier by remember { mutableStateOf(1.0) }
        var isRenamingFav by remember { mutableStateOf(false) }
        var favRenameText by remember { mutableStateOf("") }
        var showDeleteConfirm by remember { mutableStateOf(false) }

        Dialog(onDismissRequest = { selectedSavedMealForDialog = null }) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = colors.cardBackground,
                border = BorderStroke(1.dp, colors.cardBorder),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
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
                            Spacer(modifier = Modifier.height(2.dp))
                            val scaledCals = (savedMeal.totalCalories * servingMultiplier).toInt()
                            Text(
                                "$scaledCals cal · ${savedMeal.mealType.replaceFirstChar { it.uppercase() }}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = colors.mutedText
                            )
                        }

                        IconButton(
                            onClick = { showDeleteConfirm = true }
                        ) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "Delete favorite",
                                tint = colors.dangerRed
                            )
                        }
                    }

                    // Serving selection buttons (0.5x, 1x, 1.5x, 2x)
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            "Serving size",
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.primaryText
                        )
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(38.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(colors.insetBackground)
                                .padding(2.dp)
                        ) {
                            listOf(0.5, 1.0, 1.5, 2.0).forEach { mult ->
                                val label = when (mult) {
                                    0.5 -> "0.5x"
                                    1.0 -> "1.0x"
                                    1.5 -> "1.5x"
                                    2.0 -> "2.0x"
                                    else -> "${mult}x"
                                }
                                val selected = servingMultiplier == mult
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxHeight()
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(if (selected) colors.cardBackground else Color.Transparent)
                                        .clickable { servingMultiplier = mult }
                                        .border(
                                            if (selected) BorderStroke(1.dp, colors.cardBorder) else BorderStroke(0.dp, Color.Transparent),
                                            RoundedCornerShape(6.dp)
                                        ),
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

                    Spacer(modifier = Modifier.height(4.dp))

                    // Buttons
                    Button(
                        onClick = {
                            viewModel.logSavedMealAsIs(savedMeal, servingMultiplier)
                            selectedSavedMealForDialog = null
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
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
                            .height(48.dp)
                    ) {
                        Text("Edit before logging", fontWeight = FontWeight.Bold, color = colors.primaryGreen)
                    }
                }
            }
        }

        // Rename Alert Dialog
        if (isRenamingFav) {
            AlertDialog(
                onDismissRequest = { isRenamingFav = false },
                title = { Text("Rename Favorite Meal") },
                text = {
                    OutlinedTextField(
                        value = favRenameText,
                        onValueChange = { favRenameText = it },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            if (favRenameText.isNotBlank()) {
                                viewModel.renameFavoriteMeal(savedMeal.id, favRenameText)
                            }
                            isRenamingFav = false
                            selectedSavedMealForDialog = null
                        }
                    ) { Text("Save", color = colors.primaryGreen) }
                },
                dismissButton = {
                    TextButton(onClick = { isRenamingFav = false }) { Text("Cancel") }
                }
            )
        }

        // Delete Confirm Dialog
        if (showDeleteConfirm) {
            AlertDialog(
                onDismissRequest = { showDeleteConfirm = false },
                title = { Text("Remove from Favorites?") },
                text = { Text("Are you sure you want to remove this meal from your favourites?") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            viewModel.deleteFavoriteMeal(savedMeal.id)
                            showDeleteConfirm = false
                            selectedSavedMealForDialog = null
                        }
                    ) { Text("Remove", color = colors.dangerRed) }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteConfirm = false }) { Text("Cancel") }
                }
            )
        }
    }

    // Rename prompt for recently logged meal bookmarking
    renameTargetMeal?.let { savedMeal ->
        AlertDialog(
            onDismissRequest = { renameTargetMeal = null },
            title = { Text(if (isRenamingResultMeal) "Rename Favourite Meal" else "Remove Favourite Meal") },
            text = {
                if (isRenamingResultMeal) {
                    OutlinedTextField(
                        value = renameTitleText,
                        onValueChange = { renameTitleText = it },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    Text("Are you sure you want to remove this meal from your favourites?")
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (isRenamingResultMeal) {
                            if (renameTitleText.isNotBlank()) {
                                viewModel.renameFavoriteMeal(savedMeal.id, renameTitleText)
                            }
                        } else {
                            viewModel.deleteFavoriteMeal(savedMeal.id)
                        }
                        renameTargetMeal = null
                        isRenamingResultMeal = false
                    }
                ) {
                    Text(
                        text = if (isRenamingResultMeal) "Save" else "Remove",
                        color = if (isRenamingResultMeal) colors.primaryGreen else colors.dangerRed
                    )
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        renameTargetMeal = null
                        isRenamingResultMeal = false
                    }
                ) { Text("Cancel") }
            }
        )
    }

    // See all favorites overlay sheet dialog
    if (showAllFavoritesSheet) {
        Dialog(onDismissRequest = { showAllFavoritesSheet = false }) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = colors.background,
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.75f)
            ) {
                var searchText by remember { mutableStateOf("") }
                val filtered = savedMeals.filter {
                    it.title.lowercase().contains(searchText.lowercase())
                }

                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "Favourites",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryText
                        )
                        IconButton(onClick = { showAllFavoritesSheet = false }) {
                            Icon(Icons.Default.Close, contentDescription = null, tint = colors.primaryText)
                        }
                    }

                    OutlinedTextField(
                        value = searchText,
                        onValueChange = { searchText = it },
                        placeholder = { Text("Search favourites...", color = colors.quietText) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = colors.primaryGreen,
                            unfocusedBorderColor = colors.cardBorder
                        )
                    )

                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        if (filtered.isEmpty()) {
                            Text(
                                "No favourites found.",
                                color = colors.mutedText,
                                modifier = Modifier.padding(top = 16.dp),
                                textAlign = TextAlign.Center
                            )
                        } else {
                            filtered.forEach { meal ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(colors.cardBackground)
                                        .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                                        .clickable {
                                            selectedSavedMealForDialog = meal
                                            showAllFavoritesSheet = false
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
    }

    // Feedback Dialog overlay
    if (showFeedbackDialog) {
        FeedbackDialog(onDismiss = { showFeedbackDialog = false })
    }
}

@Composable
private fun MacroIndicatorBlock(label: String, value: String, barColor: Color) {
    val colors = LogCalTheme.colors
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(barColor.copy(alpha = 0.12f))
            .padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .background(barColor, CircleShape)
        )
        Text(
            "$value $label",
            fontWeight = FontWeight.Bold,
            style = MaterialTheme.typography.bodySmall,
            color = colors.primaryText
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
