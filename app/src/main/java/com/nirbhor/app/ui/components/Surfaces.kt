package com.nirbhor.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Card shadow (README): calm cards get a soft ink shadow; urgent cards get a stronger amber shadow.
 * Compose collapses the design's two-layer shadow into a single elevation with a tinted spot colour.
 */
fun Modifier.nbCardShadow(shape: RoundedCornerShape, elevated: Boolean = false): Modifier =
    this.shadow(
        elevation = if (elevated) 12.dp else 8.dp,
        shape = shape,
        ambientColor = Color(0x141B2A26),
        spotColor = if (elevated) Color(0x2EC07138) else Color(0x141B2A26),
    )

/** Standard white card. */
@Composable
fun NbCard(
    modifier: Modifier = Modifier,
    padding: Dp = Dimens.cardPadding,
    radius: Dp = Dimens.radiusCard,
    onClick: (() -> Unit)? = null,
    border: BorderStroke? = null,
    background: Color? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(radius)
    Column(
        modifier = modifier
            .nbCardShadow(shape)
            .clip(shape)
            .background(background ?: colors.card)
            .then(if (border != null) Modifier.border(border, shape) else Modifier)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(padding),
        content = content,
    )
}

/** Due-now / urgent card: 2px warm border + amber shadow. */
@Composable
fun UrgentCard(
    modifier: Modifier = Modifier,
    padding: Dp = Dimens.cardPadding,
    radius: Dp = Dimens.radiusCard,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(radius)
    Column(
        modifier = modifier
            .nbCardShadow(shape, elevated = true)
            .clip(shape)
            .background(colors.card)
            .border(BorderStroke(2.dp, colors.warm), shape)
            .padding(padding),
        content = content,
    )
}

/** A flat tinted panel (sage / calm-soft / warm-soft info panels). No shadow. */
@Composable
fun TintPanel(
    background: Color,
    modifier: Modifier = Modifier,
    padding: Dp = Dimens.cardPadding,
    radius: Dp = Dimens.radiusCard,
    border: BorderStroke? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(radius)
    Column(
        modifier = modifier
            .clip(shape)
            .background(background)
            .then(if (border != null) Modifier.border(border, shape) else Modifier)
            .padding(padding),
        content = content,
    )
}
