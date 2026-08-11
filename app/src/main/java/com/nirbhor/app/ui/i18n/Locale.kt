package com.nirbhor.app.ui.i18n

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * Locale primitives. Bangla is primary. Rather than a central strings file (a merge bottleneck when
 * many screens are built in parallel), screens pair the two languages at the call site with [tr] —
 * which mirrors how the design pairs bn/en copy. Numerals/time formatting read the same locals.
 */
val LocalIsBangla = staticCompositionLocalOf { true }
val LocalIs24Hour = staticCompositionLocalOf { false }

/** Picks Bangla or English copy for the active locale. */
@Composable
@ReadOnlyComposable
fun tr(bn: String, en: String): String = if (LocalIsBangla.current) bn else en

/** Localised integer (Bengali numerals in the Bangla locale). */
@Composable
@ReadOnlyComposable
fun num(value: Int): String = Numerals.number(value, LocalIsBangla.current)

/** Localises the digits in an already-formatted string (e.g. "৫৪টি"). */
@Composable
@ReadOnlyComposable
fun numStr(text: String): String = Numerals.digits(text, LocalIsBangla.current)

@Composable
@ReadOnlyComposable
fun percent(value: Int): String = Numerals.percent(value, LocalIsBangla.current)

/** Localised clock time for the active locale + time-format. */
@Composable
@ReadOnlyComposable
fun clock(hour: Int, minute: Int): String =
    Numerals.time(hour, minute, LocalIsBangla.current, LocalIs24Hour.current)
