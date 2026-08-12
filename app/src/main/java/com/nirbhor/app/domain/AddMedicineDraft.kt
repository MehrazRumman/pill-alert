package com.nirbhor.app.domain

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.mapSaver
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
    var markColor by mutableLongStateOf(0xFF2F6B5BL)
    var dosePerIntake by mutableFloatStateOf(1f)
    var foodRelation by mutableStateOf(FoodRelation.NONE)
    var timeTokens by mutableStateOf<List<String>>(emptyList())      // morning/noon/night
    var resolvedTimes by mutableStateOf<List<String>>(emptyList())
    var frequency by mutableStateOf(Frequency.DAILY)
    var weekdaysMask by mutableIntStateOf(0)
    var stockCount by mutableIntStateOf(0)
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

    companion object {
        /** Keeps an unfinished add flow intact across rotation and process recreation. */
        val Saver: Saver<AddMedicineDraft, Any> = mapSaver(
            save = { draft ->
                mapOf(
                    "displayName" to draft.displayName,
                    "packName" to draft.packName,
                    "strength" to draft.strength,
                    "form" to draft.form,
                    "condition" to draft.condition,
                    "mark" to draft.mark.name,
                    "markColor" to draft.markColor,
                    "dosePerIntake" to draft.dosePerIntake,
                    "foodRelation" to draft.foodRelation.name,
                    "timeTokens" to ArrayList(draft.timeTokens),
                    "resolvedTimes" to ArrayList(draft.resolvedTimes),
                    "frequency" to draft.frequency.name,
                    "weekdaysMask" to draft.weekdaysMask,
                    "stockCount" to draft.stockCount,
                    "highRisk" to draft.highRisk,
                )
            },
            restore = { saved ->
                AddMedicineDraft().apply {
                    displayName = saved["displayName"] as? String ?: ""
                    packName = saved["packName"] as? String ?: ""
                    strength = saved["strength"] as? String ?: ""
                    form = saved["form"] as? String ?: ""
                    condition = saved["condition"] as? String ?: ""
                    mark = (saved["mark"] as? String)?.let(MarkShape::fromName) ?: MarkShape.FilledCircle
                    markColor = saved["markColor"] as? Long ?: 0xFF2F6B5BL
                    dosePerIntake = saved["dosePerIntake"] as? Float ?: 1f
                    foodRelation = (saved["foodRelation"] as? String)
                        ?.let { runCatching { FoodRelation.valueOf(it) }.getOrNull() } ?: FoodRelation.NONE
                    timeTokens = (saved["timeTokens"] as? List<*>)?.filterIsInstance<String>().orEmpty()
                    resolvedTimes = (saved["resolvedTimes"] as? List<*>)?.filterIsInstance<String>().orEmpty()
                    frequency = (saved["frequency"] as? String)
                        ?.let { runCatching { Frequency.valueOf(it) }.getOrNull() } ?: Frequency.DAILY
                    weekdaysMask = saved["weekdaysMask"] as? Int ?: 0
                    stockCount = saved["stockCount"] as? Int ?: 0
                    highRisk = saved["highRisk"] as? Boolean ?: false
                }
            },
        )
    }
}

val LocalAddDraft = staticCompositionLocalOf { AddMedicineDraft() }
