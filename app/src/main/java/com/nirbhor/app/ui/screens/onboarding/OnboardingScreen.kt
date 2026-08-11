package com.nirbhor.app.ui.screens

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nirbhor.app.domain.LocalePref
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.NirbhorTheme
import kotlinx.coroutines.launch

/** Onboarding (2q/2a): full-bleed calm screen, paper text, three numbered steps, language pills. */
@Composable
fun OnboardingScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()

    Column(
        Modifier
            .fillMaxSize()
            .background(colors.calm)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 28.dp),
    ) {
        Box(
            Modifier.size(56.dp).clip(RoundedCornerShape(18.dp)).background(Color(0x22FFFFFF)),
            contentAlignment = Alignment.Center,
        ) {
            // Pill glyph.
            Box(Modifier.size(28.dp, 14.dp).clip(RoundedCornerShape(7.dp)).background(colors.paper))
        }
        Spacer(Modifier.height(16.dp))
        Text("নির্ভর", style = NirbhorTheme.type.header, color = colors.paper.copy(alpha = 0.9f))
        Spacer(Modifier.height(20.dp))
        Text(
            tr("সময়মতো ওষুধ,\nনিশ্চিন্ত পরিবার।", "Medicine on time,\na family at ease."),
            fontSize = 40.sp, lineHeight = 48.sp, fontWeight = FontWeight(700), color = colors.paper,
        )
        Spacer(Modifier.height(14.dp))
        Text(
            tr("নির্ভর আপনাকে প্রতিটি ডোজ মনে করিয়ে দেয়, হিসাব রাখে, আর দরকারে পরিবারকে জানায়।",
                "Nirbhor reminds you of every dose, keeps the record, and tells your family when it matters."),
            style = NirbhorTheme.type.body, color = colors.paper.copy(alpha = 0.85f),
        )
        Spacer(Modifier.height(26.dp))

        val steps = listOf(
            tr("পাতা স্ক্যান করে ওষুধ যোগ করুন", "Add a medicine by scanning the pack"),
            tr("সময়মতো মনে করিয়ে দেওয়া হবে", "Get reminded at the right time"),
            tr("পরিবার চাইলে হিসাব পায়", "Your family can follow along"),
        )
        steps.forEachIndexed { i, s ->
            Row(
                Modifier
                    .fillMaxWidth().padding(vertical = 5.dp)
                    .clip(RoundedCornerShape(14.dp)).background(Color(0x1FFFFFFF)).padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(30.dp).clip(CircleShape).background(Color(0x33FFFFFF)), contentAlignment = Alignment.Center) {
                    Text(num(i + 1), style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper)
                }
                Spacer(Modifier.width(12.dp))
                Text(s, style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper)
            }
        }

        Spacer(Modifier.height(28.dp))
        Row(
            Modifier
                .fillMaxWidth().height(62.dp)
                .clip(RoundedCornerShape(16.dp)).background(colors.paper)
                .clickable {
                    scope.launch {
                        container.settings.setOnboardingComplete(true)
                        actions.finishOnboarding()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            actions.openPermissionPriming()
                        }
                    }
                }
                .padding(horizontal = 22.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            Text(tr("শুরু করুন", "Get started"), style = NirbhorTheme.type.buttonLabel, color = colors.calm)
            Spacer(Modifier.width(10.dp))
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = colors.calm)
        }

        Spacer(Modifier.height(18.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            LangPill("বাংলা") { scope.launch { container.settings.setLocale(LocalePref.BN) } }
            LangPill("English") { scope.launch { container.settings.setLocale(LocalePref.EN) } }
            Text(tr("· যেকোনো সময় বদলানো যাবে", "· change any time"), style = NirbhorTheme.type.meta, color = colors.paper.copy(alpha = 0.7f))
        }
    }
}

@Composable
private fun LangPill(label: String, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    Box(
        Modifier
            .clip(RoundedCornerShape(10.dp)).border(1.5.dp, colors.paper.copy(alpha = 0.5f), RoundedCornerShape(10.dp))
            .clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Text(label, style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper)
    }
}
