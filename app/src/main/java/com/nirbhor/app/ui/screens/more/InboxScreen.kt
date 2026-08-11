package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

private data class InboxItem(val icon: ImageVector, val title: String, val body: String, val amber: Boolean, val onClick: (() -> Unit)? = null)

/** Notification inbox (6b): day-grouped; unread carries a 4px warm left rule, read drops to 72%. */
@Composable
fun InboxScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val stock by repo.stockStatuses().collectAsStateWithLifecycle(initialValue = emptyList())
    val meds by repo.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    var allRead by remember { mutableStateOf(false) }

    // Real, derived notifications only — one low-stock note per medicine that's running low.
    val lowMeds = meds.filter { m -> stock.firstOrNull { it.medicineId == m.id }?.isLow == true }
    val today = lowMeds.map { m ->
        InboxItem(
            Icons.Filled.Inventory2,
            tr("${m.displayName} ফুরিয়ে আসছে", "${m.displayName} running low"),
            tr("রিফিলে গিয়ে মজুত ঠিক করুন", "Open Refill to update stock"),
            amber = true, onClick = actions::openRefill,
        )
    }
    val earlier = emptyList<InboxItem>()

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(
            title = tr("খবর", "Notifications"), onBack = actions::back,
            trailing = {
                Text(tr("সব পড়া হয়েছে", "Mark all read"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.calm,
                    modifier = Modifier.clickable { allRead = true }.padding(6.dp))
            },
        )
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = Dimens.screenPadding, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            if (today.isEmpty() && earlier.isEmpty()) {
                Spacer(Modifier.height(40.dp))
                Text(tr("এখন কোনো খবর নেই", "No notifications yet"), style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink, modifier = Modifier.fillMaxWidth())
                Text(tr("ওষুধ ও মজুতের খবর এখানে আসবে।", "Dose and stock alerts will appear here."), style = NirbhorTheme.type.body, color = colors.ink3, modifier = Modifier.fillMaxWidth())
            } else {
                InboxGroup(tr("আজ", "Today"), today, read = allRead)
                InboxGroup(tr("আগে", "Earlier"), earlier, read = true)
            }
        }
    }
}

@Composable
private fun InboxGroup(label: String, items: List<InboxItem>, read: Boolean) {
    val colors = NirbhorTheme.colors
    if (items.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
        Text(label, style = NirbhorTheme.type.sectionLabel, color = colors.ink3)
        items.forEach { item ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusCard)).background(colors.card)
                    .then(if (item.onClick != null) Modifier.clickable(onClick = item.onClick) else Modifier)
                    .alpha(if (read) 0.72f else 1f),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.width(4.dp).height(56.dp).background(if (!read) colors.warm else Color.Transparent))
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(38.dp).clip(RoundedCornerShape(11.dp)).background(if (item.amber) colors.warmSoft else colors.calmSoft), contentAlignment = Alignment.Center) {
                        Icon(item.icon, contentDescription = null, tint = if (item.amber) colors.warmD else colors.calmD, modifier = Modifier.size(20.dp))
                    }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(item.title, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                        Text(item.body, style = NirbhorTheme.type.meta, color = colors.ink3)
                    }
                }
            }
        }
    }
}
