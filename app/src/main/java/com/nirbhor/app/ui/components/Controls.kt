package com.nirbhor.app.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nirbhor.app.ui.theme.NirbhorTheme

/** 50×30 toggle, 24px white knob. Track goes calm when on (or warmD for the amber override row). */
@Composable
fun NbSwitch(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    onColor: Color? = null,
) {
    val colors = NirbhorTheme.colors
    val track = if (checked) (onColor ?: colors.calm) else colors.line
    val knobOffset by animateDpAsState(if (checked) 22.dp else 2.dp, label = "knob")
    Box(
        modifier = modifier
            .size(50.dp, 30.dp)
            .clip(RoundedCornerShape(15.dp))
            .background(track)
            .clickable { onCheckedChange(!checked) },
    ) {
        Box(
            Modifier
                .padding(top = 3.dp)
                .offset(x = knobOffset)
                .size(24.dp)
                .clip(CircleShape)
                .background(colors.card),
        )
    }
}

/** Segmented control: paper track, active segment calm-filled. Week/Month, range selectors, etc. */
@Composable
fun SegmentedControl(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = NirbhorTheme.colors
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(11.dp))
            .background(colors.paper)
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        options.forEachIndexed { i, label ->
            val active = i == selectedIndex
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(38.dp)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (active) colors.calm else Color.Transparent)
                    .clickable { onSelect(i) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = label,
                    style = NirbhorTheme.type.cardTitleSecondary,
                    color = if (active) colors.paper else colors.ink2,
                )
            }
        }
    }
}

/**
 * Quantity stepper (README > 3d): [size]px −/+ buttons (minus outlined on paper, plus solid calm),
 * a centred 46/700 value and a unit label below. Steps by [step] (supports halves).
 */
@Composable
fun QuantityStepper(
    value: Float,
    onChange: (Float) -> Unit,
    valueLabel: String,
    unitLabel: String,
    modifier: Modifier = Modifier,
    size: Dp = 72.dp,
    step: Float = 1f,
    min: Float = 0f,
) {
    val colors = NirbhorTheme.colors
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        StepperButton(size, filled = false) {
            val next = (value - step).coerceAtLeast(min)
            if (next != value) onChange(next)
        }
        Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
            androidx.compose.foundation.layout.Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(valueLabel, fontSize = 46.sp, fontWeight = FontWeight(700), color = colors.ink)
                Text(unitLabel, style = NirbhorTheme.type.meta, color = colors.ink3)
            }
        }
        StepperButton(size, filled = true) { onChange(value + step) }
    }
}

@Composable
private fun StepperButton(size: Dp, filled: Boolean, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    Box(
        modifier = Modifier
            .size(size)
            .clip(RoundedCornerShape(16.dp))
            .background(if (filled) colors.calm else colors.paper)
            .then(if (filled) Modifier else Modifier.border(1.5.dp, colors.line, RoundedCornerShape(16.dp)))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = if (filled) Icons.Filled.Add else Icons.Filled.Remove,
            contentDescription = null,
            tint = if (filled) colors.paper else colors.ink2,
            modifier = Modifier.size(28.dp),
        )
    }
}

/** Quick chip (আধা / ১ / ২ / ৩). Selected chip must always match the stepper value. */
@Composable
fun QuickChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 52.dp,
) {
    val colors = NirbhorTheme.colors
    Box(
        modifier = modifier
            .height(height)
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) colors.calm else colors.sage)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = NirbhorTheme.type.cardTitleSecondary,
            color = if (selected) colors.paper else colors.ink2,
        )
    }
}

/**
 * A large selectable row (README > 3c timing rows, 4a channel cards): icon + title (+ subtitle) and a
 * trailing check circle. Selected = calm fill, white text, filled check. Supports multi-select.
 */
@Composable
fun SelectableRow(
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    height: Dp = 88.dp,
    leading: (@Composable () -> Unit)? = null,
) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(14.dp)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(shape)
            .background(if (selected) colors.calm else colors.card)
            .border(BorderStroke(if (selected) 2.dp else 1.5.dp, if (selected) colors.calm else colors.line), shape)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leading != null) {
            leading()
            Spacer(Modifier.width(14.dp))
        }
        androidx.compose.foundation.layout.Column(Modifier.weight(1f)) {
            Text(title, style = NirbhorTheme.type.cardTitlePrimary, color = if (selected) colors.paper else colors.ink)
            if (subtitle != null) {
                Text(subtitle, style = NirbhorTheme.type.meta, color = if (selected) colors.paper.copy(alpha = 0.85f) else colors.ink2)
            }
        }
        Spacer(Modifier.width(12.dp))
        CheckCircle(selected)
    }
}

@Composable
fun CheckCircle(selected: Boolean, size: Dp = 34.dp) {
    val colors = NirbhorTheme.colors
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(if (selected) colors.card else Color.Transparent)
            .border(if (selected) 0.dp else 2.dp, if (selected) Color.Transparent else colors.line, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (selected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = colors.calm,
                modifier = Modifier.size(size * 0.62f),
            )
        }
    }
}
