package com.nirbhor.app.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

/**
 * The type scale from README > Design Tokens > Typography. Bangla (Anek Bangla) renders visibly
 * taller than English (Archivo) at the same px, so most Bangla roles are 1–2px smaller and get a
 * touch more line-height. Letter-spacing and uppercase are NEVER applied to Bangla — splitting a
 * conjunct reorders vowel signs.
 */
@Immutable
data class NirbhorType(
    val titleHero: TextStyle,
    val header: TextStyle,
    val alarmTime: TextStyle,
    val alarmName: TextStyle,
    val bigStat: TextStyle,
    val cardTitlePrimary: TextStyle,
    val cardTitleSecondary: TextStyle,
    val body: TextStyle,
    val meta: TextStyle,
    val sectionLabel: TextStyle,
    val buttonLabel: TextStyle,
    val statusPill: TextStyle,
    /** true when the active locale is Bangla — components use this to skip uppercase / spacing. */
    val isBangla: Boolean,
    /** Archivo is always used for Latin runs (codes, emails, pack names) even in Bangla. */
    val latin: FontFamily,
)

private val trim = LineHeightStyle(
    alignment = LineHeightStyle.Alignment.Center,
    trim = LineHeightStyle.Trim.None,
)

/** Builds the scale for the active locale. [scale] applies the OS / in-app "bigger text" setting. */
fun buildNirbhorType(isBangla: Boolean, scale: Float = 1f): NirbhorType {
    val family = if (isBangla) AnekBangla else Archivo
    fun sp(px: Float): TextUnit = (px * scale).sp
    fun lh(px: Float, mult: Float): TextUnit = (px * mult * scale).sp
    // Letter spacing / uppercase only exist in the English locale.
    val ls: (Double) -> TextUnit = { if (isBangla) 0.sp else it.em }

    fun style(
        px: Float,
        weight: Int,
        lineMult: Float,
        letter: TextUnit = 0.sp,
        fam: FontFamily = family,
    ) = TextStyle(
        fontFamily = fam,
        fontWeight = FontWeight(weight),
        fontSize = sp(px),
        lineHeight = lh(px, lineMult),
        letterSpacing = letter,
        lineHeightStyle = trim,
    )

    return NirbhorType(
        titleHero = style(if (isBangla) 27f else 26f, 700, 1.35f),
        header = style(if (isBangla) 22f else 21f, 700, 1.12f),
        alarmTime = style(84f, 700, 0.90f, letter = ls(-0.045)),
        alarmName = style(if (isBangla) 23f else 22f, 700, 1.1f),
        bigStat = style(46f, 700, 1.0f, letter = ls(-0.03)),
        cardTitlePrimary = style(18f, 700, 1.2f),
        cardTitleSecondary = style(if (isBangla) 16.5f else 15.5f, 600, 1.2f),
        body = style(if (isBangla) 16f else 15.5f, 400, if (isBangla) 1.7f else 1.6f),
        meta = style(if (isBangla) 13f else 12.5f, 400, 1.4f),
        // Section label: EN 11.5 uppercase + spacing (applied by the component); BN 13.5 sentence case.
        sectionLabel = if (isBangla) {
            style(13.5f, 600, 1.0f)
        } else {
            style(11.5f, 600, 1.0f, letter = 0.1.em)
        },
        buttonLabel = style(if (isBangla) 18f else 17f, 700, 1.1f),
        statusPill = style(if (isBangla) 12f else 11f, 600, 1.0f),
        isBangla = isBangla,
        latin = Archivo,
    )
}

val LocalNirbhorType = staticCompositionLocalOf { buildNirbhorType(isBangla = true) }
