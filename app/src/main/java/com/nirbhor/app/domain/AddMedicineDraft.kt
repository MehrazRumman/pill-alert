package com.nirbhor.app.domain

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import com.nirbhor.app.ui.marks.MarkShape
import java.util.UUID

/**
 * Shared draft across the add-medicine flow (3a → 3c → 3d → 3e). Held above the flow so every step is
 * back-navigable without losing entered data (README > Add-medicine flow). The mark + colour are
 * assigned once at creation and stored on the record.
 */
class AddMedicineDraft {
    var displayName by mutableStateOf("")
    var packName by mutableStateOf("")
    var strength by mutableStateOf("")
    var form by mutableStateOf("")
    var condition by mutableStateOf("")
    var mark by mutableStateOf(MarkShape.FilledCircle)
    var markColor by mutableStateOf(0xFF2F6B5BL)
    var dosePerIntake by mutableStateOf(1f)
    var foodRelation by mutableStateOf(FoodRelation.NONE)
    var timeTokens by mutableStateOf<List<String>>(emptyList())      // morning/noon/night
    var resolvedTimes by mutableStateOf<List<String>>(emptyList())
    var frequency by mutableStateOf(Frequency.DAILY)
    var weekdaysMask by mutableStateOf(0)
    var stockCount by mutableStateOf(0)
    var highRisk by mutableStateOf(false)

    fun reset() {
        displayName = ""; packName = ""; strength = ""; form = ""; condition = ""
        mark = MarkShape.FilledCircle; markColor = 0xFF2F6B5BL
        dosePerIntake = 1f; foodRelation = FoodRelation.NONE
        timeTokens = emptyList(); resolvedTimes = emptyList()
        frequency = Frequency.DAILY; weekdaysMask = 0; stockCount = 0; highRisk = false
    }

    fun toMedicine(): Medicine = Medicine(
        id = "m-" + UUID.randomUUID().toString().take(8),
        displayName = displayName.ifBlank { packName },
        packName = packName,
        strength = strength,
        form = form,
        condition = condition,
        mark = mark,
        markColor = markColor,
        dosePerIntake = dosePerIntake,
        foodRelation = foodRelation,
        frequency = frequency,
        weekdaysMask = weekdaysMask,
        timeTokens = timeTokens,
        resolvedTimes = resolvedTimes.ifEmpty { timeTokens.map { DoseScheduler.blockDefaultTime(TimeBlock.fromToken(it)) } },
        stockCount = stockCount,
        stockUpdatedAt = System.currentTimeMillis(),
        highRisk = highRisk,
        paused = false,
    )
}

val LocalAddDraft = staticCompositionLocalOf { AddMedicineDraft() }
