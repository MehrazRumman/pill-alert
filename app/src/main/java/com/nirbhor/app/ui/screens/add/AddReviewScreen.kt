package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.FoodRelation
import com.nirbhor.app.domain.Frequency
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.notifications.AlarmScheduler
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.Numerals
import com.nirbhor.app.ui.i18n.LocalIs24Hour
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Plain-language review (3e). Confirms everything, shows a live alarm preview, saves the medicine. */
@Composable
fun AddReviewScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val draft = LocalAddDraft.current
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val existing by container.repository.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    val duplicate = existing.any { it.displayName == draft.displayName && it.strength == draft.strength }
    var saving by remember { mutableStateOf(false) }

    val bangla = LocalIsBangla.current
    val is24 = LocalIs24Hour.current

    val whenWords = draft.timeTokens.joinToString(", ") {
        when (TimeBlock.fromToken(it)) {
            TimeBlock.MORNING -> if (bangla) "সকাল" else "morning"
            TimeBlock.NOON -> if (bangla) "দুপুর" else "afternoon"
            TimeBlock.NIGHT -> if (bangla) "রাত" else "night"
        }
    }
    val foodWords = when (draft.foodRelation) {
        FoodRelation.BEFORE -> tr("খাবারের আগে", "before food"); FoodRelation.AFTER -> tr("খাবারের পরে", "after food"); FoodRelation.NONE -> tr("যেকোনো সময়", "any time")
    }
    val frequencyWords = when (draft.frequency) {
        Frequency.DAILY -> tr("প্রতিদিন", "Daily")
        Frequency.ALTERNATE -> tr("একদিন পরপর", "Every other day")
        Frequency.WEEKDAYS -> tr("কর্মদিবসে", "Weekdays")
        Frequency.WEEKLY -> tr("নির্বাচিত দিনে", "Selected days")
    }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        AddFlowHeader(step = 3, onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            Box(Modifier.size(64.dp).clip(RoundedCornerShape(18.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Check, null, tint = colors.calmD, modifier = Modifier.size(34.dp))
            }
            Text(tr("একবার মিলিয়ে নিন", "Just double-check"), style = NirbhorTheme.type.titleHero, color = colors.ink)

            if (duplicate) {
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusCard)).background(colors.card)
                        .padding(1.dp),
                ) {
                    TintPanel(background = colors.warmSoft) {
                        Text(tr("একই নামের ওষুধ আগে থেকেই আছে", "A medicine with this name already exists"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.warmD)
                        Spacer(Modifier.height(4.dp))
                        Text(tr("নির্ভর পরামর্শ দেয় না — দিনে তিনবারও ঠিক হতে পারে। প্রয়োজনে ডাক্তারকে জিজ্ঞেস করুন।",
                            "Nirbhor gives no advice — three times daily can be correct. Ask your doctor if unsure."), style = NirbhorTheme.type.meta, color = colors.ink2)
                    }
                }
            }

            NbCard(padding = 0.dp) {
                Row(Modifier.fillMaxWidth().background(colors.calmSoft).padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    MedicineMark(draft.mark, Color(draft.markColor), size = 42.dp)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(draft.displayName.ifBlank { tr("নতুন ওষুধ", "New medicine") }, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                        Text("${draft.strength} · ${draft.form}", style = NirbhorTheme.type.meta, color = colors.ink3)
                    }
                }
                ReviewRow(tr("কখন", "When"), "$whenWords · $foodWords")
                ReviewRow(tr("কত ঘন ঘন", "Frequency"), frequencyWords)
                ReviewRow(tr("কতটা", "How much"), "${Numerals.quantity(draft.dosePerIntake, bangla)} ${draft.form}")
                if (draft.stockCount > 0) ReviewRow(tr("ঘরে আছে", "In stock"), tr("${num(draft.stockCount)}টি", "${draft.stockCount}"))
            }

            // Live alarm preview.
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusLargeCard)).background(colors.calmD).padding(18.dp)) {
                Text(tr("অ্যালার্মে এমন দেখাবে", "The alarm will look like this"), style = NirbhorTheme.type.meta, color = colors.alarmText.copy(alpha = 0.7f))
                Spacer(Modifier.height(8.dp))
                val (firstHour, firstMinute) = draft.resolvedTimes.firstOrNull()
                    ?.let(com.nirbhor.app.domain.DoseScheduler::parseHhmm) ?: (8 to 0)
                Text(Numerals.time(firstHour, firstMinute, bangla, is24), style = NirbhorTheme.type.header, color = colors.alarmText)
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 8.dp)) {
                    MedicineMark(draft.mark, colors.markCalmOnDark, size = 34.dp)
                    Spacer(Modifier.width(12.dp))
                    Text(draft.displayName.ifBlank { "—" }, style = NirbhorTheme.type.alarmName, color = colors.alarmText)
                }
            }

            PrimaryButton(
                tr("যোগ করুন", "Add medicine"),
                {
                    if (saving) return@PrimaryButton
                    saving = true
                    scope.launch {
                        try {
                            container.repository.upsertMedicine(draft.toMedicine())
                            AlarmScheduler.rescheduleAll(context.applicationContext)
                            draft.reset()
                            actions.finishAddMedicine()
                        } finally {
                            saving = false
                        }
                    }
                },
                height = 68.dp,
                enabled = !saving && draft.displayName.isNotBlank() && draft.timeTokens.isNotEmpty(),
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
        }
    }
}

@Composable
private fun ReviewRow(label: String, value: String) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = NirbhorTheme.type.meta, color = colors.ink3, modifier = Modifier.width(84.dp))
        Text(value, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
    }
}
