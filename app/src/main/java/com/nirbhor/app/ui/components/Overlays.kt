package com.nirbhor.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorShapes
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Full-screen scrim behind a bottom sheet. Tapping it dismisses. */
@Composable
fun Scrim(onDismiss: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxSize()
            .background(Color(0x6B1B2A26)) // rgba(27,42,38,0.42)
            .clickable(
                interactionSource = androidx.compose.runtime.remember { MutableInteractionSource() },
                indication = null,
                onClick = onDismiss,
            ),
    )
}

/** Bottom-sheet container: card surface, 24px top corners, grab handle, top shadow. */
@Composable
fun SheetSurface(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = NirbhorTheme.colors
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(NirbhorShapes.sheetTop)
            .background(colors.card)
            .navigationBarsPadding()
            .padding(Dimens.sheetPadding),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            Modifier
                .padding(bottom = 14.dp)
                .size(width = 44.dp, height = 5.dp)
                .clip(CircleShape)
                .background(colors.line),
        )
        content()
    }
}

/**
 * Undo toast (README > 4f): dark calm-d fill, radius 14, check tile + message + undo button, pinned
 * 16px from the bottom. Auto-dismiss (~5s) is the caller's job.
 */
@Composable
fun UndoToast(
    message: String,
    actionLabel: String,
    onAction: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = NirbhorTheme.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(colors.calmD)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.size(32.dp).clip(RoundedCornerShape(8.dp)).background(colors.calm),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = colors.paper, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(12.dp))
        Text(message, style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(12.dp))
        Box(
            Modifier
                .clip(RoundedCornerShape(10.dp))
                .clickable(onClick = onAction)
                .padding(horizontal = 14.dp, vertical = 9.dp),
        ) {
            Text(actionLabel, style = NirbhorTheme.type.buttonLabel, color = colors.markCalmOnDark)
        }
    }
}
