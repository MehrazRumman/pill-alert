package com.nirbhor.app.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "medicines")
data class MedicineEntity(
    @PrimaryKey val id: String,
    val displayName: String,
    val packName: String,
    val strength: String,
    val form: String,
    val condition: String,
    val mark: String,           // MarkShape.name
    val markColor: Long,        // ARGB
    val dosePerIntake: Float,
    val foodRelation: String,   // FoodRelation.name
    val frequency: String,      // Frequency.name
    val weekdaysMask: Int,
    val timeTokens: String,     // csv of tokens
    val resolvedTimes: String,  // csv of "HH:mm"
    val stockCount: Int,
    val stockUpdatedAt: Long,
    val highRisk: Boolean,
    val paused: Boolean,
    val createdAt: Long,
)

@Entity(
    tableName = "doses",
    indices = [
        Index("medicineId"),
        Index("scheduledEpochMillis"),
        Index(value = ["medicineId", "scheduledEpochMillis"], unique = true),
    ],
)
data class DoseEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val medicineId: String,
    val scheduledEpochMillis: Long,
    val hour: Int,
    val minute: Int,
    val block: String,          // TimeBlock.name
    val status: String,         // DoseStatus.name
    val confirmedAt: Long?,
    val source: String?,        // DoseSource.name
)

@Entity(tableName = "caregivers")
data class CaregiverEntity(
    @PrimaryKey val id: String,
    val name: String,
    val relationship: String,
    val email: String,
    val emailVerified: Boolean,
    val phone: String,
    val channels: String,       // csv of CaregiverChannel.name
    val digestFrequency: String,
    val escalateOnSecondMiss: Boolean,
    val notifyOnMissedTwice: Boolean,
    val notifyOnOutOfStock: Boolean,
    val weeklySummary: Boolean,
)

@Entity(
    tableName = "alert_log",
    indices = [Index("caregiverId")],
)
data class AlertLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val caregiverId: String,
    val kind: String,
    val message: String,
    val sentAtMillis: Long,
    val outcome: String,
)
