package com.nirbhor.app.data

import com.nirbhor.app.domain.Caregiver
import com.nirbhor.app.domain.CaregiverChannel
import com.nirbhor.app.domain.DigestFrequency
import com.nirbhor.app.domain.DoseOccurrence
import com.nirbhor.app.domain.DoseSource
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.FoodRelation
import com.nirbhor.app.domain.Frequency
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.ui.marks.MarkShape

private fun csv(s: String): List<String> = if (s.isBlank()) emptyList() else s.split(",")

fun MedicineEntity.toDomain() = Medicine(
    id = id,
    displayName = displayName,
    packName = packName,
    strength = strength,
    form = form,
    condition = condition,
    mark = MarkShape.fromName(mark),
    markColor = markColor,
    dosePerIntake = dosePerIntake,
    foodRelation = runCatching { FoodRelation.valueOf(foodRelation) }.getOrDefault(FoodRelation.NONE),
    frequency = runCatching { Frequency.valueOf(frequency) }.getOrDefault(Frequency.DAILY),
    weekdaysMask = weekdaysMask,
    timeTokens = csv(timeTokens),
    resolvedTimes = csv(resolvedTimes),
    stockCount = stockCount,
    stockUpdatedAt = stockUpdatedAt,
    highRisk = highRisk,
    paused = paused,
)

fun Medicine.toEntity(createdAt: Long = System.currentTimeMillis()) = MedicineEntity(
    id = id,
    displayName = displayName,
    packName = packName,
    strength = strength,
    form = form,
    condition = condition,
    mark = mark.name,
    markColor = markColor,
    dosePerIntake = dosePerIntake,
    foodRelation = foodRelation.name,
    frequency = frequency.name,
    weekdaysMask = weekdaysMask,
    timeTokens = timeTokens.joinToString(","),
    resolvedTimes = resolvedTimes.joinToString(","),
    stockCount = stockCount,
    stockUpdatedAt = stockUpdatedAt,
    highRisk = highRisk,
    paused = paused,
    createdAt = createdAt,
)

fun DoseEntity.toDomain() = DoseOccurrence(
    id = id,
    medicineId = medicineId,
    scheduledEpochMillis = scheduledEpochMillis,
    hour = hour,
    minute = minute,
    block = runCatching { TimeBlock.valueOf(block) }.getOrDefault(TimeBlock.MORNING),
    status = runCatching { DoseStatus.valueOf(status) }.getOrDefault(DoseStatus.UPCOMING),
    confirmedAt = confirmedAt,
    source = source?.let { runCatching { DoseSource.valueOf(it) }.getOrNull() },
)

fun CaregiverEntity.toDomain() = Caregiver(
    id = id,
    name = name,
    relationship = relationship,
    email = email,
    emailVerified = emailVerified,
    phone = phone,
    channels = csv(channels).mapNotNull { runCatching { CaregiverChannel.valueOf(it) }.getOrNull() }.toSet(),
    digestFrequency = runCatching { DigestFrequency.valueOf(digestFrequency) }.getOrDefault(DigestFrequency.DAILY_DIGEST),
    escalateOnSecondMiss = escalateOnSecondMiss,
    notifyOnMissedTwice = notifyOnMissedTwice,
    notifyOnOutOfStock = notifyOnOutOfStock,
    weeklySummary = weeklySummary,
)

fun Caregiver.toEntity() = CaregiverEntity(
    id = id,
    name = name,
    relationship = relationship,
    email = email,
    emailVerified = emailVerified,
    phone = phone,
    channels = channels.joinToString(",") { it.name },
    digestFrequency = digestFrequency.name,
    escalateOnSecondMiss = escalateOnSecondMiss,
    notifyOnMissedTwice = notifyOnMissedTwice,
    notifyOnOutOfStock = notifyOnOutOfStock,
    weeklySummary = weeklySummary,
)
