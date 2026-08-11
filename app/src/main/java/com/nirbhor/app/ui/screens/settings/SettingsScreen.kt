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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.border
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nirbhor.app.domain.AppSettings
import com.nirbhor.app.domain.LocalePref
import com.nirbhor.app.domain.TimeFormat
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NbSwitch
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.SectionLabel
import com.nirbhor.app.ui.components.SegmentedControl
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Archivo
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Settings (2l/2i): three grouped cards — language, reminders, reading accessibility. */
@Composable
fun SettingsScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val settings by container.settings.settings.collectAsStateWithLifecycle(initialValue = AppSettings())

    fun edit(block: suspend () -> Unit) = scope.launch { block() }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("সেটিংস", "Settings"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            // ভাষা · Language
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabel(tr("ভাষা", "Language"))
                NbCard {
                    RadioRow(
                        title = tr("ফোনের ভাষা অনুসরণ করুন", "Follow phone language"),
                        subtitle = tr("এখন বাংলা (বাংলাদেশ)", "Now Bangla (Bangladesh)"),
                        selected = settings.localePref == LocalePref.SYSTEM,
                    ) { edit { container.settings.setLocale(LocalePref.SYSTEM) } }
                    Divider()
                    RadioRow(title = "বাংলা", subtitle = null, selected = settings.localePref == LocalePref.BN) {
                        edit { container.settings.setLocale(LocalePref.BN) }
                    }
                    Divider()
                    RadioRow(
                        title = "English", titleArchivo = true, subtitle = null,
                        selected = settings.localePref == LocalePref.EN,
                    ) { edit { container.settings.setLocale(LocalePref.EN) } }
                }
            }

            // মনে করিয়ে দেওয়া · Reminders
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabel(tr("মনে করিয়ে দেওয়া", "Reminders"))
                NbCard {
                    ToggleRow(
                        tr("পূর্ণ-স্ক্রিন অ্যালার্ম", "Full-screen alarm"),
                        tr("লক স্ক্রিনেও দেখা যাবে", "Shows over the lock screen"),
                        settings.fullScreenAlarm,
                    ) { v -> edit { container.settings.setFullScreenAlarm(v) } }
                    Divider()
                    DrillRow(tr("অ্যালার্মের শব্দ", "Alarm sound"), tr("ডিফল্ট", "Default"))
                    Divider()
                    DrillRow(tr("সাড়া না দিলে আবার", "Repeat if ignored"), tr("প্রতি ১০ মিনিটে, ৩ বার পর্যন্ত", "Every 10 min, up to 3 times"))
                    Divider()
                    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(tr("সময়ের ধরন", "Time format"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
                        Box(Modifier.width(150.dp)) {
                            val is24 = settings.is24Hour(settings.localePref != LocalePref.EN)
                            SegmentedControl(
                                options = listOf(tr("১২ ঘণ্টা", "12h"), tr("২৪ ঘণ্টা", "24h")),
                                selectedIndex = if (is24) 1 else 0,
                                onSelect = { i -> edit { container.settings.setTimeFormat(if (i == 1) TimeFormat.H24 else TimeFormat.H12) } },
                            )
                        }
                    }
                }
            }

            // সহজে পড়ার জন্য · Reading
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabel(tr("সহজে পড়ার জন্য", "For easy reading"))
                NbCard {
                    ToggleRow(
                        tr("বড় লেখা", "Bigger text"),
                        tr("সব স্ক্রিনে লেখা বড় হবে", "Larger text everywhere"),
                        settings.biggerText,
                    ) { v -> edit { container.settings.setBiggerText(v) } }
                    Divider()
                    ToggleRow(
                        tr("পড়ে শোনানো", "Read aloud"),
                        tr("অ্যালার্মে ওষুধের নাম বলা হবে", "Speaks the medicine name at alarm time"),
                        settings.readAloud,
                    ) { v -> edit { container.settings.setReadAloud(v) } }
                }
            }
        }
    }
}

@Composable
private fun RadioRow(title: String, subtitle: String?, selected: Boolean, titleArchivo: Boolean = false, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = if (titleArchivo) NirbhorTheme.type.cardTitleSecondary.copy(fontFamily = Archivo) else NirbhorTheme.type.cardTitleSecondary,
                color = colors.ink,
            )
            if (subtitle != null) Text(subtitle, style = NirbhorTheme.type.meta, color = colors.ink3)
        }
        Box(
            Modifier.size(21.dp).clip(CircleShape)
                .border(if (selected) 6.dp else 2.dp, if (selected) colors.calm else colors.line, CircleShape),
        )
    }
}

@Composable
private fun ToggleRow(title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
            Text(subtitle, style = NirbhorTheme.type.meta, color = colors.ink3)
        }
        Spacer(Modifier.width(12.dp))
        NbSwitch(checked = checked, onCheckedChange = onChange)
    }
}

@Composable
private fun DrillRow(title: String, value: String) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink, modifier = Modifier.weight(1f))
        Text(value, style = NirbhorTheme.type.meta, color = colors.ink3)
    }
}

@Composable
private fun Divider() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(NirbhorTheme.colors.line))
}
