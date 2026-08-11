package com.nirbhor.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight

/**
 * Reads the Nirbhor design tokens. Use [NirbhorTheme.colors], [NirbhorTheme.type], plus the
 * [Dimens] / [NirbhorShapes] objects, in place of raw hexes and sizes everywhere.
 */
object NirbhorTheme {
    val colors: NirbhorColors
        @Composable get() = LocalNirbhorColors.current
    val type: NirbhorType
        @Composable get() = LocalNirbhorType.current
}

/**
 * App theme. Bangla is primary, so [isBangla] defaults true. [biggerText] applies the "সহজে পড়ার
 * জন্য / bigger text" accessibility setting (up to ~1.3× per the responsive spec).
 *
 * The palette is a single warm-light scheme; the design does not define a dark variant, so we keep
 * the calm health palette in both system themes rather than inverting it.
 */
@Composable
fun NirbhorTheme(
    isBangla: Boolean = true,
    biggerText: Boolean = false,
    content: @Composable () -> Unit,
) {
    @Suppress("UNUSED_VARIABLE") // reserved: a future dark palette could branch on this.
    val dark = isSystemInDarkTheme()
    val colors = remember { NirbhorColors() }
    val scale = if (biggerText) 1.15f else 1f
    val type = remember(isBangla, scale) { buildNirbhorType(isBangla, scale) }

    val defaultFamily: FontFamily = if (isBangla) AnekBangla else Archivo

    // Material3 scheme, mapped from our tokens so stock M3 components stay on-palette.
    // error → warm (never red).
    val scheme = lightColorScheme(
        primary = colors.calm,
        onPrimary = colors.paper,
        primaryContainer = colors.calmSoft,
        onPrimaryContainer = colors.calmD,
        secondary = colors.calm,
        onSecondary = colors.paper,
        secondaryContainer = colors.sage,
        onSecondaryContainer = colors.ink,
        background = colors.paper,
        onBackground = colors.ink,
        surface = colors.card,
        onSurface = colors.ink,
        surfaceVariant = colors.sage,
        onSurfaceVariant = colors.ink2,
        outline = colors.line,
        outlineVariant = colors.line,
        error = colors.warm,
        onError = colors.paper,
        errorContainer = colors.warmSoft,
        onErrorContainer = colors.warmD,
    )

    val m3Typography = remember(type) {
        val base = Typography()
        val bodyStyle = type.body.copy(fontFamily = defaultFamily)
        base.copy(
            bodyLarge = bodyStyle,
            bodyMedium = bodyStyle,
            bodySmall = type.meta.copy(fontFamily = defaultFamily),
            titleLarge = type.header.copy(fontFamily = defaultFamily, fontWeight = FontWeight(700)),
            labelLarge = type.buttonLabel.copy(fontFamily = defaultFamily),
        )
    }

    CompositionLocalProvider(
        LocalNirbhorColors provides colors,
        LocalNirbhorType provides type,
    ) {
        MaterialTheme(
            colorScheme = scheme,
            typography = m3Typography,
            content = content,
        )
    }
}
