package com.nirbhor.app.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

@Composable
fun HelpScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val context = LocalContext.current
    val questions = listOf(
        tr("অ্যালার্ম না এলে কী করব?", "What if alarms don't appear?") to
            tr("সেটিংসে নোটিফিকেশন, অ্যালার্ম ও ব্যাটারি অনুমতি চালু আছে কি না দেখুন।", "Check notification, alarm, and battery permissions in Android settings."),
        tr("ভুল করে খেয়েছি চাপলে?", "What if I tap Taken by mistake?") to
            tr("হোম স্ক্রিনের নিচে ৫ সেকেন্ডের জন্য ফিরে নেওয়ার বোতাম আসে।", "Use Undo at the bottom of Home within five seconds."),
        tr("স্ক্যান কাজ না করলে?", "What if scanning fails?") to
            tr("আলো বাড়িয়ে আবার চেষ্টা করুন, গ্যালারি থেকে পরিষ্কার ছবি নিন, অথবা নাম লিখুন।", "Try better lighting, choose a clear gallery photo, or enter the name manually."),
    )
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("সাহায্য", "Help"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding()
                .padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            questions.forEach { (question, answer) ->
                NbCard {
                    Text(question, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                    Text(answer, style = NirbhorTheme.type.body, color = colors.ink2, modifier = Modifier.padding(top = 6.dp))
                }
            }
            SecondaryButton(
                tr("ইমেইলে যোগাযোগ করুন", "Contact by email"),
                {
                    val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:support@nirbhor.app"))
                    runCatching { context.startActivity(intent) }
                },
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}
