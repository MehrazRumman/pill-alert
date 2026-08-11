package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Brightness5
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.nirbhor.app.domain.FoodRelation
import com.nirbhor.app.domain.Frequency
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.QuickChip
import com.nirbhor.app.ui.components.SegmentedControl
import com.nirbhor.app.ui.components.SelectableRow
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** When to take (3c). No clock picker — meal tokens resolve to default times. Multi-select. */
@Composable
fun AddTimingScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val draft = LocalAddDraft.current

    fun toggle(token: String) {
        draft.timeTokens = if (token in draft.timeTokens) draft.timeTokens - token else draft.timeTokens + token
        // Keep resolved times aligned to selected tokens in block order.
        val ordered = TimeBlock.entries.filter { it.token in draft.timeTokens }
        draft.timeTokens = ordered.map { it.token }
        draft.resolvedTimes = ordered.map { "%02d:00".format(it.defaultHour) }
    }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        AddFlowHeader(step = 1, onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            Text(tr("কখন খাবেন?", "When do you take it?"), style = NirbhorTheme.type.titleHero, color = colors.ink)
            Column(verticalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
                TimeChoice(Icons.Filled.WbSunny, tr("সকাল", "Morning"), TimeBlock.MORNING.token in draft.timeTokens) { toggle(TimeBlock.MORNING.token) }
                TimeChoice(Icons.Filled.Brightness5, tr("দুপুর", "Afternoon"), TimeBlock.NOON.token in draft.timeTokens) { toggle(TimeBlock.NOON.token) }
                TimeChoice(Icons.Filled.DarkMode, tr("রাত", "Night"), TimeBlock.NIGHT.token in draft.timeTokens) { toggle(TimeBlock.NIGHT.token) }
            }

            Text(tr("কত ঘন ঘন?", "How often?"), style = NirbhorTheme.type.header, color = colors.ink)
            SegmentedControl(
                options = listOf(tr("প্রতিদিন", "Daily"), tr("একদিন পরপর", "Alternate"), tr("দিন বেছে", "Select days")),
                selectedIndex = when (draft.frequency) {
                    Frequency.DAILY -> 0
                    Frequency.ALTERNATE -> 1
                    Frequency.WEEKDAYS, Frequency.WEEKLY -> 2
                },
                onSelect = { index ->
                    draft.frequency = when (index) {
                        1 -> Frequency.ALTERNATE
                        2 -> Frequency.WEEKLY
                        else -> Frequency.DAILY
                    }
                    if (index == 2 && draft.weekdaysMask == 0) {
                        draft.weekdaysMask = com.nirbhor.app.domain.DoseScheduler.weekdayBit(java.time.LocalDate.now().dayOfWeek)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            )
            if (draft.frequency == Frequency.WEEKLY || draft.frequency == Frequency.WEEKDAYS) {
                val dayLabels = listOf(
                    tr("সোম", "Mon"), tr("মঙ্গল", "Tue"), tr("বুধ", "Wed"), tr("বৃহঃ", "Thu"),
                    tr("শুক্র", "Fri"), tr("শনি", "Sat"), tr("রবি", "Sun"),
                )
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    maxItemsInEachRow = 4,
                ) {
                    dayLabels.forEachIndexed { index, label ->
                        val bit = 1 shl index
                        QuickChip(
                            label = label,
                            selected = draft.weekdaysMask and bit != 0,
                            onClick = {
                                val next = draft.weekdaysMask xor bit
                                if (next != 0) draft.weekdaysMask = next
                            },
                            modifier = Modifier.width(76.dp),
                            height = 48.dp,
                        )
                    }
                }
            }

            Text(tr("খাবারের আগে না পরে?", "Before or after food?"), style = NirbhorTheme.type.header, color = colors.ink)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Dimens.cardGap)) {
                FoodCard(tr("আগে / খালি পেটে", "Before / empty"), draft.foodRelation == FoodRelation.BEFORE, Modifier.weight(1f)) { draft.foodRelation = FoodRelation.BEFORE }
                FoodCard(tr("পরে / ভরা পেটে", "After / full"), draft.foodRelation == FoodRelation.AFTER, Modifier.weight(1f)) { draft.foodRelation = FoodRelation.AFTER }
            }

            if (draft.timeTokens.isNotEmpty()) {
                val bangla = com.nirbhor.app.ui.i18n.LocalIsBangla.current
                val is24 = com.nirbhor.app.ui.i18n.LocalIs24Hour.current
                val sep = tr(" আর ", " and ")
                val times = draft.resolvedTimes.joinToString(sep) { hhmm ->
                    val h = hhmm.substringBefore(":").toInt()
                    com.nirbhor.app.ui.i18n.Numerals.time(h, 0, bangla, is24)
                }
                TintPanel(background = colors.calmSoft) {
                    Text(
                        tr("তাহলে অ্যালার্ম বাজবে $times-এ। সময় পছন্দ না হলে পরে বদলে নিতে পারবেন।",
                            "Alarms will ring at $times. You can change the times later."),
                        style = NirbhorTheme.type.body, color = colors.calmD,
                    )
                }
            }
            PrimaryButton(tr("পরের ধাপ", "Next"), actions::addQuantity, height = 64.dp, enabled = draft.timeTokens.isNotEmpty(), modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(8.dp))
        }
    }
}

@Composable
private fun TimeChoice(icon: ImageVector, label: String, selected: Boolean, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    SelectableRow(
        title = label, selected = selected, onClick = onClick, height = 88.dp,
        leading = {
            Icon(icon, contentDescription = null, tint = if (selected) colors.paper else colors.ink2, modifier = Modifier.size(34.dp))
        },
    )
}

@Composable
private fun FoodCard(label: String, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    val shape = RoundedCornerShape(14.dp)
    Box(
        modifier.height(76.dp).clip(shape)
            .background(if (selected) colors.calm else colors.card)
            .border(if (selected) 2.dp else 1.5.dp, if (selected) colors.calm else colors.line, shape)
            .clickable(onClick = onClick).padding(14.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Text(label, style = NirbhorTheme.type.cardTitleSecondary, color = if (selected) colors.paper else colors.ink)
    }
}
