package com.serene.logcal.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.serene.logcal.R

val Nunito = FontFamily(
    Font(R.font.nunito_regular, FontWeight.Normal),
    Font(R.font.nunito_medium, FontWeight.Medium),
    Font(R.font.nunito_semibold, FontWeight.SemiBold),
    Font(R.font.nunito_bold, FontWeight.Bold)
)

val AppTypography = Typography().run {
    copy(
        displayLarge = displayLarge.copy(fontFamily = Nunito),
        displayMedium = displayMedium.copy(fontFamily = Nunito),
        displaySmall = displaySmall.copy(fontFamily = Nunito),
        headlineLarge = headlineLarge.copy(fontFamily = Nunito),
        headlineMedium = headlineMedium.copy(fontFamily = Nunito),
        headlineSmall = headlineSmall.copy(fontFamily = Nunito),
        titleLarge = titleLarge.copy(fontFamily = Nunito),
        titleMedium = titleMedium.copy(fontFamily = Nunito),
        titleSmall = titleSmall.copy(fontFamily = Nunito),
        bodyLarge = bodyLarge.copy(fontFamily = Nunito),
        bodyMedium = bodyMedium.copy(fontFamily = Nunito),
        bodySmall = bodySmall.copy(fontFamily = Nunito),
        labelLarge = labelLarge.copy(fontFamily = Nunito),
        labelMedium = labelMedium.copy(fontFamily = Nunito),
        labelSmall = labelSmall.copy(fontFamily = Nunito)
    )
}

data class LogCalColors(
    val primaryGreen: Color = PrimaryGreen,
    val mintGreen: Color = MintGreen,
    val warningAmber: Color = WarningAmber,
    val dangerRed: Color = DangerRed,
    val protein: Color = ProteinColor,
    val carbs: Color = CarbsColor,
    val fat: Color = FatColor,
    val fiber: Color = FiberColor,
    
    val background: Color,
    val cardBackground: Color,
    val elevatedCardBackground: Color,
    val heroCardBackground: Color,
    val insetBackground: Color,
    val cardBorder: Color,
    val primaryText: Color,
    val mutedText: Color,
    val quietText: Color,
    val softAccentBackground: Color,
    val shadowColor: Color
)

private val LightLogCalColors = LogCalColors(
    background = LightBackground,
    cardBackground = LightCard,
    elevatedCardBackground = LightElevatedCard,
    heroCardBackground = LightHeroCard,
    insetBackground = LightInset,
    cardBorder = LightBorder,
    primaryText = LightPrimaryText,
    mutedText = LightSecondaryText,
    quietText = LightTertiaryText,
    softAccentBackground = PrimaryGreen.copy(alpha = 0.1f),
    shadowColor = Color.Black.copy(alpha = 0.06f)
)

private val DarkLogCalColors = LogCalColors(
    background = DarkBackground,
    cardBackground = DarkCard,
    elevatedCardBackground = DarkElevatedCard,
    heroCardBackground = DarkHeroCard,
    insetBackground = DarkInset,
    cardBorder = DarkBorder,
    primaryText = DarkPrimaryText,
    mutedText = DarkSecondaryText,
    quietText = DarkTertiaryText,
    softAccentBackground = PrimaryGreen.copy(alpha = 0.18f),
    shadowColor = Color.Black.copy(alpha = 0.28f)
)

val LocalLogCalColors = staticCompositionLocalOf { LightLogCalColors }

object LogCalTheme {
    val colors: LogCalColors
        @Composable
        @ReadOnlyComposable
        get() = LocalLogCalColors.current
}

@Composable
fun LogCalTheme(
    theme: String = "system",
    content: @Composable () -> Unit
) {
    val darkTheme = when (theme) {
        "light" -> false
        "dark" -> true
        else -> isSystemInDarkTheme()
    }
    
    val logCalColors = if (darkTheme) DarkLogCalColors else LightLogCalColors
    
    val colorScheme = if (darkTheme) {
        darkColorScheme(
            primary = PrimaryGreen,
            secondary = MintGreen,
            background = DarkBackground,
            surface = DarkCard,
            onPrimary = Color.White,
            onSecondary = Color.Black,
            onBackground = DarkPrimaryText,
            onSurface = DarkPrimaryText
        )
    } else {
        lightColorScheme(
            primary = PrimaryGreen,
            secondary = MintGreen,
            background = LightBackground,
            surface = LightCard,
            onPrimary = Color.White,
            onSecondary = Color.White,
            onBackground = LightPrimaryText,
            onSurface = LightPrimaryText
        )
    }
    
    CompositionLocalProvider(
        LocalLogCalColors provides logCalColors
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = AppTypography,
            content = content
        )
    }
}
