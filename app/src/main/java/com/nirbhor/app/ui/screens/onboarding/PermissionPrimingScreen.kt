package com.nirbhor.app.ui.screens

import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.ui.platform.LocalContext
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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Notification permission priming (5b): shown before the system POST_NOTIFICATIONS dialog. */
@Composable
fun PermissionPrimingScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val container = LocalAppContainer.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    fun finishPriming() {
        scope.launch {
            container.settings.setPrimingShown(true)
            actions.back()
        }
    }
    val fullScreenLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        finishPriming()
    }
    fun askForFullScreenAlarmOrFinish() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            if (notificationManager?.canUseFullScreenIntent() == false) {
                fullScreenLauncher.launch(
                    Intent(
                        Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                        Uri.parse("package:${context.packageName}"),
                    ),
                )
                return
            }
        }
        finishPriming()
    }
    val exactAlarmLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        askForFullScreenAlarmOrFinish()
    }
    fun askForExactAlarmOrFinish() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            if (alarmManager?.canScheduleExactAlarms() == false) {
                exactAlarmLauncher.launch(
                    Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:${context.packageName}"),
                    ),
                )
                return
            }
        }
        askForFullScreenAlarmOrFinish()
    }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        askForExactAlarmOrFinish()
    }
    fun ask() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            launcher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
        } else {
            askForExactAlarmOrFinish()
        }
    }

    Column(
        Modifier.fillMaxSize().background(colors.paper).verticalScroll(rememberScrollState()).systemBarsPadding()
            .padding(horizontal = Dimens.screenPadding).padding(top = 40.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Box(Modifier.size(76.dp).clip(RoundedCornerShape(20.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.NotificationsActive, contentDescription = null, tint = colors.calmD, modifier = Modifier.size(38.dp))
        }
        Text(tr("সময়মতো জানাতে অনুমতি দরকার", "We need permission to remind you"), style = NirbhorTheme.type.titleHero, color = colors.ink)
        Text(
            tr("পরের পর্দায় “অনুমতি দিন” চাপুন — তাহলেই ওষুধের সময় হলে নির্ভর জানাতে পারবে।",
                "On the next screen, tap \"Allow\" so Nirbhor can tell you when it's time."),
            style = NirbhorTheme.type.body, color = colors.ink2,
        )

        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusCard)).background(colors.card).padding(4.dp)) {
            ValueRow(Icons.Filled.Schedule, tr("ওষুধের সময় মনে করিয়ে দেবে", "Reminds you at dose time"))
            ValueRow(Icons.Filled.Inventory2, tr("ওষুধ ফুরিয়ে এলে জানাবে", "Warns when a medicine runs low"))
            ValueRow(Icons.Filled.Block, tr("কোনো বিজ্ঞাপন বা খবর নয়", "No ads, no news"))
        }

        TintPanel(background = colors.warmSoft) {
            Text(
                tr("অনুমতি না দিলেও অ্যাপ চলবে, তবে চুপচাপ — কোনো শব্দ বা মনে করানো থাকবে না।",
                    "The app still works without permission, but silently — no sound or reminders."),
                style = NirbhorTheme.type.body, color = colors.warmD,
            )
        }

        PrimaryButton(tr("ঠিক আছে, জিজ্ঞেস করুন", "OK, ask me"), { ask() }, height = 68.dp, modifier = Modifier.fillMaxWidth())
        Box(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                .clickable {
                    finishPriming()
                }
                .padding(vertical = 10.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(tr("এখন নয়", "Not now"), style = NirbhorTheme.type.buttonLabel, color = colors.ink3)
        }
    }
}

@Composable
private fun ValueRow(icon: ImageVector, text: String) {
    val colors = NirbhorTheme.colors
    Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(38.dp).clip(RoundedCornerShape(11.dp)).background(colors.sage), contentAlignment = Alignment.Center) {
            Icon(icon, contentDescription = null, tint = colors.ink2, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(12.dp))
        Text(text, style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
    }
}
