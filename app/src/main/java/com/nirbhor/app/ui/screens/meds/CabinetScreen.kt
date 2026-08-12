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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.StockStatus
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.StatusPill
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Medicine cabinet (2s/2e). Main tab — the bottom nav is provided by the app root. */
@Composable
fun CabinetScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val medicines by repo.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    val stock by repo.stockStatuses().collectAsStateWithLifecycle(initialValue = emptyList())
    val stockById = remember(stock) { stock.associateBy { it.medicineId } }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        Row(
            Modifier
                .fillMaxWidth().background(colors.paper)
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(tr("ওষুধের তালিকা", "Medicines"), style = NirbhorTheme.type.titleHero, color = colors.ink)
            Spacer(Modifier.width(10.dp))
            Box(Modifier.clip(RoundedCornerShape(9.dp)).background(colors.sage).padding(horizontal = 10.dp, vertical = 4.dp)) {
                Text(num(medicines.size), style = NirbhorTheme.type.statusPill, color = colors.ink2)
            }
        }

        LazyColumn(
            Modifier.weight(1f).fillMaxWidth().padding(horizontal = Dimens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(Dimens.cardGap),
        ) {
            items(medicines, key = { it.id }) { med ->
                MedicineRow(med, stockById[med.id]) { actions.openMedicine(med.id) }
            }
            item { Spacer(Modifier.size(8.dp)) }
        }

        Column(
            Modifier.fillMaxWidth().padding(horizontal = Dimens.screenPadding).padding(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            PrimaryButton(tr("ওষুধ যোগ করুন", "Add a medicine"), actions::startAddMedicine, height = 60.dp, modifier = Modifier.fillMaxWidth())
            SecondaryButton(tr("পাতা বা বাক্স স্ক্যান করুন", "Scan a pack or box"), actions::startScan, height = 60.dp, modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun MedicineRow(med: Medicine, stock: StockStatus?, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    NbCard(onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(colors.calmSoft),
                contentAlignment = Alignment.Center,
            ) {
                MedicineMark(shape = med.mark, color = Color(med.markColor), size = 27.dp)
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(med.displayName, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                Text(scheduleSummary(med), style = NirbhorTheme.type.meta, color = colors.ink3)
            }
            if (stock != null && stock.isLow) {
                StatusPill(tr("${num(stock.count)}টি বাকি", "${stock.count} left"), colors.warmSoft, colors.warmD)
            } else {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = tr("ওষুধের বিস্তারিত খুলুন", "Open medicine details"),
                    tint = colors.ink3,
                    modifier = Modifier.size(24.dp),
                )
            }
        }
    }
}

@Composable
private fun scheduleSummary(med: Medicine): String {
    // Words, not clock times — e.g. "প্রতিদিন সকাল, দুপুর, রাত".
    val bangla = LocalIsBangla.current
    val blocks = med.timeTokens.map { TimeBlock.fromToken(it) }
    val frequency = when (med.frequency) {
        com.nirbhor.app.domain.Frequency.DAILY -> if (bangla) "প্রতিদিন" else "Daily"
        com.nirbhor.app.domain.Frequency.ALTERNATE -> if (bangla) "একদিন পরপর" else "Every other day"
        com.nirbhor.app.domain.Frequency.WEEKDAYS -> if (bangla) "সপ্তাহের কর্মদিবসে" else "On weekdays"
        com.nirbhor.app.domain.Frequency.WEEKLY -> if (bangla) "নির্বাচিত দিনে" else "On selected days"
    }
    val times = blocks.joinToString(", ") {
        when (it) {
            TimeBlock.MORNING -> if (bangla) "সকাল" else "morning"
            TimeBlock.NOON -> if (bangla) "দুপুর" else "afternoon"
            TimeBlock.NIGHT -> if (bangla) "রাত" else "night"
        }
    }
    return "$frequency · $times"
}
