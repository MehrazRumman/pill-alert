package com.nirbhor.app.ui.screens

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MarkShape
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

private val markPalette = listOf(
    MarkShape.FilledCircle to 0xFF2F6B5BL,
    MarkShape.Ring to 0xFF2F6B5BL,
    MarkShape.RoundedSquare to 0xFF7D94A8L,
    MarkShape.Triangle to 0xFFB9975BL,
    MarkShape.Capsule to 0xFFA8788FL,
    MarkShape.HalfFilled to 0xFF2F6B5BL,
)

/** Add by name (3g). Free-text entry — the patient types exactly what's on the pack; no catalog. */
@Composable
fun AddSearchScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val draft = LocalAddDraft.current
    var query by remember { mutableStateOf("") }
    // Assign a stable mark from the name so the same medicine always looks the same.
    val (mark, color) = remember(query) {
        if (query.isBlank()) MarkShape.FilledCircle to 0xFF2F6B5BL
        else markPalette[(query.hashCode() and 0x7fffffff) % markPalette.size]
    }
    val tabletWord = tr("ট্যাবলেট", "tablet")

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("নাম দিয়ে যোগ করুন", "Add by name"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = Dimens.screenPadding, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.cardGap),
        ) {
            Row(
                Modifier.fillMaxWidth().height(60.dp).clip(RoundedCornerShape(14.dp)).background(colors.card)
                    .border(1.5.dp, colors.calm, RoundedCornerShape(14.dp)).padding(horizontal = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Search, contentDescription = null, tint = colors.ink3)
                Spacer(Modifier.width(10.dp))
                Box(Modifier.weight(1f)) {
                    if (query.isEmpty()) Text(tr("ওষুধের নাম লিখুন", "Type the medicine name"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink3)
                    BasicTextField(
                        value = query, onValueChange = { query = it },
                        textStyle = TextStyle(color = colors.ink, fontSize = NirbhorTheme.type.cardTitlePrimary.fontSize, fontFamily = NirbhorTheme.type.cardTitlePrimary.fontFamily),
                        cursorBrush = androidx.compose.ui.graphics.SolidColor(colors.calm),
                    )
                }
            }

            if (query.isNotBlank()) {
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(Dimens.radiusCard)).background(colors.card)
                        .clickable {
                            draft.displayName = query.trim(); draft.packName = query.trim()
                            draft.strength = ""; draft.form = tabletWord; draft.condition = ""
                            draft.mark = mark; draft.markColor = color
                            actions.addTiming()
                        }
                        .padding(Dimens.cardPadding),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    MedicineMark(mark, Color(color), size = 34.dp)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(query.trim(), style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                        Text(tr("এই নামে যোগ করুন", "Add with this name"), style = NirbhorTheme.type.meta, color = colors.calm)
                    }
                }
            } else {
                TintPanel(background = colors.calmSoft) {
                    Text(tr("পাতায় যে নাম লেখা আছে ঠিক সেটাই লিখুন — পরের ধাপে সময় ও পরিমাণ বেছে নেবেন।",
                        "Type the exact name printed on the pack — you'll set the time and amount next."),
                        style = NirbhorTheme.type.body, color = colors.calmD)
                }
            }
        }
    }
}
