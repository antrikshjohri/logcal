package com.serene.logcal.ui.profile

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.ui.res.painterResource
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
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.LinkOff
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.serene.logcal.data.repository.AppGraph
import com.serene.logcal.service.FirestoreService
import com.serene.logcal.service.AnalyticsService
import com.serene.logcal.ui.theme.LogCalTheme
import com.serene.logcal.util.DebugLogger
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.net.URLEncoder
import java.util.Date
import java.util.Locale

@Composable
fun WhatsAppLinkScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val firestoreService = remember { FirestoreService() }
    val colors = LogCalTheme.colors

    var linkageCode by remember { mutableStateOf("") }
    var linkageExpiryMillis by remember { mutableLongStateOf(0L) }
    var linkedPhoneNumber by remember { mutableStateOf<String?>(null) }
    
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    var secondsRemaining by remember { mutableLongStateOf(0L) }

    fun loadStatus() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                val info = firestoreService.fetchWhatsAppLinkageInfo()
                linkedPhoneNumber = info.phoneNumber
                
                if (info.linkageExpiryMillis != null && info.linkageExpiryMillis > System.currentTimeMillis()) {
                    linkageCode = info.linkageCode ?: ""
                    linkageExpiryMillis = info.linkageExpiryMillis
                    secondsRemaining = (info.linkageExpiryMillis - System.currentTimeMillis()) / 1000L
                } else {
                    linkageCode = ""
                    linkageExpiryMillis = 0L
                    secondsRemaining = 0L
                }
            } catch (e: Exception) {
                DebugLogger.e("DEBUG: Failed to load WhatsApp link status", e)
                errorMessage = "Failed to load status: ${e.localizedMessage}"
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(Unit) {
        loadStatus()
    }

    // Countdown Timer logic
    LaunchedEffect(secondsRemaining) {
        if (secondsRemaining > 0) {
            delay(1000L)
            secondsRemaining -= 1
            if (secondsRemaining <= 0) {
                linkageCode = ""
                linkageExpiryMillis = 0L
            }
        }
    }

    fun formattedTime(secs: Long): String {
        if (secs <= 0) return "Expired"
        val m = secs / 60
        val s = secs % 60
        return String.format(Locale.US, "%02d:%02d", m, s)
    }

    fun openWhatsApp(code: String) {
        val botNumber = "919319929923"
        val msg = "Please link my LogCal account with code: $code"
        try {
            val encodedMsg = URLEncoder.encode(msg, "UTF-8")
            val url = "https://wa.me/$botNumber?text=$encodedMsg"
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)
            AnalyticsService.trackWhatsAppOpened()
        } catch (e: Exception) {
            DebugLogger.e("DEBUG: Failed to launch WhatsApp", e)
            Toast.makeText(context, "Could not open WhatsApp.", Toast.LENGTH_SHORT).show()
        }
    }

    fun linkFlow() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                val code = (1..6).map { chars.random() }.joinToString("")
                val expiry = System.currentTimeMillis() + (15 * 60 * 1000) // 15 mins
                
                firestoreService.saveWhatsAppLinkageCode(code, expiry)
                AnalyticsService.trackWhatsAppLinkingStarted()
                
                linkageCode = code
                linkageExpiryMillis = expiry
                secondsRemaining = 15 * 60L
                
                openWhatsApp(code)
            } catch (e: Exception) {
                errorMessage = "Failed to start linking: ${e.localizedMessage}"
            } finally {
                isLoading = false
            }
        }
    }

    fun unlinkFlow() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                firestoreService.unlinkWhatsApp()
                AnalyticsService.trackWhatsAppUnlinked()
                linkedPhoneNumber = null
                linkageCode = ""
                linkageExpiryMillis = 0L
                secondsRemaining = 0L
                Toast.makeText(context, "Account unlinked successfully", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                errorMessage = "Failed to unlink: ${e.localizedMessage}"
            } finally {
                isLoading = false
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
            IconButton(onClick = {
                AnalyticsService.trackWhatsAppCloseTapped()
                onBack()
            }) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = colors.primaryText)
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "WhatsApp Logging",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = colors.primaryText
            )
        }

        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = colors.primaryGreen)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                if (linkedPhoneNumber != null) {
                    // Linked View
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = colors.primaryGreen,
                        modifier = Modifier.size(64.dp)
                    )

                    Text(
                        "WhatsApp Linked!",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )

                    Text(
                        "Your LogCal account is successfully connected to WhatsApp.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.cardBackground, RoundedCornerShape(12.dp))
                            .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            painter = painterResource(id = com.serene.logcal.R.drawable.ic_whatsapp),
                            contentDescription = null,
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                        )
                        Column {
                            Text("Connected Number", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = colors.mutedText)
                            Text("+$linkedPhoneNumber", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = colors.primaryText)
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Button(
                        onClick = {
                            AnalyticsService.trackWhatsAppUnlinkTapped()
                            unlinkFlow()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                        shape = RoundedCornerShape(25.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = colors.dangerRed.copy(alpha = 0.1f),
                            contentColor = colors.dangerRed
                        ),
                        border = androidx.compose.foundation.BorderStroke(1.dp, colors.dangerRed.copy(alpha = 0.3f))
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.LinkOff, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Unlink Account", fontWeight = FontWeight.Bold)
                        }
                    }
                } else {
                    // Unlinked View
                    Image(
                        painter = painterResource(id = com.serene.logcal.R.drawable.ic_whatsapp),
                        contentDescription = "WhatsApp Link",
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                    )

                    Text(
                        "Log via WhatsApp",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = colors.primaryText
                    )

                    Text(
                        "Log your meals by texting our WhatsApp bot. We will automatically parse calories and macros using AI.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.mutedText,
                        textAlign = TextAlign.Center
                    )

                    // Mock Visual Guide
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.cardBackground, RoundedCornerShape(12.dp))
                            .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            "WHAT TO DO IN WHATSAPP",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold,
                            color = colors.mutedText
                        )

                        // Visual chat message box
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(colors.insetBackground, RoundedCornerShape(8.dp))
                                .padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                "To: LogCal Bot",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.mutedText,
                                fontWeight = FontWeight.Bold
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End
                            ) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFDCF8C6)) // Chat green
                                        .padding(8.dp)
                                ) {
                                    Text(
                                        text = if (linkageCode.isBlank()) "Please link my LogCal account with code: <code>" else "Please link my LogCal account with code: $linkageCode",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.Black
                                    )
                                }
                            }
                        }
                    }

                    if (linkageCode.isBlank()) {
                        Button(
                            onClick = {
                                AnalyticsService.trackWhatsAppLinkTapped()
                                linkFlow()
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp),
                            shape = RoundedCornerShape(25.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                        ) {
                            Text("Link with WhatsApp", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium, color = Color.White)
                        }
                    } else {
                        Button(
                            onClick = {
                                AnalyticsService.trackWhatsAppOpenWATapped()
                                openWhatsApp(linkageCode)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp),
                            shape = RoundedCornerShape(25.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = colors.primaryGreen)
                        ) {
                            Text("Open WhatsApp to Link", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium, color = Color.White)
                        }

                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(colors.cardBackground.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                                .border(1.dp, colors.cardBorder, RoundedCornerShape(12.dp))
                                .padding(16.dp)
                        ) {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Code:", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = colors.mutedText)
                                Text(linkageCode, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace, color = colors.primaryGreen)
                                Text("(${formattedTime(secondsRemaining)})", style = MaterialTheme.typography.bodySmall, color = colors.warningAmber, fontWeight = FontWeight.Bold)
                            }

                            Row(
                                modifier = Modifier
                                    .clickable {
                                        AnalyticsService.trackWhatsAppCheckStatusTapped()
                                        loadStatus()
                                    }
                                    .padding(8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = null, tint = colors.primaryGreen, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Check Linkage Status", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = colors.primaryGreen)
                            }
                        }
                    }
                }

                if (errorMessage != null) {
                    Text(errorMessage!!, color = colors.dangerRed, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center)
                }
            }
        }
    }
}
