package com.nirbhor.app.data

import com.nirbhor.app.domain.testMedicine
import org.junit.Assert.assertEquals
import org.junit.Test

class AdherenceCounterTest {
    @Test fun emptyWindowIsZeroPercent() {
        assertEquals(0, NirbhorRepository.AdherenceWindow(0, 0, 0, 0, 0, 0).percent)
    }

    @Test fun lateDosesCountAsTakenButNotOnTime() {
        val window = NirbhorRepository.AdherenceWindow(
            taken = 4,
            takenLate = 1,
            missed = 1,
            skipped = 1,
            total = 6,
            streakDays = 0,
        )
        assertEquals(50, window.percent)
    }

    @Test fun perMedicinePercentExcludesLateDoses() {
        val adherence = NirbhorRepository.MedAdherence(testMedicine(), taken = 3, takenLate = 1, total = 4)
        assertEquals(50, adherence.percent)
    }

    @Test fun percentagesUseWholeNumberFloorWithoutOverflow() {
        assertEquals(66, NirbhorRepository.AdherenceWindow(2, 0, 1, 0, 3, 0).percent)
        assertEquals(100, NirbhorRepository.AdherenceWindow(2, 0, 0, 0, 2, 0).percent)
    }
}
