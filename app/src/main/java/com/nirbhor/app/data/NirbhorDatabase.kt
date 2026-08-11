package com.nirbhor.app.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        MedicineEntity::class,
        DoseEntity::class,
        CaregiverEntity::class,
        AlertLogEntity::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class NirbhorDatabase : RoomDatabase() {
    abstract fun medicineDao(): MedicineDao
    abstract fun doseDao(): DoseDao
    abstract fun caregiverDao(): CaregiverDao

    companion object {
        @Volatile private var instance: NirbhorDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Older builds could race while generating a day and insert the same dose twice.
                // Keep the oldest occurrence before enforcing the invariant in SQLite.
                db.execSQL(
                    "DELETE FROM doses WHERE id NOT IN " +
                        "(SELECT MIN(id) FROM doses GROUP BY medicineId, scheduledEpochMillis)",
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS " +
                        "index_doses_medicineId_scheduledEpochMillis " +
                        "ON doses (medicineId, scheduledEpochMillis)",
                )
            }
        }

        fun get(context: Context): NirbhorDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    NirbhorDatabase::class.java,
                    "nirbhor.db",
                ).addMigrations(MIGRATION_1_2).build().also { instance = it }
            }
    }
}
