package com.nirbhor.app.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nirbhor.app.data.NirbhorRepository
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.ProgressRing
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.SegmentedControl
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.percent
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Adherence record (2t/2f): donut summary, day grid, per-medicine bars, PDF export. */
@Composable
fun RecordScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    var weekly by remember { mutableStateOf(true) }
    val days = if (weekly) 7 else 30

    var window by remember { mutableStateOf<NirbhorRepository.AdherenceWindow?>(null) }
    var cells by remember { mutableStateOf<List<NirbhorRepository.DayCell>>(emptyList()) }
    var perMed by remember { mutableStateOf<List<NirbhorRepository.MedAdherence>>(emptyList()) }
    LaunchedEffect(days) {
        window = repo.adherenceOver(days)
        cells = repo.dayCells(days)
        perMed = repo.perMedicineAdherence(days)
    }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        Row(
            Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = Dimens.screenPadding, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(tr("রেকর্ড", "Record"), style = NirbhorTheme.type.titleHero, color = colors.ink, modifier = Modifier.weight(1f))
            Box(Modifier.width(160.dp)) {
                SegmentedControl(
                    options = listOf(tr("সপ্তাহ", "Week"), tr("মাস", "Month")),
                    selectedIndex = if (weekly) 0 else 1,
                    onSelect = { weekly = it == 0 },
                )
            }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = Dimens.screenPadding).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            SummaryCard(window)
            DayGrid(cells)
            perMed.filter { it.total > 0 }.forEach { MedBar(it) }
            SecondaryButton(
                tr("ডাক্তারের জন্য পিডিএফ বানান", "Make a PDF for the doctor"),
                actions::openDoctorReport, height = 50.dp, modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun SummaryCard(w: NirbhorRepository.AdherenceWindow?) {
    val colors = NirbhorTheme.colors
    NbCard(padding = 13.dp) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ProgressRing(
                fraction = (w?.percent ?: 0) / 100f, diameter = 74.dp, strokeWidth = 8.dp,
                center = { Text(percent(w?.percent ?: 0), fontSize = 20.sp, fontWeight = FontWeight(700), color = colors.calmD) },
            )
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                val pct = w?.percent ?: 0
                Text(
                    if (pct >= 90) tr("বেশ ভালো চলছে", "Going well")
                    else if (pct >= 70) tr("মোটামুটি চলছে", "Fairly steady")
                    else tr("আরও যত্ন দরকার", "Needs more care"),
                    style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink,
                )
                Text(
                    if ((w?.missed ?: 0) == 0) tr("এই সময়ে কোনো ডোজ বাদ পড়েনি।", "No doses were missed in this period.")
                    else tr("এই সময়ে ${num(w?.missed ?: 0)}টি ডোজ বাদ পড়েছে।", "${w?.missed ?: 0} doses were missed in this period."),
                    style = NirbhorTheme.type.meta, color = colors.ink2,
                )
            }
        }
    }
}

private val bnWeekHeaders = listOf("সোম", "মঙ্গল", "বুধ", "বৃহ", "শুক্র", "শনি", "রবি")
private val enWeekHeaders = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

@Composable
private fun DayGrid(cells: List<NirbhorRepository.DayCell>) {
    val colors = NirbhorTheme.colors
    val bangla = LocalIsBangla.current
    val headers = if (bangla) bnWeekHeaders else enWeekHeaders
    val today = java.time.LocalDate.now()

    NbCard(padding = 13.dp) {
        Row(Modifier.fillMaxWidth()) {
            headers.forEach { h ->
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    Text(h, fontSize = 12.sp, color = colors.ink3)
                }
            }
        }
        Spacer(Modifier.height(6.dp))
        // Chunk cells into weeks of 7. Pad the first week so weekday columns align (Mon=0).
        val firstDow = cells.firstOrNull()?.date?.dayOfWeek?.value?.minus(1) ?: 0
        val padded = List(firstDow) { null } + cells
        padded.chunked(7).forEach { week ->
            Row(Modifier.fillMaxWidth().padding(vertical = 3.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for (i in 0 until 7) {
                    val cell = week.getOrNull(i)
                    Box(Modifier.weight(1f).aspectRatio(1f)) {
                        if (cell != null) DayCellView(cell, isToday = cell.date == today)
                    }
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            LegendSwatch(colors.calm, tr("সব নেওয়া", "All taken"))
            LegendSwatch(colors.warm, tr("বাদ", "Missed"))
            LegendSwatch(colors.sage, tr("বাকি", "Future"))
        }
    }
}

@Composable
private fun DayCellView(cell: NirbhorRepository.DayCell, isToday: Boolean) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(9.dp)
    Box(
        Modifier.fillMaxSize().clip(shape)
            .background(
                when (cell.state) {
                    NirbhorRepository.DayState.FULL -> colors.calm
                    NirbhorRepository.DayState.MISSED -> colors.warm
                    else -> colors.sage
                }
            ),
    ) {
        if (cell.state == NirbhorRepository.DayState.PARTIAL) {
            // 135° diagonal split: calm top-left triangle over the sage base.
            Canvas(Modifier.fillMaxSize()) {
                val p = Path().apply {
                    moveTo(0f, 0f); lineTo(size.width, 0f); lineTo(0f, size.height); close()
                }
                drawPath(p, colors.calm)
            }
        }
        if (isToday) {
            Canvas(Modifier.fillMaxSize()) {
                drawRoundRect(
                    color = colors.ink, style = Stroke(width = 2.5.dp.toPx()),
                    topLeft = Offset(-2.dp.toPx(), -2.dp.toPx()),
                    size = androidx.compose.ui.geometry.Size(size.width + 4.dp.toPx(), size.height + 4.dp.toPx()),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(9.dp.toPx(), 9.dp.toPx()),
                )
            }
        }
    }
}

@Composable
private fun LegendSwatch(color: Color, label: String) {
    val colors = NirbhorTheme.colors
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(12.dp).clip(RoundedCornerShape(4.dp)).background(color))
        Spacer(Modifier.width(5.dp))
        Text(label, style = NirbhorTheme.type.meta, color = colors.ink3)
    }
}

@Composable
private fun MedBar(m: NirbhorRepository.MedAdherence) {
    val colors = NirbhorTheme.colors
    val good = m.percent >= 80
    Row(verticalAlignment = Alignment.CenterVertically) {
        MedicineMark(shape = m.medicine.mark, color = Color(m.medicine.markColor), size = 20.dp)
        Spacer(Modifier.width(10.dp))
        Text(m.medicine.displayName, style = NirbhorTheme.type.meta, color = colors.ink2, modifier = Modifier.width(96.dp))
        Spacer(Modifier.width(8.dp))
        Box(Modifier.weight(1f).height(9.dp).clip(RoundedCornerShape(5.dp)).background(colors.sage)) {
            Box(
                Modifier.fillMaxWidth(m.percent / 100f).height(9.dp).clip(RoundedCornerShape(5.dp))
                    .background(if (good) colors.calm else colors.warm),
            )
        }
        Spacer(Modifier.width(8.dp))
        Text(percent(m.percent), style = NirbhorTheme.type.meta, color = colors.ink2)
    }
}
