package com.nirbhor.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * The Nirbhor button family. Height is passed per context (README > Touch targets): 56 home
 * dose-confirm, 60–68 add-medicine/alarm flow, 80 alarm confirm. Primary = calm fill; secondary =
 * outlined. Labels can be centred or left-aligned with a leading icon (the first-run actions).
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = Dimens.flowButton,
    enabled: Boolean = true,
    container: Color? = null,
    content: Color? = null,
    leftAligned: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val colors = NirbhorTheme.colors
    NbButtonSurface(modifier, height, enabled, container ?: colors.calm, null, onClick) {
        ButtonRow(leftAligned, leading, trailing) {
            Text(
                text = text,
                style = NirbhorTheme.type.buttonLabel,
                color = content ?: colors.paper,
                textAlign = if (leftAligned) TextAlign.Start else TextAlign.Center,
            )
        }
    }
}

@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = Dimens.flowButton,
    enabled: Boolean = true,
    borderColor: Color? = null,
    content: Color? = null,
    leftAligned: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
) {
    val colors = NirbhorTheme.colors
    NbButtonSurface(modifier, height, enabled, colors.card, BorderStroke(1.5.dp, borderColor ?: colors.line), onClick) {
        ButtonRow(leftAligned, leading, null) {
            Text(
                text = text,
                style = NirbhorTheme.type.buttonLabel,
                color = content ?: colors.calm,
                textAlign = if (leftAligned) TextAlign.Start else TextAlign.Center,
            )
        }
    }
}

@Composable
private fun NbButtonSurface(
    modifier: Modifier,
    height: Dp,
    enabled: Boolean,
    background: Color,
    border: BorderStroke?,
    onClick: () -> Unit,
    content: @Composable () -> Unit,
) {
    val shape = RoundedCornerShape(Dimens.radiusButton)
    Box(
        modifier = modifier
            .heightIn(min = height)
            .clip(shape)
            .background(background)
            .then(if (border != null) Modifier.border(border, shape) else Modifier)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 8.dp)
            .alpha(if (enabled) 1f else 0.5f),
        contentAlignment = Alignment.Center,
    ) { content() }
}

@Composable
private fun ButtonRow(
    leftAligned: Boolean,
    leading: (@Composable () -> Unit)?,
    trailing: (@Composable () -> Unit)?,
    label: @Composable RowScope.() -> Unit,
) {
    Row(
        modifier = if (leftAligned) Modifier.fillMaxWidth() else Modifier,
        horizontalArrangement = if (leftAligned) Arrangement.Start else Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leading != null) {
            leading()
            Spacer(Modifier.width(10.dp))
        }
        label()
        if (trailing != null) {
            Spacer(Modifier.width(10.dp))
            trailing()
        }
    }
}
