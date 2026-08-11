package com.nirbhor.app.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Medication
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.runtime.staticCompositionLocalOf
import com.nirbhor.app.AppContainer
import com.nirbhor.app.ui.components.NavTab

/** Route table. Main tabs keep the bottom nav; everything else is pushed full-screen (no nav bar). */
object Routes {
    // Main tabs
    const val TODAY = "today"       // Home timeline (2j/2b) — also renders empty (4d) / day-complete (6f)
    const val MEDS = "meds"         // Medicine cabinet (2s/2e)
    const val RECORD = "record"     // Adherence record (2t/2f)
    const val MORE = "more"         // More hub (6a)

    // Onboarding / priming
    const val ONBOARDING = "onboarding"          // 2q/2a
    const val PERMISSION_PRIMING = "priming"     // 5b

    // Pushed screens
    const val ALARM_PREVIEW = "alarm_preview"    // 2k/2c (in-app preview; real alarm is AlarmActivity)
    const val INBOX = "inbox"                    // 6b notification inbox
    const val REFILL = "refill"                  // 2u/2g refill & stock
    const val FAMILY = "family"                  // 2v/2h family & caregivers
    const val CAREGIVER_NOTIFY = "caregiver_notify" // 4a
    const val CAREGIVER_CODE = "caregiver_code"  // 6d
    const val DOCTOR_REPORT = "doctor_report"    // 6c
    const val SETTINGS = "settings"              // 2l/2i
    const val HELP = "help"
    const val MEDICINE_DETAIL = "medicine/{id}"  // 5e
    fun medicineDetail(id: String) = "medicine/$id"

    // Add-medicine flow (3a → …)
    const val ADD_ROUTE = "add/route"            // 3a route chooser
    const val ADD_SCAN = "add/scan"              // 3b scan & confirm
    const val ADD_SEARCH = "add/search"          // 3g search fallback
    const val ADD_PRESCRIPTION = "add/prescription" // 3f prescription photo
    const val ADD_TIMING = "add/timing"          // 3c when to take
    const val ADD_QUANTITY = "add/quantity"      // 3d how many
    const val ADD_REVIEW = "add/review"          // 3e review

    val mainTabs = setOf(TODAY, MEDS, RECORD, MORE)
}

/** The four bottom-nav tabs (আজ / ওষুধ / রেকর্ড / আরও). */
val navTabs = listOf(
    NavTab(Routes.TODAY, Icons.Filled.WbSunny, "আজ", "Today"),
    NavTab(Routes.MEDS, Icons.Filled.Medication, "ওষুধ", "Meds"),
    NavTab(Routes.RECORD, Icons.Filled.BarChart, "রেকর্ড", "Record"),
    NavTab(Routes.MORE, Icons.Filled.MoreHoriz, "আরও", "More"),
)

/** Gives screens access to the repository/settings without a DI framework. */
val LocalAppContainer = staticCompositionLocalOf<AppContainer> {
    error("AppContainer not provided")
}
