package com.nirbhor.app.notifications

import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.nirbhor.app.NirbhorApp
import com.nirbhor.app.domain.AppSettings
import com.nirbhor.app.domain.DoseWithMedicine
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.i18n.LocalIs24Hour
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.i18n.clock
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MarkShape
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Locale

/** Full-screen alarm over the lock screen (2k/2c). Launched by [AlarmReceiver]'s full-screen intent. */
class AlarmActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        val epoch = intent.getLongExtra(AlarmScheduler.EXTRA_EPOCH, System.currentTimeMillis())
        val doseId = intent.getLongExtra(AlarmScheduler.EXTRA_DOSE_ID, -1L)
        val container = (application as NirbhorApp).container

        (getSystemService(NotificationManager::class.java))?.cancel(doseId.toInt())

        setContent {
            val settings by produceState(initialValue = AppSettings()) {
                value = container.settings.settings.first()
            }
            val deviceIsBangla = remember { Locale.getDefault().language == "bn" }
            val isBangla = settings.isBangla(deviceIsBangla)

            NirbhorTheme(isBangla = isBangla, biggerText = settings.biggerText) {
                CompositionLocalProvider(
                    LocalIsBangla provides isBangla,
                    LocalIs24Hour provides settings.is24Hour(isBangla),
                ) {
                    val doses by produceState(initialValue = emptyList<DoseWithMedicine>(), epoch) {
                        value = container.repository.dosesAround(epoch)
                    }
                    AlarmContent(
                        epoch = epoch,
                        doses = doses,
                        onTaken = {
                            container.appScope.launch { doses.forEach { container.repository.markTaken(it.dose.id, com.nirbhor.app.domain.DoseSource.ALARM) } }
                            finish()
                        },
                        onSnooze = {
                            container.appScope.launch {
                                doses.forEach { container.repository.snoozeDose(it.dose.id) }
                                AlarmScheduler.rescheduleAll(applicationContext)
                            }
                            finish()
                        },
                        onSkip = {
                            container.appScope.launch { doses.forEach { container.repository.skipDose(it.dose.id, com.nirbhor.app.domain.DoseSource.ALARM) } }
                            finish()
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun AlarmContent(
    epoch: Long,
    doses: List<DoseWithMedicine>,
    onTaken: () -> Unit,
    onSnooze: () -> Unit,
    onSkip: () -> Unit,
) {
    val colors = NirbhorTheme.colors
    val time = remember(epoch) { java.time.Instant.ofEpochMilli(epoch).atZone(java.time.ZoneId.systemDefault()).toLocalTime() }
    Column(
        Modifier.fillMaxSize().background(colors.calmD).systemBarsPadding().padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(50.dp))
        androidx.compose.material3.Text(tr("নির্ভর · মনে করিয়ে দিচ্ছে", "Nirbhor · reminding you"), style = NirbhorTheme.type.meta, color = colors.alarmText.copy(alpha = 0.8f))
        Spacer(Modifier.height(20.dp))
        androidx.compose.material3.Text(clock(time.hour, time.minute), style = NirbhorTheme.type.alarmTime, color = colors.alarmText)
        Spacer(Modifier.height(28.dp))
        doses.forEach { dwm ->
            val markColor = if (dwm.medicine.mark == MarkShape.RoundedSquare) colors.markSlateOnDark else colors.markCalmOnDark
            Row(
                Modifier.fillMaxWidth().padding(vertical = 5.dp).clip(RoundedCornerShape(16.dp)).background(Color(0x1AFFFFFF)).padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                MedicineMark(dwm.medicine.mark, markColor, size = 40.dp)
                Spacer(Modifier.width(14.dp))
                Column {
                    androidx.compose.material3.Text(dwm.medicine.displayName, style = NirbhorTheme.type.alarmName, color = colors.alarmText)
                    androidx.compose.material3.Text("${dwm.medicine.strength} · ${dwm.medicine.form}", style = NirbhorTheme.type.meta, color = colors.alarmText.copy(alpha = 0.75f))
                }
            }
        }
        Spacer(Modifier.weight(1f))
        PrimaryButton(tr("খেয়ে নিয়েছি", "I've taken it"), onTaken, height = 80.dp, container = colors.alarmText, content = colors.calmD, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(10.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            PrimaryButton(tr("পরে মনে করাও", "Snooze"), onSnooze, height = 62.dp, container = Color(0x22FFFFFF), content = colors.alarmText, modifier = Modifier.weight(1f))
            SecondaryButton(tr("আজ বাদ", "Skip"), onSkip, height = 62.dp, borderColor = colors.alarmText.copy(alpha = 0.4f), content = colors.alarmText.copy(alpha = 0.7f), modifier = Modifier.width(118.dp))
        }
        Spacer(Modifier.height(24.dp))
    }
}
