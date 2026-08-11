package com.nirbhor.app.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface MedicineDao {
    @Query("SELECT * FROM medicines ORDER BY createdAt ASC")
    fun observeAll(): Flow<List<MedicineEntity>>

    @Query("SELECT * FROM medicines WHERE id = :id")
    fun observe(id: String): Flow<MedicineEntity?>

    @Query("SELECT * FROM medicines WHERE id = :id")
    suspend fun get(id: String): MedicineEntity?

    @Query("SELECT * FROM medicines")
    suspend fun getAll(): List<MedicineEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(medicine: MedicineEntity)

    @Update
    suspend fun update(medicine: MedicineEntity)

    @Query("UPDATE medicines SET stockCount = :count, stockUpdatedAt = :updatedAt WHERE id = :id")
    suspend fun setStock(id: String, count: Int, updatedAt: Long)

    @Query("DELETE FROM medicines WHERE id = :id")
    suspend fun delete(id: String)

    @Query("UPDATE medicines SET stockCount = MAX(0, stockCount + :delta), stockUpdatedAt = :updatedAt WHERE id = :id")
    suspend fun adjustStock(id: String, delta: Int, updatedAt: Long)

    @Query("SELECT COUNT(*) FROM medicines")
    suspend fun count(): Int
}

@Dao
interface DoseDao {
    @Query("SELECT * FROM doses WHERE scheduledEpochMillis BETWEEN :startMillis AND :endMillis ORDER BY scheduledEpochMillis ASC")
    fun observeBetween(startMillis: Long, endMillis: Long): Flow<List<DoseEntity>>

    @Query("SELECT * FROM doses WHERE scheduledEpochMillis BETWEEN :startMillis AND :endMillis ORDER BY scheduledEpochMillis ASC")
    suspend fun getBetween(startMillis: Long, endMillis: Long): List<DoseEntity>

    @Query("SELECT * FROM doses WHERE id = :id")
    suspend fun get(id: Long): DoseEntity?

    @Query("SELECT * FROM doses WHERE medicineId = :medicineId AND scheduledEpochMillis BETWEEN :startMillis AND :endMillis")
    suspend fun getForMedicineBetween(medicineId: String, startMillis: Long, endMillis: Long): List<DoseEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(doses: List<DoseEntity>)

    @Update
    suspend fun update(dose: DoseEntity)

    @Query("UPDATE doses SET status = :status, confirmedAt = :confirmedAt, source = :source WHERE id = :id AND status IN (:allowedStatuses)")
    suspend fun setStatusIf(
        id: Long,
        status: String,
        confirmedAt: Long?,
        source: String?,
        allowedStatuses: List<String>,
    ): Int

    @Query("DELETE FROM doses WHERE medicineId = :medicineId AND scheduledEpochMillis >= :fromMillis AND status = 'UPCOMING'")
    suspend fun deleteUpcomingForMedicine(medicineId: String, fromMillis: Long)

    @Query("DELETE FROM doses WHERE medicineId = :medicineId")
    suspend fun deleteForMedicine(medicineId: String)

    @Query("UPDATE doses SET status = 'MISSED' WHERE status = 'UPCOMING' AND scheduledEpochMillis < :cutoffMillis")
    suspend fun markOverdue(cutoffMillis: Long): Int

    @Query("SELECT COUNT(*) FROM doses WHERE scheduledEpochMillis BETWEEN :startMillis AND :endMillis")
    suspend fun countBetween(startMillis: Long, endMillis: Long): Int
}

@Dao
interface CaregiverDao {
    @Query("SELECT * FROM caregivers LIMIT 1")
    fun observePrimary(): Flow<CaregiverEntity?>

    @Query("SELECT * FROM caregivers")
    suspend fun getAll(): List<CaregiverEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(caregiver: CaregiverEntity)

    @Query("DELETE FROM caregivers WHERE id = :id")
    suspend fun delete(id: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addAlert(alert: AlertLogEntity)

    @Query("SELECT * FROM alert_log ORDER BY sentAtMillis DESC LIMIT :limit")
    fun observeAlerts(limit: Int): Flow<List<AlertLogEntity>>
}
