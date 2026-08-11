package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.QuantityStepper
import com.nirbhor.app.ui.components.QuickChip
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

/** How many (3d): dose stepper + quick chips, then optional stock with a days-remaining readout. */
@Composable
fun AddQuantityScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val draft = LocalAddDraft.current
    var dose by remember { mutableStateOf(if (draft.dosePerIntake > 0f) draft.dosePerIntake else 1f) }
    var stock by remember { mutableStateOf(draft.stockCount.toFloat()) }
    val perDay = draft.timeTokens.size.coerceAtLeast(1) * dose
    val days = if (perDay <= 0f) 0 else (stock / perDay).toInt()
    val doseLabel = if (dose == 0.5f) tr("আধা", "½") else num(dose.toInt())

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        AddFlowHeader(step = 2, onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            Text(tr("একবারে কতটা?", "How much each time?"), style = NirbhorTheme.type.titleHero, color = colors.ink)
            NbCard(padding = 18.dp) {
                QuantityStepper(
                    value = dose, onChange = { dose = it.coerceIn(0.5f, 10f); draft.dosePerIntake = dose },
                    valueLabel = doseLabel, unitLabel = tr(draft.form.ifBlank { "ট্যাবলেট" }, "tablet"),
                    size = 72.dp, step = 0.5f, min = 0.5f,
                )
                Spacer(Modifier.height(12.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(0.5f to tr("আধা", "½"), 1f to num(1), 2f to num(2), 3f to num(3)).forEach { (v, lbl) ->
                        QuickChip(lbl, selected = dose == v, onClick = { dose = v; draft.dosePerIntake = v }, modifier = Modifier.weight(1f))
                    }
                }
            }

            Text(tr("ঘরে এখন কয়টা আছে?", "How many at home now?"), style = NirbhorTheme.type.header, color = colors.ink)
            NbCard(padding = 18.dp) {
                QuantityStepper(
                    value = stock, onChange = { stock = it; draft.stockCount = it.toInt() },
                    valueLabel = num(stock.toInt()), unitLabel = tr("টি", "left"),
                    size = 60.dp, step = 1f, min = 0f,
                )
                if (stock > 0) {
                    Spacer(Modifier.height(10.dp))
                    TintPanel(background = colors.calmSoft) {
                        Text(tr("${num(days)} দিন চলবে", "About $days days"), style = NirbhorTheme.type.body, color = colors.calmD)
                    }
                }
            }

            PrimaryButton(tr("পরের ধাপ", "Next"), { draft.dosePerIntake = dose; draft.stockCount = stock.toInt(); actions.addReview() }, height = 64.dp, modifier = Modifier.fillMaxWidth())
            SecondaryButton(tr("বাদ দিন", "Skip"), { draft.stockCount = 0; actions.addReview() }, height = 52.dp, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(8.dp))
        }
    }
}
