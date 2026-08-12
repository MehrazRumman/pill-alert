package com.nirbhor.app.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ModelsTest {
    @Test fun emptyTimelineBlockIsNeitherTakenNorDue() {
        val block = TimelineBlock(TimeBlock.MORNING, 8, 0, emptyList())
        assertFalse(block.allTaken)
        assertFalse(block.anyDueNow)
    }

    @Test fun takenAndTakenLateBothCountAsComplete() {
        val medicine = testMedicine()
        val block = TimelineBlock(
            TimeBlock.MORNING,
            8,
            0,
            listOf(
                DoseWithMedicine(testDose(1, DoseStatus.TAKEN), medicine),
                DoseWithMedicine(testDose(2, DoseStatus.TAKEN_LATE), medicine),
            ),
        )
        assertTrue(block.allTaken)
        assertFalse(block.anyDueNow)
    }

    @Test fun mixedTimelineReportsUpcomingAndNotComplete() {
        val medicine = testMedicine()
        val block = TimelineBlock(
            TimeBlock.MORNING,
            8,
            0,
            listOf(
                DoseWithMedicine(testDose(1, DoseStatus.TAKEN), medicine),
                DoseWithMedicine(testDose(2, DoseStatus.UPCOMING), medicine),
            ),
        )
        assertFalse(block.allTaken)
        assertTrue(block.anyDueNow)
    }

    @Test fun skippedDoseResolvesBlockWithoutPretendingItWasTaken() {
        val medicine = testMedicine()
        val block = TimelineBlock(
            TimeBlock.MORNING,
            8,
            0,
            listOf(
                DoseWithMedicine(testDose(1, DoseStatus.TAKEN), medicine),
                DoseWithMedicine(testDose(2, DoseStatus.SKIPPED), medicine),
            ),
        )
        assertFalse(block.allTaken)
        assertTrue(block.allResolved)
        assertFalse(block.anyDueNow)
    }

    @Test fun missedDoseDoesNotResolveBlock() {
        val medicine = testMedicine()
        val block = TimelineBlock(
            TimeBlock.MORNING,
            8,
            0,
            listOf(DoseWithMedicine(testDose(1, DoseStatus.MISSED), medicine)),
        )
        assertFalse(block.allResolved)
    }

    @Test fun dailyProgressHandlesEmptyNormalAndOvercompleteValues() {
        assertEquals(0, DailyProgress(0, 0).remaining)
        assertEquals(0f, DailyProgress(0, 0).fraction)
        assertEquals(2, DailyProgress(1, 3).remaining)
        assertEquals(1f / 3f, DailyProgress(1, 3).fraction)
        assertEquals(0, DailyProgress(5, 3).remaining)
    }
}
