package com.nirbhor.app.ui.i18n

/**
 * Locale-level numeral + time formatting (README > Fidelity > Numerals). The Bangla locale uses
 * Bengali numerals (০১২৩৪৫৬৭৮৯) everywhere — times, doses, counts, percentages, phone numbers —
 * and 12-hour times with a period word. The English locale uses Western numerals and (by default)
 * 24-hour times. This is a locale-level rule, not a per-string one.
 */
object Numerals {

    private val bnDigits = charArrayOf('০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯')

    /** Converts every ASCII digit in [text] to Bengali when [bangla] is true; otherwise returns as-is. */
    fun digits(text: String, bangla: Boolean): String {
        if (!bangla) return text
        val sb = StringBuilder(text.length)
        for (c in text) sb.append(if (c in '0'..'9') bnDigits[c - '0'] else c)
        return sb.toString()
    }

    fun number(value: Int, bangla: Boolean): String = digits(value.toString(), bangla)

    /** Formats whole and half quantities without truncating values such as 1.5 to 1. */
    fun quantity(value: Float, bangla: Boolean): String {
        val roundedHalf = kotlin.math.round(value * 2f) / 2f
        val text = if (roundedHalf % 1f == 0f) {
            roundedHalf.toInt().toString()
        } else {
            "${roundedHalf.toInt()}.5"
        }
        return digits(text, bangla)
    }

    fun percent(value: Int, bangla: Boolean): String =
        if (bangla) digits(value.toString(), true) + "%" else "$value%"

    /** Bangla time-of-day period word for a 24-hour [hour]. */
    fun banglaPeriod(hour: Int): String = when (hour) {
        in 0..3 -> "রাত"
        in 4..5 -> "ভোর"
        in 6..11 -> "সকাল"
        in 12..14 -> "দুপুর"
        in 15..17 -> "বিকাল"
        in 18..19 -> "সন্ধ্যা"
        else -> "রাত"
    }

    /**
     * Formats a clock time. Bangla: "সকাল ৮:০০" (period word + 12h + Bengali digits).
     * English 24h: "08:00". English 12h: "8:00 AM".
     */
    fun time(hour: Int, minute: Int, bangla: Boolean, is24: Boolean): String {
        val mm = minute.toString().padStart(2, '0')
        if (bangla) {
            val period = banglaPeriod(hour)
            val h12 = ((hour + 11) % 12) + 1
            return "$period ${digits("$h12:$mm", true)}"
        }
        return if (is24) {
            "${hour.toString().padStart(2, '0')}:$mm"
        } else {
            val h12 = ((hour + 11) % 12) + 1
            val ampm = if (hour < 12) "AM" else "PM"
            "$h12:$mm $ampm"
        }
    }
}
