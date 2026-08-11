package com.nirbhor.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Section label. English is UPPERCASE with letter-spacing (11.5px); Bangla is sentence-case, 13.5px,
 * NO uppercase and NO letter-spacing (Bengali script has no case and spacing breaks conjuncts).
 */
@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier, color: Color? = null) {
    val bangla = LocalIsBangla.current
    Text(
        text = if (bangla) text else text.uppercase(),
        style = NirbhorTheme.type.sectionLabel,
        color = color ?: NirbhorTheme.colors.ink3,
        modifier = modifier,
    )
}

/**
 * Status pill — the coloured capsule that carries a dose-state word (এখন সময় / নেওয়া হয়েছে / ৪টি বাকি).
 * Three redundant signals per state are the caller's job (shape + fill + word); this renders fill+word.
 */
@Composable
fun StatusPill(
    text: String,
    background: Color,
    contentColor: Color,
    modifier: Modifier = Modifier,
) {
    Text(
        text = text,
        style = NirbhorTheme.type.statusPill,
        color = contentColor,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier
            .background(background, RoundedCornerShape(9.dp))
            .padding(horizontal = 10.dp, vertical = 5.dp),
    )
}
