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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.data.NirbhorRepository
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NbSwitch
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.Numerals
import com.nirbhor.app.ui.i18n.LocalIs24Hour
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.percent
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Medicine detail (5e). Identity, editable times, stock, high-risk gate, pause, remove. No red. */
@Composable
fun MedicineDetailScreen(medicineId: String, actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val medicine by repo.medicine(medicineId).collectAsStateWithLifecycle(initialValue = null)

    var adherence by remember { mutableStateOf<NirbhorRepository.AdherenceWindow?>(null) }
    LaunchedEffect(medicineId) { adherence = repo.adherenceOver(30) }

    val med = medicine
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = med?.displayName ?: tr("ওষুধ", "Medicine"), onBack = actions::back)
        if (med == null) return@Column
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            NbCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MedicineMark(shape = med.mark, color = Color(med.markColor), size = 46.dp)
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(med.displayName, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                        Text("${med.strength} · ${med.form} · ${med.condition}", style = NirbhorTheme.type.meta, color = colors.ink3)
                    }
                }
            }

            // Times
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(tr("সময়", "Times"), style = NirbhorTheme.type.sectionLabel, color = colors.ink3)
                NbCard {
                    med.timeTokens.forEachIndexed { i, token ->
                        val hhmm = med.resolvedTimes.getOrNull(i) ?: "08:00"
                        TimeRow(med, i, hhmm) { newTime ->
                            val updated = med.resolvedTimes.toMutableList()
                            while (updated.size <= i) updated.add("08:00")
                            updated[i] = newTime
                            scope.launch { repo.upsertMedicine(med.copy(resolvedTimes = updated)) }
                        }
                    }
                    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Add, contentDescription = null, tint = colors.calm, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(10.dp))
                        Text(tr("আরও একটি সময় যোগ করুন", "Add another time"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.calm)
                    }
                }
            }

            // Stock
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(tr("ঘরে আছে", "In stock"), style = NirbhorTheme.type.sectionLabel, color = colors.ink3)
                NbCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(tr("${num(med.stockCount)}টি ${med.form}", "${med.stockCount} ${med.form}"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
                        SecondaryButton(tr("সংখ্যা ঠিক করুন", "Fix count"), { scope.launch { repo.setStock(med.id, med.stockCount + 30) } }, height = 44.dp)
                    }
                    Spacer(Modifier.height(10.dp))
                    Box(Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp)).background(colors.sage)) {
                        Box(Modifier.fillMaxWidth((med.stockCount / 60f).coerceIn(0f, 1f)).height(8.dp).clip(RoundedCornerShape(4.dp)).background(colors.calm))
                    }
                }
            }

            // High-risk gate + adherence
            NbCard {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(tr("চেপে ধরে নিশ্চিত করা", "Press-and-hold to confirm"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                        Text(tr("ভুলবশত চাপ এড়াতে", "Avoids accidental taps"), style = NirbhorTheme.type.meta, color = colors.ink3)
                    }
                    NbSwitch(checked = med.highRisk, onCheckedChange = { v -> scope.launch { repo.upsertMedicine(med.copy(highRisk = v)) } })
                }
                Spacer(Modifier.height(10.dp))
                Text(
                    tr("গত ৩০ দিনে ${percent(adherence?.percent ?: 0)} সময়মতো নেওয়া হয়েছে", "${percent(adherence?.percent ?: 0)} on time over 30 days"),
                    style = NirbhorTheme.type.meta, color = colors.ink2,
                )
            }

            // Footer: pause + remove (no red).
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SecondaryButton(
                    if (med.paused) tr("আবার চালু করুন", "Resume") else tr("সাময়িক বন্ধ", "Pause"),
                    { scope.launch { repo.upsertMedicine(med.copy(paused = !med.paused)) } },
                    height = 56.dp, modifier = Modifier.weight(1f),
                )
                SecondaryButton(
                    tr("তালিকা থেকে সরান", "Remove"),
                    { scope.launch { repo.deleteMedicine(med.id); actions.back() } },
                    height = 56.dp, borderColor = colors.warm, content = colors.warmD, modifier = Modifier.weight(1f),
                )
            }
            TintPanel(background = colors.sage) {
                Text(
                    tr("নির্ভর কোনো পরামর্শ দেয় না। ওষুধ নিয়ে প্রশ্ন থাকলে ডাক্তারের সঙ্গে কথা বলুন।",
                        "Nirbhor gives no medical advice. Ask your doctor about any medicine question."),
                    style = NirbhorTheme.type.meta, color = colors.ink2,
                )
            }
        }
    }
}

@Composable
private fun TimeRow(med: Medicine, index: Int, hhmm: String, onChange: (String) -> Unit) {
    val colors = NirbhorTheme.colors
    val bangla = LocalIsBangla.current
    val is24 = LocalIs24Hour.current
    val (h, m) = remember(hhmm) { com.nirbhor.app.domain.DoseScheduler.parseHhmm(hhmm) ?: (8 to 0) }
    val block = TimeBlock.fromToken(med.timeTokens.getOrNull(index) ?: "morning")
    val label = when (block) { TimeBlock.MORNING -> tr("সকাল", "Morning"); TimeBlock.NOON -> tr("দুপুর", "Afternoon"); TimeBlock.NIGHT -> tr("রাত", "Night") }
    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
        // Tap to shift −15 / +15 min via two small affordances.
        Stepper("−") { onChange(shift(h, m, -15)) }
        Spacer(Modifier.width(10.dp))
        Text(Numerals.time(h, m, bangla, is24), style = NirbhorTheme.type.cardTitleSecondary, color = colors.calmD)
        Spacer(Modifier.width(10.dp))
        Stepper("+") { onChange(shift(h, m, +15)) }
    }
}

@Composable
private fun Stepper(label: String, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    Box(
        Modifier.size(36.dp).clip(RoundedCornerShape(10.dp)).background(colors.sage).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Text(label, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink2) }
}

private fun shift(h: Int, m: Int, delta: Int): String {
    var total = (h * 60 + m + delta + 24 * 60) % (24 * 60)
    return "%02d:%02d".format(total / 60, total % 60)
}
