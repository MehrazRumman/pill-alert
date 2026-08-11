package com.nirbhor.app.domain

import com.nirbhor.app.ui.marks.MarkShape
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AddMedicineDraftTest {
    @Test fun convertsAllEnteredFieldsToMedicine() {
        val draft = AddMedicineDraft().apply {
            displayName = "নাপা"
            packName = "Napa"
            strength = "500 mg"
            form = "tablet"
            condition = "fever"
            mark = MarkShape.Capsule
            markColor = 123L
            dosePerIntake = 0.5f
            foodRelation = FoodRelation.BEFORE
            frequency = Frequency.WEEKLY
            weekdaysMask = 5
            timeTokens = listOf("morning", "night")
            resolvedTimes = listOf("07:30", "22:15")
            stockCount = 12
            highRisk = true
        }
        val medicine = draft.toMedicine()
        assertEquals("নাপা", medicine.displayName)
        assertEquals("Napa", medicine.packName)
        assertEquals(listOf("07:30", "22:15"), medicine.resolvedTimes)
        assertEquals(Frequency.WEEKLY, medicine.frequency)
        assertEquals(5, medicine.weekdaysMask)
        assertEquals(0.5f, medicine.dosePerIntake)
        assertTrue(medicine.highRisk)
        assertFalse(medicine.paused)
        assertTrue(medicine.id.startsWith("m-"))
    }

    @Test fun blankDisplayNameFallsBackToPackName() {
        val draft = AddMedicineDraft().apply { packName = "Napa" }
        assertEquals("Napa", draft.toMedicine().displayName)
    }

    @Test fun emptyResolvedTimesUseDefaultsForEveryToken() {
        val draft = AddMedicineDraft().apply {
            timeTokens = listOf("morning", "noon", "night")
            resolvedTimes = emptyList()
        }
        assertEquals(listOf("08:00", "14:00", "21:00"), draft.toMedicine().resolvedTimes)
    }

    @Test fun generatedIdsAreUnique() {
        val draft = AddMedicineDraft()
        assertNotEquals(draft.toMedicine().id, draft.toMedicine().id)
    }

    @Test fun resetRestoresEveryMutableField() {
        val draft = AddMedicineDraft().apply {
            displayName = "Changed"; packName = "Changed"; strength = "1 mg"; form = "syrup"
            condition = "x"; mark = MarkShape.Triangle; markColor = 1L; dosePerIntake = 3f
            foodRelation = FoodRelation.AFTER; frequency = Frequency.WEEKLY; weekdaysMask = 127
            timeTokens = listOf("night"); resolvedTimes = listOf("23:00"); stockCount = 99; highRisk = true
        }
        draft.reset()
        assertEquals("", draft.displayName)
        assertEquals("", draft.packName)
        assertEquals(MarkShape.FilledCircle, draft.mark)
        assertEquals(1f, draft.dosePerIntake)
        assertEquals(FoodRelation.NONE, draft.foodRelation)
        assertEquals(Frequency.DAILY, draft.frequency)
        assertEquals(0, draft.weekdaysMask)
        assertTrue(draft.timeTokens.isEmpty())
        assertTrue(draft.resolvedTimes.isEmpty())
        assertEquals(0, draft.stockCount)
        assertFalse(draft.highRisk)
    }
}
