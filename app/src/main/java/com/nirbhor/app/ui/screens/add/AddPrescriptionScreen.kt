package com.nirbhor.app.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Prescription photo (3f). Reads the first clearly visible medicine name from a selected photo;
 * the user continues through timing and quantity to confirm it before anything is saved.
 */
@Composable
fun AddPrescriptionScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val context = LocalContext.current
    val draft = LocalAddDraft.current
    var reading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) {
            reading = true
            error = null
            recognizeImage(
                context,
                uri,
                onSuccess = { text ->
                    val parsed = parsePackText(text)
                    if (parsed == null) {
                        reading = false
                        error = if (context.resources.configuration.locales[0].language == "bn") "ওষুধের নাম পড়া যায়নি" else "Couldn't find a medicine name"
                    } else {
                        draft.displayName = parsed.name
                        draft.packName = parsed.name
                        draft.strength = parsed.strength
                        draft.form = parsed.form
                        stableMark(parsed.name).let { (mark, color) -> draft.mark = mark; draft.markColor = color }
                        reading = false
                        actions.addTiming()
                    }
                },
                onFailure = {
                    reading = false
                    error = if (context.resources.configuration.locales[0].language == "bn") "ছবি পড়া যায়নি" else "Couldn't read that photo"
                },
            )
        }
    }
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("প্রেসক্রিপশন", "Prescription"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding()
                .padding(horizontal = Dimens.screenPadding, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp), horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(96.dp).clip(RoundedCornerShape(20.dp)).background(colors.calmSoft), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.PhotoCamera, contentDescription = null, tint = colors.calmD, modifier = Modifier.size(44.dp))
            }
            Text(tr("প্রেসক্রিপশনের ছবি থেকে ওষুধ পড়ুন", "Read a medicine from a prescription"),
                style = NirbhorTheme.type.titleHero, color = colors.ink)
            Text(tr("পরিষ্কার ছবিটি বেছে নিন। প্রথম যে ওষুধের নাম পড়া যাবে, সেটি নিশ্চিত করার জন্য দেখানো হবে।", "Choose a clear photo. The first readable medicine will be shown for confirmation."),
                style = NirbhorTheme.type.body, color = colors.ink2)
            Spacer(Modifier.height(8.dp))
            PrimaryButton(
                if (reading) tr("পড়া হচ্ছে…", "Reading…") else tr("ছবি বেছে নিন", "Choose a photo"),
                { picker.launch("image/*") },
                enabled = !reading,
                height = 64.dp,
                modifier = Modifier.fillMaxWidth(),
            )
            error?.let { Text(it, style = NirbhorTheme.type.meta, color = colors.warmD) }
            SecondaryButton(tr("পাতা স্ক্যান করুন", "Scan the pack"), actions::addScan, height = 60.dp, modifier = Modifier.fillMaxWidth())
            SecondaryButton(tr("নাম দিয়ে যোগ করুন", "Add by name"), actions::addSearch, height = 60.dp, modifier = Modifier.fillMaxWidth())
            TintPanel(background = colors.sage) {
                Text(tr("নির্ভর কখনও ডাক্তারের লেখা বদলায় না।", "Nirbhor never changes what the doctor wrote."),
                    style = NirbhorTheme.type.body, color = colors.ink2)
            }
        }
    }
}
