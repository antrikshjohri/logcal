package com.serene.logcal.ui

import android.Manifest
import android.app.DatePickerDialog
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.speech.RecognizerIntent
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
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
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.serene.logcal.R
import com.serene.logcal.model.MealLogResponse
import com.serene.logcal.model.MealType
import com.serene.logcal.util.DebugLogger
import com.serene.logcal.viewmodel.LogViewModel
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.animateLottieCompositionAsState
import com.airbnb.lottie.compose.rememberLottieComposition
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.delay

/** Shown next to the spinner while `logMeal` is in flight (single line; low latency). */
private const val LOG_MEAL_LOADING_LABEL = "Analyzing your meal…"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogMealScreen(viewModel: LogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var expanded by remember { mutableStateOf(false) }
    var lastErrorShown: String? by remember { mutableStateOf(null) }
    val density = LocalDensity.current
    var mealTypeButtonWidth by remember { mutableStateOf(0.dp) }
    var pendingCameraUri by remember { mutableStateOf<Uri?>(null) }
    var showConfetti by remember { mutableStateOf(false) }
    var wasLoading by remember { mutableStateOf(false) }

    val confettiComposition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.confetti_animation)
    )
    val confettiProgress by animateLottieCompositionAsState(
        composition = confettiComposition,
        isPlaying = showConfetti,
        iterations = 1
    )

    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && pendingCameraUri != null) {
            DebugLogger.d("LogMealScreen camera success uri=$pendingCameraUri")
            viewModel.setAttachedImageUri(pendingCameraUri.toString())
        } else {
            DebugLogger.w("LogMealScreen camera canceled or failed")
        }
    }

    val cameraPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        DebugLogger.d("LogMealScreen camera permission granted=$granted")
        if (!granted) {
            Toast.makeText(context, "Camera permission is required.", Toast.LENGTH_SHORT).show()
            return@rememberLauncherForActivityResult
        }
        val uri = createTempImageUri(context)
        pendingCameraUri = uri
        cameraLauncher.launch(uri)
    }

    val galleryLauncher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            DebugLogger.d("LogMealScreen gallery image selected uri=$uri")
            viewModel.setAttachedImageUri(uri.toString())
        } else {
            DebugLogger.w("LogMealScreen gallery selection canceled")
        }
    }

    val speechLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val matches = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS).orEmpty()
        val top = matches.firstOrNull().orEmpty()
        DebugLogger.d("LogMealScreen speech resultCount=${matches.size} topLength=${top.length}")
        if (top.isNotBlank()) {
            viewModel.appendFoodText(top)
        }
    }

    val micPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        DebugLogger.d("LogMealScreen mic permission granted=$granted")
        if (!granted) {
            Toast.makeText(context, "Microphone permission is required.", Toast.LENGTH_SHORT).show()
            return@rememberLauncherForActivityResult
        }
        launchSpeechInput(context, speechLauncher::launch)
    }

    LaunchedEffect(uiState.errorMessage) {
        val msg = uiState.errorMessage
        if (msg != null && msg != lastErrorShown) {
            lastErrorShown = msg
            Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
        }
    }

    LaunchedEffect(uiState.isLoading, uiState.latestResult) {
        if (uiState.isLoading) {
            wasLoading = true
            return@LaunchedEffect
        }
        if (wasLoading && uiState.latestResult != null) {
            DebugLogger.d("LogMealScreen playing confetti animation")
            showConfetti = true
            delay(1800)
            showConfetti = false
            wasLoading = false
        } else if (!uiState.isLoading) {
            wasLoading = false
        }
    }

    LaunchedEffect(uiState.isLoading) {
        if (uiState.isLoading) {
            DebugLogger.d("LogMealScreen loading UI label=$LOG_MEAL_LOADING_LABEL")
        }
    }

    val displayFormatter = remember { DateTimeFormatter.ofPattern("dd MMM yyyy") }

    Scaffold(containerColor = Color(0xFFF2F2F6)) { innerPadding ->
        Box(
            modifier = Modifier
                .padding(innerPadding)
                .background(Color(0xFFF2F2F6))
                .fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
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

                    uiState.attachedImageUri?.let { imageUri ->
                        Box(modifier = Modifier.size(92.dp)) {
                            AsyncImage(
                                model = imageUri,
                                contentDescription = "Attached meal image",
                                modifier = Modifier
                                    .size(88.dp)
                                    .background(Color(0xFFE9E9EE), RoundedCornerShape(12.dp))
                            )
                            Box(
                                modifier = Modifier
                                    .align(Alignment.TopEnd)
                                    .offset(x = 4.dp, y = (-4).dp)
                                    .size(28.dp)
                                    .background(Color.White, CircleShape)
                                    .border(1.dp, Color(0xFFCCCCD3), CircleShape)
                                    .clickable {
                                        DebugLogger.d("LogMealScreen attached image removed")
                                        viewModel.clearAttachedImage()
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Remove attached image",
                                    tint = Color(0xFF4A4A4A),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(155.dp)
                            .background(Color.White, RoundedCornerShape(12.dp))
                            .border(1.dp, Color(0xFFDADAE0), RoundedCornerShape(12.dp))
                            .padding(14.dp)
                    ) {
                        BasicTextField(
                            value = uiState.foodText,
                            onValueChange = viewModel::onFoodTextChanged,
                            modifier = Modifier.fillMaxWidth().height(98.dp),
                            textStyle = MaterialTheme.typography.bodyLarge.copy(color = Color(0xFF202020))
                        )
                        if (uiState.foodText.isBlank()) {
                            Text("Speak naturally about your meal...", color = Color(0xFF9A9AA1), style = MaterialTheme.typography.bodyLarge)
                        }
                        Row(
                            modifier = Modifier.align(Alignment.BottomEnd),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            LogIconButton(Icons.Default.CameraAlt) {
                                val hasCameraPermission = ContextCompat.checkSelfPermission(
                                    context,
                                    Manifest.permission.CAMERA
                                ) == PackageManager.PERMISSION_GRANTED
                                if (hasCameraPermission) {
                                    val uri = createTempImageUri(context)
                                    pendingCameraUri = uri
                                    DebugLogger.d("LogMealScreen opening camera uri=$uri")
                                    cameraLauncher.launch(uri)
                                } else {
                                    DebugLogger.d("LogMealScreen requesting camera permission")
                                    cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                                }
                            }
                            LogIconButton(Icons.Default.Image) {
                                DebugLogger.d("LogMealScreen opening gallery picker")
                                galleryLauncher.launch(
                                    PickVisualMediaRequest(
                                        mediaType = ActivityResultContracts.PickVisualMedia.ImageOnly
                                    )
                                )
                            }
                            LogIconButton(Icons.Default.Mic) {
                                val hasMicPermission = ContextCompat.checkSelfPermission(
                                    context,
                                    Manifest.permission.RECORD_AUDIO
                                ) == PackageManager.PERMISSION_GRANTED
                                if (hasMicPermission) {
                                    DebugLogger.d("LogMealScreen opening speech recognizer")
                                    launchSpeechInput(context, speechLauncher::launch)
                                } else {
                                    DebugLogger.d("LogMealScreen requesting microphone permission")
                                    micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                }
                            }
                        }
                    }

                    val canSubmitMeal =
                        (uiState.foodText.trim().isNotEmpty() || !uiState.attachedImageUri.isNullOrBlank()) && !uiState.isLoading
                    Button(
                        onClick = { viewModel.logMeal() },
                        enabled = canSubmitMeal,
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (uiState.foodText.trim().isNotEmpty() || !uiState.attachedImageUri.isNullOrBlank()) Color(0xFF168CED) else Color(0xFF9A9AA1),
                            contentColor = Color.White
                        ),
                        modifier = Modifier.fillMaxWidth().height(58.dp)
                    ) {
                        if (uiState.isLoading) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(18.dp),
                                    color = Color.White,
                                    strokeWidth = 2.dp
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = LOG_MEAL_LOADING_LABEL,
                                    style = MaterialTheme.typography.titleSmall,
                                    color = Color.White,
                                    maxLines = 1
                                )
                            }
                        } else {
                            Text("Log Meal", fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleMedium)
                        }
                    }

                    uiState.latestResult?.let { ResultCard(it) }
                }
            }

            if (showConfetti) {
                LottieAnimation(
                    composition = confettiComposition,
                    progress = { confettiProgress },
                    modifier = Modifier
                        .size(280.dp)
                        .align(Alignment.Center)
                )
            }
        }
    }
}

@Composable
private fun LogIconButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .background(Color(0xFFE5F4FF), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick),
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
                Text("Logged Successfully", fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                Box(modifier = Modifier.background(Color(0xFFD9EBFF), RoundedCornerShape(8.dp)).padding(horizontal = 10.dp, vertical = 6.dp)) {
                    Text(
                        result.mealType.replaceFirstChar { it.uppercase() },
                        color = Color(0xFF285F93),
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }
            Text("Total Calories: ${result.totalCalories.toInt()}", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            if (result.protein != null && result.carbs != null && result.fat != null) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    MacroBlock("Protein", "${result.protein!!.toInt()}g")
                    MacroBlock("Carbs", "${result.carbs!!.toInt()}g")
                    MacroBlock("Fat", "${result.fat!!.toInt()}g")
                }
            }

            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(Color(0xFFE6E6EA)))

            if (result.items.isNotEmpty()) {
                Text("Items:", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                result.items.forEach { item ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(item.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Medium)
                            Text(item.quantity, color = Color(0xFF7E7E86), style = MaterialTheme.typography.bodyMedium)
                            if (!item.assumptions.isNullOrBlank()) {
                                Text(
                                    "Assumptions: ${item.assumptions}",
                                    color = Color(0xFF7E7E86),
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                        Text("${item.calories.toInt()} cal", color = Color(0xFF7E7E86), style = MaterialTheme.typography.titleMedium)
                    }
                }
            }
        }
    }
}

@Composable
private fun RowScope.MacroBlock(label: String, value: String) {
    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.bodySmall, color = Color(0xFF8A8A91))
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

private fun launchSpeechInput(
    context: Context,
    launch: (Intent) -> Unit
) {
    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
        putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak about your meal")
    }
    if (intent.resolveActivity(context.packageManager) == null) {
        DebugLogger.e("LogMealScreen no speech recognition activity found")
        Toast.makeText(context, "Speech recognition is unavailable on this device.", Toast.LENGTH_SHORT).show()
        return
    }
    launch(intent)
}

