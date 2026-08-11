package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Archivo
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Caregiver joins by code (6d): four code tiles, then a confirmation + permission disclosure. */
@Composable
fun CaregiverCodeScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    var code by remember { mutableStateOf("") }
    val matched = code.length == 4

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("কোড দিয়ে যুক্ত হোন", "Join by code"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding()
                .padding(horizontal = Dimens.screenPadding, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap), horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(tr("রোগীর অ্যাপে দেখানো ৪-অক্ষরের কোডটি লিখুন", "Enter the 4-character code shown in the patient's app"),
                style = NirbhorTheme.type.body, color = colors.ink2)

            Box {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    for (i in 0 until 4) {
                        val c = code.getOrNull(i)?.toString() ?: ""
                        val active = i == code.length
                        Box(
                            Modifier.size(70.dp).clip(RoundedCornerShape(14.dp)).background(colors.card)
                                .border(if (active) 2.dp else 1.5.dp, if (active) colors.calm else colors.line, RoundedCornerShape(14.dp)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(c, fontSize = 28.sp, fontWeight = FontWeight(700), fontFamily = Archivo, color = colors.ink)
                        }
                    }
                }
                BasicTextField(
                    value = code,
                    onValueChange = { if (it.length <= 4) code = it.uppercase() },
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters),
                    modifier = Modifier.matchParentSize().alpha(0f),
                )
            }

            if (matched) {
                TintPanel(background = colors.calmSoft, radius = Dimens.radiusLargeCard) {
                    Text(tr("আব্বার সঙ্গে যুক্ত হচ্ছেন", "Connecting to Abba"), style = NirbhorTheme.type.cardTitlePrimary, color = colors.calmD)
                }
                TintPanel(background = colors.sage) {
                    listOf(
                        tr("• আপনি শুধু দেখতে পারবেন, বদলাতে পারবেন না", "• You can only view, not change anything"),
                        tr("• রোগী চাইলে যেকোনো সময় সরাতে পারবেন", "• The patient can remove you any time"),
                        tr("• আপনি যা দেখছেন, রোগীও তা জানেন", "• The patient sees what you see"),
                    ).forEach { Text(it, style = NirbhorTheme.type.body, color = colors.ink2, modifier = Modifier.padding(vertical = 2.dp)) }
                }
            }

            Spacer(Modifier.height(24.dp))
            PrimaryButton(tr("যুক্ত হোন", "Join"), actions::back, height = 68.dp, enabled = matched, modifier = Modifier.fillMaxWidth())
            Text(tr("কোড নেই", "No code"), style = NirbhorTheme.type.buttonLabel, color = colors.ink3, modifier = Modifier.padding(6.dp))
        }
    }
}
