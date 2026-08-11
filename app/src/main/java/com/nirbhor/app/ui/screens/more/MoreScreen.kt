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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** More hub (6a). Main tab. Patient card → family/stock/report → settings/help → version. */
@Composable
fun MoreScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val medicines by repo.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    val stock by repo.stockStatuses().collectAsStateWithLifecycle(initialValue = emptyList())
    val lowCount = stock.count { it.isLow }

    Column(
        Modifier
            .fillMaxSize().background(colors.paper)
            .verticalScroll(rememberScrollState())
            .windowInsetsPadding(WindowInsets.statusBars)
            .padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
    ) {
        Text(tr("আরও", "More"), style = NirbhorTheme.type.titleHero, color = colors.ink)

        // Patient card.
        NbCard {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(52.dp).clip(RoundedCornerShape(16.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
                    Text(tr("আ", "Y"), style = NirbhorTheme.type.header, color = colors.calmD)
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text(tr("আপনি", "You"), style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                    Text(
                        tr("${num(medicines.size)}টি ওষুধ", "${medicines.size} medicines"),
                        style = NirbhorTheme.type.meta, color = colors.ink3,
                    )
                }
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
            HubRow(Icons.Filled.People, tr("পরিবার ও যত্নকারী", "Family & caregivers"),
                tr("কে হিসাব পায় তা ঠিক করুন", "Choose who follows along"), null, actions::openFamily)
            HubRow(Icons.Filled.Inventory2, tr("ওষুধের মজুত", "Stock"),
                tr("ঘরে কতটা আছে দেখুন", "See what's left at home"),
                if (lowCount > 0) tr("${num(lowCount)}টি ফুরিয়ে আসছে", "$lowCount running low") else null,
                actions::openRefill)
            HubRow(Icons.Filled.PictureAsPdf, tr("ডাক্তারের রিপোর্ট", "Doctor report"),
                tr("পিডিএফ বানিয়ে পাঠান", "Make and share a PDF"), null, actions::openDoctorReport)
        }

        Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
            HubRow(Icons.Filled.Settings, tr("সেটিংস", "Settings"),
                tr("ভাষা, মনে করিয়ে দেওয়া, পড়ার সুবিধা", "Language, reminders, reading"), null, actions::openSettings)
            HubRow(Icons.AutoMirrored.Filled.HelpOutline, tr("সাহায্য", "Help"),
                tr("সাধারণ প্রশ্ন ও যোগাযোগ", "FAQ and contact"), null) {}
        }

        Text(tr("নির্ভর · সংস্করণ ১.০.০", "Nirbhor · version 1.0.0"),
            style = NirbhorTheme.type.meta, color = colors.ink3, modifier = Modifier.fillMaxWidth())
    }
}

@Composable
private fun HubRow(icon: ImageVector, label: String, explainer: String, amber: String?, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    NbCard(onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(38.dp).clip(RoundedCornerShape(11.dp)).background(colors.sage), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = colors.ink2, modifier = Modifier.size(20.dp))
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(label, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                Text(amber ?: explainer, style = NirbhorTheme.type.meta, color = if (amber != null) colors.warmD else colors.ink3)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = colors.ink3)
        }
    }
}
