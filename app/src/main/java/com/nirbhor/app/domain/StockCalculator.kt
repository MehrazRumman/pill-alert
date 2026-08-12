package com.nirbhor.app.domain

/** Shared stock math so add, cabinet, refill, and alerts cannot disagree. */
object StockCalculator {
    fun estimatedDays(
        stockCount: Int,
        dosePerIntake: Float,
        timesPerScheduledDay: Int,
        frequency: Frequency,
        weekdaysMask: Int,
        paused: Boolean = false,
    ): Int? {
        if (paused || stockCount < 0 || dosePerIntake <= 0f || timesPerScheduledDay <= 0) return null
        val scheduledDaysPerWeek = when (frequency) {
            Frequency.DAILY -> 7f
            Frequency.ALTERNATE -> 3.5f
            Frequency.WEEKDAYS, Frequency.WEEKLY -> Integer.bitCount(weekdaysMask and 0x7F).toFloat()
        }
        if (scheduledDaysPerWeek <= 0f) return null
        val averagePerDay = dosePerIntake * timesPerScheduledDay * scheduledDaysPerWeek / 7f
        return (stockCount.coerceAtLeast(0) / averagePerDay).toInt()
    }

    fun estimatedDays(medicine: Medicine): Int? = estimatedDays(
        stockCount = medicine.stockCount,
        dosePerIntake = medicine.dosePerIntake,
        timesPerScheduledDay = medicine.timeTokens.size,
        frequency = medicine.frequency,
        weekdaysMask = medicine.weekdaysMask,
        paused = medicine.paused,
    )
}
