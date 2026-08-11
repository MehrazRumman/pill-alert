package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Prescription photo (3f). Reading a prescription photo needs on-device OCR, which is not wired yet,
 * so this screen never fabricates medicines — it routes to the real entry paths (scan / by name).
 */
@Composable
fun AddPrescriptionScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("প্রেসক্রিপশন", "Prescription"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().padding(horizontal = Dimens.screenPadding, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp), horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(96.dp).clip(RoundedCornerShape(20.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.PhotoCamera, contentDescription = null, tint = colors.calmD, modifier = Modifier.size(44.dp))
            }
            Text(tr("প্রেসক্রিপশন থেকে পড়া শীঘ্রই আসছে", "Reading from a prescription is coming soon"),
                style = NirbhorTheme.type.titleHero, color = colors.ink)
            Text(tr("এখন পাতা স্ক্যান করে বা নাম লিখে ওষুধ যোগ করুন।", "For now, add a medicine by scanning the pack or typing the name."),
                style = NirbhorTheme.type.body, color = colors.ink2)
            Spacer(Modifier.height(8.dp))
            PrimaryButton(tr("পাতা স্ক্যান করুন", "Scan the pack"), actions::addScan, height = 64.dp, modifier = Modifier.fillMaxWidth())
            SecondaryButton(tr("নাম দিয়ে যোগ করুন", "Add by name"), actions::addSearch, height = 58.dp, modifier = Modifier.fillMaxWidth())
            TintPanel(background = colors.sage) {
                Text(tr("নির্ভর কখনও ডাক্তারের লেখা বদলায় না।", "Nirbhor never changes what the doctor wrote."),
                    style = NirbhorTheme.type.body, color = colors.ink2)
            }
        }
    }
}
