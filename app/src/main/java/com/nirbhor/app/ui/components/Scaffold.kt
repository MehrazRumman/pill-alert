package com.nirbhor.app.ui.components

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
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Header bar for pushed screens: back chevron + title on a card surface with a hairline bottom border. */
@Composable
fun NirbhorTopBar(
    title: String,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val colors = NirbhorTheme.colors
    Column(modifier = modifier.fillMaxWidth().background(colors.card)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = Dimens.denseHeaderPadding, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBack != null) {
                Box(
                    Modifier.size(Dimens.tapMin).clip(CircleShape).clickable(onClick = onBack),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = colors.ink)
                }
                Spacer(Modifier.width(6.dp))
            }
            Text(title, style = NirbhorTheme.type.header, color = colors.ink, modifier = Modifier.weight(1f))
            if (trailing != null) trailing()
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.line))
    }
}

/** One bottom-nav tab. */
data class NavTab(
    val route: String,
    val icon: ImageVector,
    val labelBn: String,
    val labelEn: String,
)

/** Four-tab bottom nav. Active item gets calm text on a calm-soft radius-12 pill. */
@Composable
fun BottomNavBar(
    tabs: List<NavTab>,
    currentRoute: String?,
    isBangla: Boolean,
    onSelect: (NavTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = NirbhorTheme.colors
    Column(modifier = modifier.fillMaxWidth().background(colors.card)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.line))
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            tabs.forEach { tab ->
                val active = currentRoute == tab.route
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .height(Dimens.bottomNavItem)
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onSelect(tab) },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Box(
                        Modifier
                            .clip(RoundedCornerShape(12.dp))
                            .background(if (active) colors.calmSoft else androidx.compose.ui.graphics.Color.Transparent)
                            .padding(horizontal = 16.dp, vertical = 4.dp),
                    ) {
                        Icon(
                            tab.icon,
                            contentDescription = if (isBangla) tab.labelBn else tab.labelEn,
                            tint = if (active) colors.calm else colors.ink3,
                            modifier = Modifier.size(Dimens.navIcon),
                        )
                    }
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = if (isBangla) tab.labelBn else tab.labelEn,
                        style = NirbhorTheme.type.statusPill,
                        color = if (active) colors.calm else colors.ink3,
                    )
                }
            }
        }
    }
}
