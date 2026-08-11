package com.nirbhor.app.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        MedicineEntity::class,
        DoseEntity::class,
        CaregiverEntity::class,
        AlertLogEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class NirbhorDatabase : RoomDatabase() {
    abstract fun medicineDao(): MedicineDao
    abstract fun doseDao(): DoseDao
    abstract fun caregiverDao(): CaregiverDao

    companion object {
        @Volatile private var instance: NirbhorDatabase? = null

        fun get(context: Context): NirbhorDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    NirbhorDatabase::class.java,
                    "nirbhor.db",
                ).fallbackToDestructiveMigration().build().also { instance = it }
            }
    }
}
