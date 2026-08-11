package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Add-flow header: back chevron + three 22×6 progress pills (README > Group 3). [step] is 1-based. */
@Composable
fun AddFlowHeader(step: Int, onBack: () -> Unit) {
    val colors = NirbhorTheme.colors
    Row(
        Modifier.fillMaxWidth().background(colors.paper)
            .windowInsetsPadding(WindowInsets.statusBars)
            .padding(horizontal = Dimens.denseHeaderPadding, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(Dimens.tapMin).clip(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = colors.ink)
        }
        Spacer(Modifier.width(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            repeat(3) { i ->
                Box(
                    Modifier.size(width = 22.dp, height = 6.dp).clip(RoundedCornerShape(3.dp))
                        .background(if (i < step) colors.calm else colors.line),
                )
            }
        }
    }
}

/** Standard add-flow screen shell: header (optional progress) + a padded body column on paper. */
@Composable
fun AddFlowScaffold(
    step: Int?,
    onBack: () -> Unit,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit,
) {
    val colors = NirbhorTheme.colors
    Column(Modifier.background(colors.paper)) {
        if (step != null) AddFlowHeader(step, onBack)
        content()
    }
}
