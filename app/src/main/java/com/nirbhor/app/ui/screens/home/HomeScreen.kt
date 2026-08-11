package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Brightness5
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.WbSunny
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.DoseWithMedicine
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.StockStatus
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.domain.TimelineBlock
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.notifications.AlarmScheduler
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.ProgressRing
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.StatusPill
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.UndoToast
import com.nirbhor.app.ui.components.UrgentCard
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.i18n.Numerals
import com.nirbhor.app.ui.i18n.clock
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalTime

/** Home — the time-blocked timeline (2j/2b), plus its empty (4d), day-complete (6f) and undo (4f) states. */
@Composable
fun HomeScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var today by remember { mutableStateOf(LocalDate.now()) }
    var currentTime by remember { mutableStateOf(LocalTime.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            val currentDate = LocalDate.now()
            repo.ensureDosesFor(currentDate)
            repo.markOverdueDoses()
            today = currentDate
            currentTime = LocalTime.now()
            delay(60_000L)
        }
    }
    val blocks by repo.timelineFor(today).collectAsStateWithLifecycle(initialValue = emptyList())
    val medicines by repo.medicines.collectAsStateWithLifecycle(initialValue = emptyList())
    val stock by repo.stockStatuses().collectAsStateWithLifecycle(initialValue = emptyList())
    val stockById = remember(stock) { stock.associateBy { it.medicineId } }

    var lastTaken by remember { mutableStateOf<DoseWithMedicine?>(null) }
    LaunchedEffect(lastTaken) {
        if (lastTaken != null) {
            delay(5000)
            lastTaken = null
        }
    }

    val total = blocks.sumOf { it.doses.size }
    val taken = blocks.sumOf { b -> b.doses.count { it.dose.status == DoseStatus.TAKEN || it.dose.status == DoseStatus.TAKEN_LATE } }
    val allDone = total > 0 && taken == total

    Box(Modifier.fillMaxSize().background(colors.paper)) {
        Column(Modifier.fillMaxSize()) {
            HomeHeader(now = currentTime, today = today, onBell = actions::openInbox)
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = Dimens.screenPadding)
                    .padding(top = 16.dp, bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
            ) {
                when {
                    medicines.isEmpty() -> EmptyHome(actions)
                    allDone -> DayComplete(taken)
                    else -> {
                        ProgressSummary(taken, total)
                        blocks.forEach { block ->
                            TimeBlockSection(
                                block = block,
                                now = currentTime,
                                stockById = stockById,
                                onTaken = { dwm ->
                                    scope.launch { repo.markTaken(dwm.dose.id) }
                                    lastTaken = dwm
                                },
                                onSnooze = { dwm ->
                                    scope.launch {
                                        repo.snoozeDose(dwm.dose.id)
                                        AlarmScheduler.rescheduleAll(context.applicationContext)
                                    }
                                },
                                onSkip = { dwm -> scope.launch { repo.skipDose(dwm.dose.id) } },
                            )
                        }
                    }
                }
            }
        }

        val toastMed = lastTaken
        if (toastMed != null) {
            Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 16.dp)) {
                UndoToast(
                    message = tr("${toastMed.medicine.displayName} খাওয়া হয়েছে", "${toastMed.medicine.displayName} taken"),
                    actionLabel = tr("ফিরিয়ে নিন", "Undo"),
                    onAction = {
                        scope.launch { repo.undoTaken(toastMed.dose.id) }
                        lastTaken = null
                    },
                )
            }
        }
    }
}

@Composable
private fun HomeHeader(now: LocalTime, today: LocalDate, onBell: () -> Unit) {
    val colors = NirbhorTheme.colors
    val bangla = LocalIsBangla.current
    val hour = now.hour
    val greeting = when {
        hour < 12 -> tr("সুপ্রভাত", "Good morning")
        else -> tr("শুভ সন্ধ্যা", "Good evening")
    }
    Column(Modifier.fillMaxWidth().background(colors.card)) {
        Row(
            Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = Dimens.screenPadding, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(greeting, style = NirbhorTheme.type.header, color = colors.ink)
                Text(dateString(today, bangla), style = NirbhorTheme.type.meta, color = colors.ink3)
            }
            Box(
                Modifier.size(42.dp).clip(RoundedCornerShape(12.dp)).background(colors.sage).clickable(onClick = onBell),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Notifications, contentDescription = "Notifications", tint = colors.ink2, modifier = Modifier.size(21.dp))
                Box(
                    Modifier.align(Alignment.TopEnd).padding(9.dp).size(8.dp).clip(CircleShape).background(colors.warm),
                )
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.line))
    }
}

@Composable
private fun ProgressSummary(taken: Int, total: Int) {
    val colors = NirbhorTheme.colors
    TintPanel(background = colors.calmSoft, radius = Dimens.radiusCard) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ProgressRing(fraction = if (total == 0) 0f else taken.toFloat() / total, diameter = 46.dp)
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    tr("${num(total)}টির মধ্যে ${num(taken)}টি ডোজ নেওয়া হয়েছে", "$taken of $total doses taken"),
                    style = NirbhorTheme.type.cardTitleSecondary, color = colors.calmD,
                )
                val remaining = (total - taken).coerceAtLeast(0)
                Text(
                    tr("আর ${num(remaining)}টি বাকি", "$remaining to go"),
                    style = NirbhorTheme.type.meta, color = colors.ink2,
                )
            }
        }
    }
}

private enum class BlockState { DONE, DUE, UPCOMING }

@Composable
private fun TimeBlockSection(
    block: TimelineBlock,
    now: LocalTime,
    stockById: Map<String, StockStatus>,
    onTaken: (DoseWithMedicine) -> Unit,
    onSnooze: (DoseWithMedicine) -> Unit,
    onSkip: (DoseWithMedicine) -> Unit,
) {
    val colors = NirbhorTheme.colors
    val blockTime = LocalTime.of(block.hour, block.minute)
    val state = when {
        block.allTaken -> BlockState.DONE
        !now.isBefore(blockTime) -> BlockState.DUE
        else -> BlockState.UPCOMING
    }
    val (icon, labelBn, labelEn) = blockMeta(block.block)

    Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = if (state == BlockState.DONE) colors.ink3 else colors.ink2, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(8.dp))
            Text(tr(labelBn, labelEn), style = NirbhorTheme.type.cardTitleSecondary, color = if (state == BlockState.DONE) colors.ink3 else colors.ink)
            Spacer(Modifier.width(8.dp))
            Text(clock(block.hour, block.minute), style = NirbhorTheme.type.meta, color = colors.ink3)
            Spacer(Modifier.weight(1f))
            when (state) {
                BlockState.DONE -> Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Check, null, tint = colors.calm, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(tr("শেষ", "Done"), style = NirbhorTheme.type.statusPill, color = colors.calm)
                }
                BlockState.DUE -> StatusPill(tr("এখন সময়", "DUE NOW"), colors.warm, colors.paper)
                BlockState.UPCOMING -> {}
            }
        }
        block.doses.forEach { dwm ->
            val ss = stockById[dwm.medicine.id]
            val low = ss?.let { it.isLow && dwm.dose.status == DoseStatus.UPCOMING } ?: false
            DoseCard(
                dwm = dwm,
                due = state == BlockState.DUE && dwm.dose.status == DoseStatus.UPCOMING,
                lowStock = low,
                lowCount = ss?.count ?: 0,
                onTaken = { onTaken(dwm) },
                onSnooze = { onSnooze(dwm) },
                onSkip = { onSkip(dwm) },
            )
        }
    }
}

@Composable
private fun DoseCard(
    dwm: DoseWithMedicine,
    due: Boolean,
    lowStock: Boolean,
    lowCount: Int,
    onTaken: () -> Unit,
    onSnooze: () -> Unit,
    onSkip: () -> Unit,
) {
    val colors = NirbhorTheme.colors
    val med = dwm.medicine
    val taken = dwm.dose.status == DoseStatus.TAKEN || dwm.dose.status == DoseStatus.TAKEN_LATE
    val missed = dwm.dose.status == DoseStatus.MISSED
    val skipped = dwm.dose.status == DoseStatus.SKIPPED

    if (due) {
        UrgentCard(padding = 16.dp) {
            DoseIdentity(dwm, titleStyle = NirbhorTheme.type.cardTitlePrimary)
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                if (med.highRisk) {
                    HoldToConfirmButton(onLongPress = onTaken, modifier = Modifier.weight(1f))
                } else {
                    PrimaryButton(text = tr("খেয়েছি", "Taken"), onClick = onTaken, height = Dimens.doseConfirm, modifier = Modifier.weight(1f))
                }
                SquareAction(Icons.Filled.Schedule, onSnooze)
                SquareAction(Icons.Filled.Remove, onSkip)
            }
        }
    } else {
        val rowAlpha = if (taken || skipped) 0.62f else 1f
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Dimens.radiusCard))
                .background(colors.card)
                .padding(Dimens.cardPadding)
                .alpha(rowAlpha),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (missed) {
                Box(Modifier.width(4.dp).height(40.dp).clip(RoundedCornerShape(2.dp)).background(colors.warm))
                Spacer(Modifier.width(12.dp))
            }
            StatusTile(taken = taken, med = med)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    med.displayName,
                    style = NirbhorTheme.type.cardTitleSecondary,
                    color = colors.ink,
                    textDecoration = if (taken) TextDecoration.LineThrough else null,
                )
                val sub = when {
                    taken -> tr("নেওয়া হয়েছে", "Taken")
                    missed -> tr("বাদ পড়েছে", "Missed")
                    skipped -> tr("আজ খাব না", "Skipped")
                    else -> "${med.strength} · ${med.form}"
                }
                Text(sub, style = NirbhorTheme.type.meta, color = if (missed) colors.warmD else colors.ink3)
                if (lowStock) {
                    Text(tr("ঘরে আর ${num(lowCount)}টি আছে", "$lowCount left at home"), style = NirbhorTheme.type.meta, color = colors.warmD)
                }
            }
        }
    }
}

@Composable
private fun HoldToConfirmButton(onLongPress: () -> Unit, modifier: Modifier = Modifier) {
    val colors = NirbhorTheme.colors
    Box(
        modifier.heightIn(min = Dimens.doseConfirm).clip(RoundedCornerShape(Dimens.radiusButton))
            .background(colors.calm)
            .combinedClickable(
                role = Role.Button,
                onClick = {},
                onLongClick = onLongPress,
                onLongClickLabel = tr("চেপে ধরে নিশ্চিত করুন", "Hold to confirm"),
            ).padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(tr("চেপে ধরুন", "Hold to confirm"), style = NirbhorTheme.type.buttonLabel, color = colors.paper)
    }
}

@Composable
private fun DoseIdentity(dwm: DoseWithMedicine, titleStyle: TextStyle) {
    val colors = NirbhorTheme.colors
    Row(verticalAlignment = Alignment.CenterVertically) {
        MedicineMark(shape = dwm.medicine.mark, color = Color(dwm.medicine.markColor), size = 34.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(dwm.medicine.displayName, style = titleStyle, color = colors.ink)
            Text("${dwm.medicine.strength} · ${dwm.medicine.form}", style = NirbhorTheme.type.meta, color = colors.ink3)
        }
    }
}

@Composable
private fun StatusTile(taken: Boolean, med: Medicine) {
    val colors = NirbhorTheme.colors
    if (taken) {
        Box(Modifier.size(38.dp).clip(RoundedCornerShape(10.dp)).background(colors.calm), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Check, null, tint = colors.paper, modifier = Modifier.size(22.dp))
        }
    } else {
        MedicineMark(shape = med.mark, color = Color(med.markColor), size = 34.dp)
    }
}

@Composable
private fun SquareAction(icon: ImageVector, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    Box(
        Modifier.size(Dimens.doseConfirm).clip(RoundedCornerShape(Dimens.radiusButton))
            .background(colors.card).border(1.5.dp, colors.line, RoundedCornerShape(Dimens.radiusButton)).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = colors.ink2, modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun DayComplete(taken: Int) {
    val colors = NirbhorTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(Dimens.groupGap)) {
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusLargeCard)).background(colors.calm).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(64.dp).clip(RoundedCornerShape(18.dp)).background(colors.calmD), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Check, null, tint = colors.paper, modifier = Modifier.size(38.dp))
            }
            Spacer(Modifier.height(14.dp))
            Text(tr("আজকের সব ওষুধ শেষ", "All done for today"), style = NirbhorTheme.type.titleHero, color = colors.paper)
            Text(tr("${num(taken)}টি ডোজ নেওয়া হয়েছে", "$taken doses taken"), style = NirbhorTheme.type.body, color = colors.paper.copy(alpha = 0.9f))
        }
        TintPanel(background = colors.sage) {
            Text(
                tr("রাত ৯:৩০-এ পরিবারকে আজকের হিসাব পাঠানো হবে।", "Today's summary goes to your family at 9:30 PM."),
                style = NirbhorTheme.type.body, color = colors.ink2,
            )
        }
    }
}

@Composable
private fun EmptyHome(actions: NavActions) {
    val colors = NirbhorTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Spacer(Modifier.height(24.dp))
        Text(tr("এখানে আপনার আজকের ওষুধ দেখা যাবে", "Your medicines for today will appear here"), style = NirbhorTheme.type.titleHero, color = colors.ink)
        Text(tr("শুরু করতে একটি ওষুধ যোগ করুন।", "Add a medicine to get started."), style = NirbhorTheme.type.body, color = colors.ink2)
        PrimaryButton(tr("পাতা স্ক্যান করে শুরু করুন", "Scan a pack to start"), actions::startScan, height = 68.dp, leftAligned = true, modifier = Modifier.fillMaxWidth())
        SecondaryButton(tr("প্রেসক্রিপশনের ছবি", "Prescription photo"), actions::startPrescription, height = 58.dp, leftAligned = true, modifier = Modifier.fillMaxWidth())
        SecondaryButton(tr("নাম দিয়ে খুঁজুন", "Search by name"), actions::startSearch, height = 58.dp, leftAligned = true, modifier = Modifier.fillMaxWidth())
        TintPanel(background = colors.sage) {
            Text(tr("পরিবারের কেউ আপনার হয়ে ওষুধ যোগ করে দিতে পারেন।", "A family member can add your medicines for you."), style = NirbhorTheme.type.body, color = colors.ink2)
        }
    }
}

private fun blockMeta(block: TimeBlock): Triple<ImageVector, String, String> = when (block) {
    TimeBlock.MORNING -> Triple(Icons.Filled.WbSunny, "সকাল", "Morning")
    TimeBlock.NOON -> Triple(Icons.Filled.Brightness5, "দুপুর", "Afternoon")
    TimeBlock.NIGHT -> Triple(Icons.Filled.DarkMode, "রাত", "Night")
}

private val bnMonths = arrayOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
private val enMonths = arrayOf("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
private val bnWeekdays = arrayOf("সোমবার", "মঙ্গলবার", "বুধবার", "বৃহস্পতিবার", "শুক্রবার", "শনিবার", "রবিবার")
private val enWeekdays = arrayOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

private fun dateString(d: LocalDate, bangla: Boolean): String {
    val wd = d.dayOfWeek.value - 1
    return if (bangla) {
        "${bnWeekdays[wd]}, ${Numerals.number(d.dayOfMonth, true)} ${bnMonths[d.monthValue - 1]}"
    } else {
        "${enWeekdays[wd]}, ${d.dayOfMonth} ${enMonths[d.monthValue - 1]}"
    }
}
