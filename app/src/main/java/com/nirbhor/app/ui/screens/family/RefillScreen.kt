package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.StockStatus
import com.nirbhor.app.domain.StockCalculator
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.QuantityStepper
import com.nirbhor.app.ui.components.QuickChip
import com.nirbhor.app.ui.components.Scrim
import com.nirbhor.app.ui.components.SectionLabel
import com.nirbhor.app.ui.components.SheetSurface
import com.nirbhor.app.ui.components.StatusPill
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Refill & stock (2u/2g) with the restock sheet (6e). */
@Composable
fun RefillScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val medicines by repo.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    val stock by repo.stockStatuses().collectAsStateWithLifecycle(initialValue = emptyList())
    val stockById = remember(stock) { stock.associateBy { it.medicineId } }

    var restockFor by remember { mutableStateOf<Medicine?>(null) }
    val lowest = medicines.minByOrNull { stockById[it.id]?.daysRemaining ?: Int.MAX_VALUE }
    val lowestStock = lowest?.let { stockById[it.id] }

    Box(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().background(colors.paper)) {
            NirbhorTopBar(title = tr("রিফিল ও মজুত", "Refill & stock"), onBack = actions::back)
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                    .navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
            ) {
                if (lowest != null && lowestStock != null && lowestStock.isLow) {
                    LowAlertCard(lowest, lowestStock) { restockFor = lowest }
                }
                Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
                    if (medicines.isEmpty()) {
                        Text(tr("এখনও কোনো ওষুধ যোগ করা হয়নি।", "No medicines have been added yet."), style = NirbhorTheme.type.body, color = colors.ink2)
                        PrimaryButton(tr("ওষুধ যোগ করুন", "Add a medicine"), actions::startAddMedicine, modifier = Modifier.fillMaxWidth())
                    } else {
                        medicines.forEach { m -> StockRow(m, stockById[m.id]) { restockFor = m } }
                    }
                }
                TintPanel(background = colors.sage) {
                    Text(
                        tr("প্রতিটি ওষুধ কত দিন চলবে তা রোজ হিসাব করা হয়। ৫ দিনের কম থাকলে সতর্কবার্তা যায়।",
                            "Days remaining is recalculated daily. You're warned when fewer than 5 days are left."),
                        style = NirbhorTheme.type.body, color = colors.ink2,
                    )
                }
            }
        }

        val target = restockFor
        if (target != null) {
            Scrim(onDismiss = { restockFor = null })
            Box(Modifier.align(Alignment.BottomCenter)) {
                RestockSheet(
                    medicine = target,
                    current = stockById[target.id]?.count ?: 0,
                    onAdd = { amount ->
                        scope.launch { repo.addStock(target.id, amount) }
                        restockFor = null
                    },
                )
            }
        }
    }
}

@Composable
private fun LowAlertCard(med: Medicine, stock: StockStatus, onRestock: () -> Unit) {
    val colors = NirbhorTheme.colors
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusLargeCard)).background(colors.warmSoft)
            .border(1.dp, colors.warm.copy(alpha = 0.28f), RoundedCornerShape(Dimens.radiusLargeCard)).padding(16.dp),
    ) {
        SectionLabel(tr("ফুরিয়ে আসছে", "Running low"), color = colors.warmD)
        Spacer(Modifier.height(10.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            MedicineMark(shape = med.mark, color = Color(med.markColor), size = 34.dp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(med.displayName, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                Text(
                    tr("${num(stock.count)}টি ${med.form} বাকি · ${num(stock.daysRemaining)} দিন চলবে",
                        "${stock.count} ${med.form} left · ${stock.daysRemaining} days"),
                    style = NirbhorTheme.type.meta, color = colors.warmD,
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        SegmentBar(filled = stock.count.coerceIn(0, 10))
        Spacer(Modifier.height(12.dp))
        PrimaryButton(
            tr("আরও কিনেছি", "Bought more"), onRestock, height = 58.dp,
            container = colors.warmD, content = colors.paper, modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun SegmentBar(filled: Int) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        repeat(10) { i ->
            Box(
                Modifier.weight(1f).height(12.dp).clip(RoundedCornerShape(6.dp))
                    .background(if (i < filled) colors.warm else colors.warm.copy(alpha = 0.2f)),
            )
        }
    }
}

@Composable
private fun StockRow(med: Medicine, stock: StockStatus?, onRestock: () -> Unit) {
    val colors = NirbhorTheme.colors
    val days = stock?.daysRemaining ?: 0
    val low = stock?.isLow == true
    NbCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MedicineMark(shape = med.mark, color = Color(med.markColor), size = 32.dp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(med.displayName, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                Text(
                    tr("${num(stock?.count ?: 0)}টি ${med.form} · ${num(days)} দিন চলবে",
                        "${stock?.count ?: 0} ${med.form} · ${days} days"),
                    style = NirbhorTheme.type.meta, color = colors.ink3,
                )
            }
            if (low) StatusPill(tr("শীঘ্রই", "Soon"), colors.warmSoft, colors.warmD)
            else StatusPill(tr("ঠিক আছে", "OK"), colors.calmSoft, colors.calmD)
        }
        Spacer(Modifier.height(10.dp))
        Box(Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp)).background(colors.sage)) {
            val frac = (days / 30f).coerceIn(0f, 1f)
            Box(Modifier.fillMaxWidth(frac).height(8.dp).clip(RoundedCornerShape(4.dp)).background(if (low) colors.warm else colors.calm))
        }
        Spacer(Modifier.height(10.dp))
        PrimaryButton(tr("মজুত আপডেট করুন", "Update stock"), onRestock, height = 48.dp, modifier = Modifier.fillMaxWidth())
    }
}

@Composable
private fun RestockSheet(medicine: Medicine, current: Int, onAdd: (Int) -> Unit) {
    val colors = NirbhorTheme.colors
    var amount by remember { mutableFloatStateOf(30f) }
    SheetSurface {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            MedicineMark(shape = medicine.mark, color = Color(medicine.markColor), size = 34.dp)
            Spacer(Modifier.width(12.dp))
            Text(medicine.displayName, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
        }
        Spacer(Modifier.height(16.dp))
        QuantityStepper(
            value = amount, onChange = { amount = it },
            valueLabel = num(amount.toInt()), unitLabel = tr("টি যোগ করুন", "to add"),
            size = 72.dp, step = 1f,
        )
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(10, 30, 60, 90).forEach { q ->
                QuickChip(num(q), selected = amount.toInt() == q, onClick = { amount = q.toFloat() }, modifier = Modifier.weight(1f))
            }
        }
        Spacer(Modifier.height(14.dp))
        val result = current + amount.toInt()
        val days = StockCalculator.estimatedDays(
            result, medicine.dosePerIntake, medicine.timeTokens.size,
            medicine.frequency, medicine.weekdaysMask, medicine.paused,
        )
        TintPanel(background = colors.calmSoft) {
            Text(
                if (days == null) tr("ঘরে হবে ${num(result)}টি — ওষুধটি এখন বন্ধ আছে।", "You'll have $result — this medicine is paused.")
                else tr("ঘরে হবে ${num(result)}টি — প্রায় ${num(days)} দিন চলবে।", "You'll have ${result} — about ${days} days."),
                style = NirbhorTheme.type.body, color = colors.calmD,
            )
        }
        Spacer(Modifier.height(14.dp))
        PrimaryButton(tr("যোগ করুন", "Add"), { onAdd(amount.toInt()) }, height = 64.dp, modifier = Modifier.fillMaxWidth())
    }
}
