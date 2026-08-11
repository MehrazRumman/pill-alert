package com.nirbhor.app.ui.theme

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import com.nirbhor.app.R

/**
 * Both families are bundled as variable fonts (README > Assets: "bundle locally; do not rely on a
 * webfont fetch"). We derive the 400/500/600/700(/800) instances from the single variable file via
 * [FontVariation] — supported on API 26+, which is our minSdk.
 */
private fun anek(weight: Int) = Font(
    R.font.anekbangla_variable,
    weight = FontWeight(weight),
    variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
)

private fun archivo(weight: Int) = Font(
    R.font.archivo_variable,
    weight = FontWeight(weight),
    variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
)

/** Anek Bangla — the Bangla (primary) locale family. */
val AnekBangla = FontFamily(
    anek(400), anek(500), anek(600), anek(700),
)

/** Archivo — the English (secondary) locale family, and always used for Latin runs (codes,
 *  email addresses, medicine pack names) regardless of the active locale. */
val Archivo = FontFamily(
    archivo(400), archivo(500), archivo(600), archivo(700), archivo(800),
)
