package com.nirbhor.app.data

import com.nirbhor.app.domain.Caregiver
import com.nirbhor.app.domain.CaregiverChannel
import com.nirbhor.app.domain.DigestFrequency
import com.nirbhor.app.domain.DoseSource
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.FoodRelation
import com.nirbhor.app.domain.Frequency
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.domain.testMedicine
import com.nirbhor.app.ui.marks.MarkShape
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MappersTest {
    @Test fun medicineRoundTripPreservesEveryDomainField() {
        val medicine = testMedicine(
            frequency = Frequency.WEEKDAYS,
            weekdaysMask = 0b0010101,
            timeTokens = listOf("morning", "night"),
            resolvedTimes = listOf("07:10", "22:40"),
            paused = true,
        )
        val entity = medicine.toEntity(createdAt = 999L)
        assertEquals(999L, entity.createdAt)
        assertEquals(medicine, entity.toDomain())
    }

    @Test fun blankCsvFieldsBecomeEmptyLists() {
        val domain = validMedicineEntity(timeTokens = "", resolvedTimes = "").toDomain()
        assertEquals(emptyList<String>(), domain.timeTokens)
        assertEquals(emptyList<String>(), domain.resolvedTimes)
    }

    @Test fun invalidMedicineEnumsAndMarkUseSafeDefaults() {
        val domain = validMedicineEntity(
            mark = "BAD",
            foodRelation = "BAD",
            frequency = "BAD",
        ).toDomain()
        assertEquals(MarkShape.FilledCircle, domain.mark)
        assertEquals(FoodRelation.NONE, domain.foodRelation)
        assertEquals(Frequency.DAILY, domain.frequency)
    }

    @Test fun doseMapperPreservesValidValues() {
        val entity = DoseEntity(
            id = 9,
            medicineId = "m1",
            scheduledEpochMillis = 1000,
            hour = 21,
            minute = 30,
            block = TimeBlock.NIGHT.name,
            status = DoseStatus.TAKEN_LATE.name,
            confirmedAt = 2000,
            source = DoseSource.ALARM.name,
        )
        val domain = entity.toDomain()
        assertEquals(9, domain.id)
        assertEquals(TimeBlock.NIGHT, domain.block)
        assertEquals(DoseStatus.TAKEN_LATE, domain.status)
        assertEquals(DoseSource.ALARM, domain.source)
    }

    @Test fun invalidDoseEnumsUseSafeDefaultsAndUnknownSourceIsNull() {
        val domain = DoseEntity(
            medicineId = "m1", scheduledEpochMillis = 1, hour = 0, minute = 0,
            block = "BAD", status = "BAD", confirmedAt = null, source = "BAD",
        ).toDomain()
        assertEquals(TimeBlock.MORNING, domain.block)
        assertEquals(DoseStatus.UPCOMING, domain.status)
        assertNull(domain.source)
    }

    @Test fun caregiverRoundTripPreservesChannelsAndPreferences() {
        val caregiver = Caregiver(
            id = "c1",
            name = "Rahim",
            relationship = "Son",
            email = "r@example.com",
            emailVerified = true,
            phone = "+8801000000000",
            channels = setOf(CaregiverChannel.EMAIL, CaregiverChannel.APP),
            digestFrequency = DigestFrequency.IMMEDIATE,
            escalateOnSecondMiss = true,
            notifyOnMissedTwice = true,
            notifyOnOutOfStock = false,
            weeklySummary = true,
        )
        assertEquals(caregiver, caregiver.toEntity().toDomain())
    }

    @Test fun caregiverMapperDropsUnknownChannelsAndDefaultsDigest() {
        val domain = CaregiverEntity(
            id = "c1", name = "A", relationship = "B", email = "", emailVerified = false,
            phone = "", channels = "EMAIL,UNKNOWN,SMS", digestFrequency = "UNKNOWN",
            escalateOnSecondMiss = false, notifyOnMissedTwice = false,
            notifyOnOutOfStock = false, weeklySummary = false,
        ).toDomain()
        assertEquals(setOf(CaregiverChannel.EMAIL, CaregiverChannel.SMS), domain.channels)
        assertEquals(DigestFrequency.DAILY_DIGEST, domain.digestFrequency)
    }

    private fun validMedicineEntity(
        mark: String = MarkShape.Ring.name,
        foodRelation: String = FoodRelation.AFTER.name,
        frequency: String = Frequency.DAILY.name,
        timeTokens: String = "morning",
        resolvedTimes: String = "08:00",
    ) = MedicineEntity(
        id = "m1", displayName = "Medicine", packName = "Pack", strength = "1 mg",
        form = "tablet", condition = "", mark = mark, markColor = 1L, dosePerIntake = 1f,
        foodRelation = foodRelation, frequency = frequency, weekdaysMask = 0,
        timeTokens = timeTokens, resolvedTimes = resolvedTimes, stockCount = 1,
        stockUpdatedAt = 1L, highRisk = false, paused = false, createdAt = 1L,
    )
}
