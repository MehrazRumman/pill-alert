package com.nirbhor.app.ui.screens

import android.content.Intent
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.AlertLogItem
import com.nirbhor.app.domain.Caregiver
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NbSwitch
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.StatusPill
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Archivo
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Family & caregivers (2v/2h). */
@Composable
fun FamilyScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var inviteCode by rememberSaveable { mutableStateOf(newInviteCode()) }
    val caregiver by repo.primaryCaregiver.collectAsStateWithLifecycle(initialValue = null)
    val alerts by repo.alertLog().collectAsStateWithLifecycle(initialValue = emptyList())

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("পরিবার ও যত্নকারী", "Family & caregivers"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            val cg = caregiver
            if (cg != null) {
                NbCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(52.dp).clip(RoundedCornerShape(16.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
                            Text(cg.name.take(1), style = NirbhorTheme.type.header, color = colors.calmD)
                        }
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Text(cg.name, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                            Text("${cg.relationship} · ${cg.phone}", style = NirbhorTheme.type.meta.copy(fontFamily = Archivo), color = colors.ink3)
                        }
                        StatusPill(tr("সক্রিয়", "Active"), colors.calmSoft, colors.calmD)
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(tr("তাকে জানানো হবে যখন", "They'll be told when"), style = NirbhorTheme.type.sectionLabel, color = colors.ink3)
                    NbCard {
                        ToggleLine(tr("পরপর দুবার বাদ পড়লে", "Missed twice in a row"), cg.notifyOnMissedTwice) { v ->
                            scope.launch { repo.upsertCaregiver(cg.copy(notifyOnMissedTwice = v)) }
                        }
                        ToggleLine(tr("ওষুধ ফুরিয়ে গেলে", "Out of stock"), cg.notifyOnOutOfStock) { v ->
                            scope.launch { repo.upsertCaregiver(cg.copy(notifyOnOutOfStock = v)) }
                        }
                        ToggleLine(tr("সাপ্তাহিক হিসাব", "Weekly summary"), cg.weeklySummary) { v ->
                            scope.launch { repo.upsertCaregiver(cg.copy(weeklySummary = v)) }
                        }
                    }
                    SecondaryButton(tr("কীভাবে জানানো হবে ঠিক করুন", "Choose how they're told"), actions::openCaregiverNotify, height = 52.dp, modifier = Modifier.fillMaxWidth())
                }
            }

            // Invite block.
            TintPanel(background = colors.calmSoft, radius = Dimens.radiusLargeCard) {
                Text(tr("নতুন কাউকে যুক্ত করুন", "Invite someone new"), style = NirbhorTheme.type.cardTitlePrimary, color = colors.calmD)
                Spacer(Modifier.height(4.dp))
                Text(tr("এই কোডটি তাদের অ্যাপে দিতে বলুন", "Ask them to enter this code in their app"), style = NirbhorTheme.type.meta, color = colors.ink2)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    inviteCode.forEach { c ->
                        Box(Modifier.size(52.dp, 60.dp).clip(RoundedCornerShape(12.dp)).background(colors.card), contentAlignment = Alignment.Center) {
                            Text(c.toString(), fontSize = 28.sp, fontWeight = FontWeight(700), fontFamily = Archivo, color = colors.ink)
                        }
                    }
                }
                Spacer(Modifier.height(6.dp))
                Text(tr("কোডটি ২৪ ঘণ্টা কার্যকর থাকবে", "The code works for 24 hours"), style = NirbhorTheme.type.meta, color = colors.ink3)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    PrimaryButton(
                        tr("কোড পাঠান", "Send code"),
                        {
                            val message = if (context.resources.configuration.locales[0].language == "bn") {
                                "নির্ভরে যুক্ত হতে এই কোডটি দিন: $inviteCode"
                            } else {
                                "Use this code to connect in Nirbhor: $inviteCode"
                            }
                            context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, message)
                            }, null))
                        },
                        height = 52.dp, modifier = Modifier.weight(1f),
                    )
                    SecondaryButton(tr("নতুন কোড", "New code"), { inviteCode = newInviteCode() }, height = 52.dp, modifier = Modifier.width(112.dp))
                }
            }

            if (alerts.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(tr("সাম্প্রতিক বার্তা", "Recent alerts"), style = NirbhorTheme.type.sectionLabel, color = colors.ink3)
                    NbCard {
                        alerts.forEach { AlertLine(it) }
                    }
                }
            }
        }
    }
}

private fun newInviteCode(): String {
    val alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return buildString(4) { repeat(4) { append(alphabet.random()) } }
}

@Composable
private fun ToggleLine(title: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth().padding(vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
        NbSwitch(checked = checked, onCheckedChange = onChange)
    }
}

@Composable
private fun AlertLine(item: AlertLogItem) {
    val colors = NirbhorTheme.colors
    val dot = if (item.kind == "missed") colors.warm else colors.calm
    Row(Modifier.fillMaxWidth().padding(vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(9.dp).clip(CircleShape).background(dot))
        Spacer(Modifier.width(12.dp))
        Text(item.message, style = NirbhorTheme.type.meta, color = colors.ink2, modifier = Modifier.weight(1f))
        Text(item.outcome, style = NirbhorTheme.type.meta, color = colors.ink3)
    }
}
