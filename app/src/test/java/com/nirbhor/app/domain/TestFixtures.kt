package com.nirbhor.app.domain

import com.nirbhor.app.ui.marks.MarkShape

internal fun testMedicine(
    id: String = "medicine-1",
    frequency: Frequency = Frequency.DAILY,
    weekdaysMask: Int = 0,
    timeTokens: List<String> = listOf(TimeBlock.MORNING.token),
    resolvedTimes: List<String> = listOf("08:00"),
    paused: Boolean = false,
) = Medicine(
    id = id,
    displayName = "Test medicine",
    packName = "Test",
    strength = "500 mg",
    form = "tablet",
    condition = "test condition",
    mark = MarkShape.Ring,
    markColor = 0xFF2F6B5B,
    dosePerIntake = 1.5f,
    foodRelation = FoodRelation.AFTER,
    frequency = frequency,
    weekdaysMask = weekdaysMask,
    timeTokens = timeTokens,
    resolvedTimes = resolvedTimes,
    stockCount = 24,
    stockUpdatedAt = 1234L,
    highRisk = false,
    paused = paused,
)

internal fun testDose(
    id: Long = 1L,
    status: DoseStatus = DoseStatus.UPCOMING,
    medicineId: String = "medicine-1",
) = DoseOccurrence(
    id = id,
    medicineId = medicineId,
    scheduledEpochMillis = 1_700_000_000_000L,
    hour = 8,
    minute = 0,
    block = TimeBlock.MORNING,
    status = status,
    confirmedAt = null,
    source = null,
)
