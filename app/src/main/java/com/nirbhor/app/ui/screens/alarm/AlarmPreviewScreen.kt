package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.DoseWithMedicine
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.notifications.AlarmScheduler
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.i18n.clock
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MarkShape
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch
import java.time.LocalDate

/** Full-screen alarm preview (2k/2c). The real lock-screen alarm is AlarmActivity; this mirrors it. */
@Composable
fun AlarmPreviewScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val blocks by repo.timelineFor(LocalDate.now()).collectAsStateWithLifecycle(initialValue = emptyList())

    val block = blocks.firstOrNull { b -> b.doses.any { it.dose.status == DoseStatus.UPCOMING } } ?: blocks.firstOrNull()
    val due = block?.doses?.filter { it.dose.status == DoseStatus.UPCOMING }?.ifEmpty { block.doses } ?: emptyList()

    Column(
        Modifier.fillMaxSize().background(colors.calmD).systemBarsPadding().padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(40.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.NotificationsActive, contentDescription = null, tint = colors.alarmText.copy(alpha = 0.8f), modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(tr("নির্ভর · মনে করিয়ে দিচ্ছে", "Nirbhor · reminding you"), style = NirbhorTheme.type.meta, color = colors.alarmText.copy(alpha = 0.8f))
        }
        Spacer(Modifier.height(20.dp))
        Text(
            clock(block?.hour ?: 8, block?.minute ?: 0),
            style = NirbhorTheme.type.alarmTime, color = colors.alarmText,
        )
        Spacer(Modifier.height(6.dp))
        Text(tr("ওষুধ খাওয়ার সময় হয়েছে", "It's time for your medicine"), style = NirbhorTheme.type.body, color = colors.alarmText.copy(alpha = 0.85f))
        Spacer(Modifier.height(28.dp))

        Column(Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState())) {
            due.forEach { dwm -> AlarmMedCard(dwm) }
        }
        val takeAction = {
            scope.launch {
                due.forEach { repo.markTaken(it.dose.id) }
                actions.back()
            }
            Unit
        }
        if (due.any { it.medicine.highRisk }) {
            Box(
                Modifier.fillMaxWidth().heightIn(min = 80.dp).clip(RoundedCornerShape(16.dp)).background(colors.alarmText)
                    .combinedClickable(
                        enabled = due.isNotEmpty(), role = Role.Button, onClick = {}, onLongClick = takeAction,
                        onLongClickLabel = tr("চেপে ধরে নিশ্চিত করুন", "Hold to confirm"),
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Text(tr("চেপে ধরে নিশ্চিত করুন", "Hold to confirm"), style = NirbhorTheme.type.buttonLabel, color = colors.calmD)
            }
        } else {
            PrimaryButton(
                tr("খেয়ে নিয়েছি", "I've taken it"), takeAction,
                height = 80.dp, enabled = due.isNotEmpty(), container = colors.alarmText, content = colors.calmD, modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.height(10.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            PrimaryButton(
                tr("পরে মনে করাও", "Snooze"),
                {
                    scope.launch {
                        due.forEach { repo.snoozeDose(it.dose.id) }
                        AlarmScheduler.rescheduleAll(context.applicationContext)
                        actions.back()
                    }
                },
                height = 62.dp, enabled = due.isNotEmpty(), container = Color(0x22FFFFFF), content = colors.alarmText, modifier = Modifier.weight(1f),
            )
            SecondaryButton(
                tr("আজ বাদ", "Skip"),
                {
                    scope.launch {
                        due.forEach { repo.skipDose(it.dose.id) }
                        actions.back()
                    }
                },
                height = 62.dp, enabled = due.isNotEmpty(), borderColor = colors.alarmText.copy(alpha = 0.4f), content = colors.alarmText.copy(alpha = 0.7f), modifier = Modifier.width(118.dp),
            )
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun AlarmMedCard(dwm: DoseWithMedicine) {
    val colors = NirbhorTheme.colors
    val markColor = if (dwm.medicine.mark == MarkShape.RoundedSquare) colors.markSlateOnDark else colors.markCalmOnDark
    Row(
        Modifier.fillMaxWidth().padding(vertical = 5.dp).clip(RoundedCornerShape(16.dp)).background(Color(0x1AFFFFFF)).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        MedicineMark(dwm.medicine.mark, markColor, size = 40.dp)
        Spacer(Modifier.width(14.dp))
        Column {
            Text(dwm.medicine.displayName, style = NirbhorTheme.type.alarmName, color = colors.alarmText)
            Text("${dwm.medicine.strength} · ${dwm.medicine.form}", style = NirbhorTheme.type.meta, color = colors.alarmText.copy(alpha = 0.75f))
        }
    }
}
