package com.nirbhor.app.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.nirbhor.app.domain.DoseSource
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.FoodRelation
import com.nirbhor.app.domain.Frequency
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.ui.marks.MarkShape
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class DaoIntegrationTest {
    private lateinit var db: NirbhorDatabase

    @Before fun createDatabase() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, NirbhorDatabase::class.java)
            .allowMainThreadQueries()
            .build()
    }

    @After fun closeDatabase() = db.close()

    @Test fun duplicateMedicineAndEpochDoseIsIgnored() = runBlocking {
        db.medicineDao().upsert(medicine())
        val dose = dose()
        db.doseDao().insertAll(listOf(dose))
        db.doseDao().insertAll(listOf(dose))
        assertEquals(1, db.doseDao().getBetween(0, Long.MAX_VALUE).size)
    }

    @Test fun conditionalStatusUpdatePreventsSecondConfirmation() = runBlocking {
        db.medicineDao().upsert(medicine())
        db.doseDao().insertAll(listOf(dose()))
        val stored = db.doseDao().getBetween(0, Long.MAX_VALUE).single()
        val first = db.doseDao().setStatusIf(
            stored.id, DoseStatus.TAKEN.name, 200L, DoseSource.HOME.name,
            listOf(DoseStatus.UPCOMING.name),
        )
        val second = db.doseDao().setStatusIf(
            stored.id, DoseStatus.TAKEN_LATE.name, 300L, DoseSource.ALARM.name,
            listOf(DoseStatus.UPCOMING.name),
        )
        assertEquals(1, first)
        assertEquals(0, second)
        assertEquals(DoseStatus.TAKEN.name, db.doseDao().get(stored.id)?.status)
    }

    @Test fun stockAdjustmentNeverDropsBelowZero() = runBlocking {
        db.medicineDao().upsert(medicine(stockCount = 2))
        db.medicineDao().adjustStock("m1", -10, 500L)
        val stored = db.medicineDao().get("m1")
        assertEquals(0, stored?.stockCount)
        assertEquals(500L, stored?.stockUpdatedAt)
    }

    @Test fun snoozeCannotReviveDoseCompletedByAnotherAction() = runBlocking {
        db.medicineDao().upsert(medicine())
        db.doseDao().insertAll(listOf(dose()))
        val stored = db.doseDao().getBetween(0, Long.MAX_VALUE).single()
        db.doseDao().setStatusIf(
            stored.id, DoseStatus.TAKEN.name, 200L, DoseSource.HOME.name,
            listOf(DoseStatus.UPCOMING.name),
        )
        val changed = db.doseDao().snoozeIfUpcoming(stored.id, 999L, 9, 30)
        assertEquals(0, changed)
        assertEquals(DoseStatus.TAKEN.name, db.doseDao().get(stored.id)?.status)
        assertEquals(100L, db.doseDao().get(stored.id)?.scheduledEpochMillis)
    }

    @Test fun deletingMedicineDosesRemovesOnlyThatMedicinesRows() = runBlocking {
        db.medicineDao().upsert(medicine("m1"))
        db.medicineDao().upsert(medicine("m2"))
        db.doseDao().insertAll(listOf(dose("m1", 100L), dose("m2", 200L)))
        db.doseDao().deleteForMedicine("m1")
        val remaining = db.doseDao().getBetween(0, Long.MAX_VALUE)
        assertEquals(listOf("m2"), remaining.map { it.medicineId })
    }

    private fun medicine(id: String = "m1", stockCount: Int = 10) = MedicineEntity(
        id = id, displayName = "Medicine", packName = "Pack", strength = "500 mg",
        form = "tablet", condition = "", mark = MarkShape.FilledCircle.name,
        markColor = 1L, dosePerIntake = 1f, foodRelation = FoodRelation.NONE.name,
        frequency = Frequency.DAILY.name, weekdaysMask = 0, timeTokens = "morning",
        resolvedTimes = "08:00", stockCount = stockCount, stockUpdatedAt = 0L,
        highRisk = false, paused = false, createdAt = 0L,
    )

    private fun dose(medicineId: String = "m1", epoch: Long = 100L) = DoseEntity(
        medicineId = medicineId, scheduledEpochMillis = epoch, hour = 8, minute = 0,
        block = TimeBlock.MORNING.name, status = DoseStatus.UPCOMING.name,
        confirmedAt = null, source = null,
    )
}
