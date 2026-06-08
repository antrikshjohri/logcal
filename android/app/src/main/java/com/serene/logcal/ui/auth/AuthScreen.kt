package com.serene.logcal.ui.auth

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val demoMeals = listOf(
    Pair("One bowl of grilled chicken salad and garlic bread", 520),
    Pair("A large burrito bowl with guacamole", 620),
    Pair("Butter chicken with 1 naan and rice", 680),
    Pair("Salmon teriyaki and rice", 580),
    Pair("One bowl of caesar salad with grilled chicken", 450),
    Pair("Two slices of margherita pizza", 290),
    Pair("One plate of dal makhani with roti", 480),
    Pair("Two slices of avocado toast with poached eggs", 420),
    Pair("1 bowl Fish and chips", 650),
    Pair("One plate of pad thai with vegetables", 520)
)

@Composable
fun AuthScreen(onAuthSuccess: () -> Unit) {
    val context = LocalContext.current
    val auth = remember { FirebaseAuth.getInstance() }
    var isLoading by remember { mutableStateOf(false) }

    // Animation states
    var currentMealIndex by remember { mutableStateOf(0) }
    val mealTextAlpha = remember { Animatable(0f) }
    val arrowAlpha = remember { Animatable(0f) }
    val caloriesAlpha = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        while (true) {
            // Reset state
            mealTextAlpha.snapTo(0f)
            arrowAlpha.snapTo(0f)
            caloriesAlpha.snapTo(0f)

            // Phase 1: Meal text fades in
            mealTextAlpha.animateTo(1f, animationSpec = tween(400))
            delay(500)

            // Phase 2: Arrow fades in
            arrowAlpha.animateTo(1f, animationSpec = tween(400))
            delay(500)

            // Phase 3: Calories card fades in
            caloriesAlpha.animateTo(1f, animationSpec = tween(400))
            delay(1500)

            // Phase 4: All fade out together
            launch { mealTextAlpha.animateTo(0f, animationSpec = tween(400)) }
            launch { arrowAlpha.animateTo(0f, animationSpec = tween(400)) }
            launch { caloriesAlpha.animateTo(0f, animationSpec = tween(400)) }
            delay(500)

            // Next meal
            currentMealIndex = (currentMealIndex + 1) % demoMeals.size
        }
    }

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        isLoading = false
        val resultCode = result.resultCode
        val data = result.data
        DebugLogger.d("DEBUG: Google sign-in launcher returned. resultCode=$resultCode, data=$data")

        if (resultCode == Activity.RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            try {
                val account = task.getResult(ApiException::class.java)!!
                val idToken = account.idToken
                if (idToken.isNullOrBlank()) {
                    DebugLogger.e("DEBUG: Google sign-in failed: idToken is null or empty")
                    Toast.makeText(context, "Sign-in error: Missing ID token", Toast.LENGTH_LONG).show()
                    return@rememberLauncherForActivityResult
                }
                val credential = GoogleAuthProvider.getCredential(idToken, null)
                isLoading = true
                auth.signInWithCredential(credential)
                    .addOnSuccessListener { authResult ->
                        DebugLogger.d("DEBUG: Google sign-in successful: ${authResult.user?.email}")
                        onAuthSuccess()
                    }
                    .addOnFailureListener { e ->
                        DebugLogger.e("DEBUG: Google sign-in failed", e)
                        isLoading = false
                        Toast.makeText(context, "Sign-in failed: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                    }
            } catch (e: ApiException) {
                DebugLogger.e("DEBUG: Google sign-in ApiException status code: ${e.statusCode}", e)
                Toast.makeText(context, "Sign-in error: ${e.localizedMessage} (Status: ${e.statusCode})", Toast.LENGTH_LONG).show()
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Google sign-in exception", e)
                Toast.makeText(context, "Sign-in error: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            }
        } else {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            val exception = task.exception
            val statusCode = (exception as? ApiException)?.statusCode
            DebugLogger.w("DEBUG: Google sign-in launcher resultCode is not RESULT_OK. resultCode=$resultCode, statusCode=$statusCode")

            val errorMsg = when (statusCode) {
                10 -> "Developer Error (10): Ensure debug SHA-1 is registered in Firebase console."
                7 -> "Network Error (7): Please check your connection."
                12500 -> "Sign-in Failed (12500): Check Google Play Services config."
                12501 -> "Sign-in Cancelled (12501)."
                else -> exception?.localizedMessage ?: "Sign-in failed or cancelled. Result code: $resultCode"
            }
            Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show()
        }
    }

    val colors = LogCalTheme.colors

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))

            // Welcome headings
            Text(
                text = "Welcome to LogCal",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Speak to track calories",
                style = MaterialTheme.typography.titleMedium,
                color = colors.mutedText,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(30.dp))

            // Visual Demo Section
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.weight(1f)
            ) {
                // Mic Circle Icon
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .background(colors.softAccentBackground, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Mic,
                        contentDescription = "Microphone",
                        tint = colors.primaryGreen,
                        modifier = Modifier.size(44.dp)
                    )
                }

                // Meal text container (fixed height to prevent layout shifts)
                Box(
                    modifier = Modifier
                        .height(60.dp)
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "\"${demoMeals[currentMealIndex].first}\"",
                        style = MaterialTheme.typography.bodyLarge.copy(fontSize = 17.sp),
                        fontStyle = FontStyle.Italic,
                        color = colors.primaryText,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.alpha(mealTextAlpha.value)
                    )
                }

                // Arrow container
                Box(
                    modifier = Modifier.height(30.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowDownward,
                        contentDescription = "Inferred to",
                        tint = colors.mutedText,
                        modifier = Modifier
                            .size(24.dp)
                            .alpha(arrowAlpha.value)
                    )
                }

                // Calories Card
                Box(
                    modifier = Modifier
                        .height(100.dp)
                        .width(220.dp)
                        .alpha(caloriesAlpha.value)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(colors.cardBackground, RoundedCornerShape(16.dp))
                            .border(1.dp, colors.cardBorder, RoundedCornerShape(16.dp))
                            .padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = "Logged",
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.mutedText
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${demoMeals[currentMealIndex].second} cal",
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = colors.primaryText
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(30.dp))

            // Auth actions
            Text(
                text = "Sign in to sync your data",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.mutedText,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            if (isLoading) {
                CircularProgressIndicator(color = colors.primaryGreen)
                Spacer(modifier = Modifier.height(20.dp))
            } else {
                // Google sign-in button
                Button(
                    onClick = {
                        isLoading = true
                        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestIdToken("1023141890322-i5ob5lajc097qdfs3fg22ebc6bapfboe.apps.googleusercontent.com")
                            .requestEmail()
                            .build()
                        val googleSignInClient = GoogleSignIn.getClient(context, gso)
                        googleSignInClient.signOut().addOnCompleteListener {
                            val intent = googleSignInClient.signInIntent
                            googleSignInLauncher.launch(intent)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colors.primaryGreen,
                        contentColor = Color.White
                    )
                ) {
                    Text(
                        text = "Sign in with Google",
                        fontWeight = FontWeight.SemiBold,
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Guest option
                Text(
                    text = "Continue as Guest",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = colors.primaryGreen,
                    modifier = Modifier
                        .clickable {
                            isLoading = true
                            auth
                                .signInAnonymously()
                                .addOnSuccessListener {
                                    DebugLogger.d("DEBUG: Anonymous guest sign-in successful")
                                    onAuthSuccess()
                                }
                                .addOnFailureListener { e ->
                                    isLoading = false
                                    Toast.makeText(context, "Guest setup failed: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                                }
                        }
                        .padding(vertical = 8.dp)
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Legal notice
            Row(
                modifier = Modifier.padding(bottom = 20.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "By continuing, you agree to our ",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.mutedText
                )
                Text(
                    text = "Privacy Policy",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.mutedText,
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier.clickable {
                        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://sites.google.com/view/privacypolicylogcalai/home"))
                        context.startActivity(browserIntent)
                    }
                )
            }
        }
    }
}
