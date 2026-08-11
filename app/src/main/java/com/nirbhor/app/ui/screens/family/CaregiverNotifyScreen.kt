package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Smartphone
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.Caregiver
import com.nirbhor.app.domain.CaregiverChannel
import com.nirbhor.app.domain.DigestFrequency
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbSwitch
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.SectionLabel
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Archivo
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Caregiver notification setup (4a): channels (multi), frequency, immediate-escalation override. */
@Composable
fun CaregiverNotifyScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val cg by repo.primaryCaregiver.collectAsStateWithLifecycle(initialValue = null)
    val caregiver = cg ?: return

    fun save(updated: Caregiver) = scope.launch { repo.upsertCaregiver(updated) }
    fun toggleChannel(ch: CaregiverChannel) {
        val next = if (ch in caregiver.channels) caregiver.channels - ch else caregiver.channels + ch
        save(caregiver.copy(channels = next))
    }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("রুমানাকে জানানো", "Telling Rumana"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
                SectionLabel(tr("কীভাবে জানাব", "How to tell them"))
                ChannelCard(Icons.Filled.Mail, tr("ইমেইল", "Email"), tr("বিনামূল্যে · বিস্তারিত হিসাব পাঠানো যায়", "Free · can send a full record"),
                    CaregiverChannel.EMAIL in caregiver.channels, ::toggleChannel, CaregiverChannel.EMAIL, verifiedEmail = caregiver.email.takeIf { caregiver.emailVerified })
                ChannelCard(Icons.Filled.Smartphone, tr("এসএমএস", "SMS"), tr("ইন্টারনেট ছাড়াও পৌঁছায় · ছোট বার্তা", "Reaches without internet · short message"),
                    CaregiverChannel.SMS in caregiver.channels, ::toggleChannel, CaregiverChannel.SMS)
                ChannelCard(Icons.Filled.NotificationsActive, tr("অ্যাপ নোটিফিকেশন", "App notification"), tr("তাদের ফোনে জানানো হবে", "On their phone"),
                    CaregiverChannel.APP in caregiver.channels, ::toggleChannel, CaregiverChannel.APP)
            }

            Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
                SectionLabel(tr("কত ঘন ঘন", "How often"))
                RadioCard(tr("দিনে একবার, সব একসাথে", "Once a day, all together"), tr("রাত ৯:৩০-এ দিনের হিসাব", "Day's summary at 9:30 PM"),
                    caregiver.digestFrequency == DigestFrequency.DAILY_DIGEST) { save(caregiver.copy(digestFrequency = DigestFrequency.DAILY_DIGEST)) }
                RadioCard(tr("প্রতিবার সাথে সাথে", "Every time, right away"), tr("বেশি ইমেইল যাবে", "More emails"),
                    caregiver.digestFrequency == DigestFrequency.IMMEDIATE) { save(caregiver.copy(digestFrequency = DigestFrequency.IMMEDIATE)) }
            }

            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.warmSoft).padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(tr("পরপর দুবার বাদ পড়লে সাথে সাথেই জানাব", "If missed twice in a row, tell them right away"),
                    style = NirbhorTheme.type.cardTitleSecondary, color = colors.warmD, modifier = Modifier.weight(1f))
                Spacer(Modifier.width(12.dp))
                NbSwitch(checked = caregiver.escalateOnSecondMiss, onCheckedChange = { save(caregiver.copy(escalateOnSecondMiss = it)) }, onColor = colors.warmD)
            }

            TintPanel(background = colors.sage) {
                Text(tr("আপনার পরিবার যা যা বার্তা পায়, আপনি সবই দেখতে পান। সর্বশেষ পাঠানো হয়েছে গতকাল।",
                    "You can see every message your family gets. Last sent yesterday."), style = NirbhorTheme.type.body, color = colors.ink2)
            }
        }
    }
}

@Composable
private fun ChannelCard(icon: ImageVector, title: String, subtitle: String, selected: Boolean, onToggle: (CaregiverChannel) -> Unit, channel: CaregiverChannel, verifiedEmail: String? = null) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(14.dp)
    Column(
        Modifier.fillMaxWidth().clip(shape).background(colors.card)
            .border(if (selected) 2.dp else 1.5.dp, if (selected) colors.calm else colors.line, shape)
            .clickable { onToggle(channel) }.padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(46.dp).clip(RoundedCornerShape(14.dp)).background(colors.sage), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = colors.ink2, modifier = Modifier.size(24.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                Text(subtitle, style = NirbhorTheme.type.meta, color = colors.ink2)
            }
            SelIndicator(selected)
        }
        if (verifiedEmail != null) {
            Spacer(Modifier.height(10.dp))
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(11.dp)).background(colors.paper).padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(verifiedEmail, style = NirbhorTheme.type.meta.copy(fontFamily = Archivo), color = colors.ink, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                Spacer(Modifier.width(8.dp))
                Icon(Icons.Filled.Check, contentDescription = null, tint = colors.calmD, modifier = Modifier.size(16.dp))
                Text(tr("যাচাই হয়েছে", "Verified"), style = NirbhorTheme.type.statusPill, color = colors.calmD)
            }
        }
    }
}

@Composable
private fun SelIndicator(selected: Boolean) {
    val colors = NirbhorTheme.colors
    Box(
        Modifier.size(28.dp).clip(CircleShape)
            .background(if (selected) colors.calm else androidx.compose.ui.graphics.Color.Transparent)
            .border(if (selected) 0.dp else 2.dp, if (selected) androidx.compose.ui.graphics.Color.Transparent else colors.line, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (selected) Icon(Icons.Filled.Check, contentDescription = null, tint = colors.paper, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun RadioCard(title: String, subtitle: String, selected: Boolean, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(14.dp)
    Row(
        Modifier.fillMaxWidth().clip(shape).background(colors.card)
            .border(if (selected) 2.dp else 1.5.dp, if (selected) colors.calm else colors.line, shape)
            .clickable(onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
            Text(subtitle, style = NirbhorTheme.type.meta, color = colors.ink3)
        }
        Box(Modifier.size(21.dp).clip(CircleShape).border(if (selected) 6.dp else 2.dp, if (selected) colors.calm else colors.line, CircleShape))
    }
}
