package com.nirbhor.app.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Nirbhor design tokens. Defined once, used everywhere (README > Design Tokens > Colour).
 *
 * The palette is a calm health palette: primary is a healing green ([calm]); urgency is a muted
 * amber ([warm]) — never red. Accent colours ([slate], [ochre], [mauve]) are used ONLY as medicine
 * marks, never as UI chrome.
 */
@Immutable
data class NirbhorColors(
    val ink: Color = Color(0xFF1B2A26),       // Primary text; deep green-black
    val ink2: Color = Color(0xFF4A5C56),      // Secondary text, body copy on cards
    val ink3: Color = Color(0xFF8B9A94),      // Tertiary text, labels, disabled, placeholder
    val paper: Color = Color(0xFFF4F2EC),     // App background (warm off-white)
    val card: Color = Color(0xFFFFFFFF),      // Card / sheet / nav-bar surface
    val sage: Color = Color(0xFFE3EAE4),      // Neutral tinted fill (secondary chips, empty track)
    val line: Color = Color(0xFFDCD8CE),      // Hairline border, 1px dividers
    val calm: Color = Color(0xFF2F6B5B),      // PRIMARY. Buttons, selected, "taken", progress
    val calmD: Color = Color(0xFF1F4F42),     // Primary dark — alarm background, text on calm-soft
    val calmSoft: Color = Color(0xFFDCEAE4),  // Primary tinted fill (info panels, selected chips)
    val warm: Color = Color(0xFFC07138),      // URGENCY. Due now, missed, low stock
    val warmSoft: Color = Color(0xFFF6E7D8),  // Urgency tinted fill
    val warmD: Color = Color(0xFF8A4A1C),     // Text and solid buttons on warm-soft

    // Accent colours — medicine marks ONLY, never UI chrome.
    val markSlate: Color = Color(0xFF7D94A8),
    val markOchre: Color = Color(0xFFB9975B),
    val markMauve: Color = Color(0xFFA8788F),

    // On the dark alarm background, marks lighten to these.
    val markCalmOnDark: Color = Color(0xFF7FC0AC),
    val markSlateOnDark: Color = Color(0xFF9FB6C8),

    // Alarm surface text.
    val alarmText: Color = Color(0xFFEEF3F0),
)

val LocalNirbhorColors = staticCompositionLocalOf { NirbhorColors() }
