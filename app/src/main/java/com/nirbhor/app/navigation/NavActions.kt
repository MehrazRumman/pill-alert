package com.nirbhor.app.navigation

import androidx.navigation.NavHostController

/**
 * All navigation intents, as plain lambdas. Screens receive this instead of the [NavHostController]
 * so each screen stays decoupled from the route table and testable in isolation.
 */
class NavActions(private val nav: NavHostController) {
    fun back() { nav.popBackStack() }

    fun selectTab(route: String) {
        nav.navigate(route) {
            popUpTo(Routes.TODAY) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }

    fun finishOnboarding() {
        nav.navigate(Routes.TODAY) { popUpTo(Routes.ONBOARDING) { inclusive = true } }
    }

    fun openMedicine(id: String) = nav.navigate(Routes.medicineDetail(id))
    fun openInbox() = nav.navigate(Routes.INBOX)
    fun openRefill() = nav.navigate(Routes.REFILL)
    fun openFamily() = nav.navigate(Routes.FAMILY)
    fun openCaregiverNotify() = nav.navigate(Routes.CAREGIVER_NOTIFY)
    fun openCaregiverCode() = nav.navigate(Routes.CAREGIVER_CODE)
    fun openDoctorReport() = nav.navigate(Routes.DOCTOR_REPORT)
    fun openSettings() = nav.navigate(Routes.SETTINGS)
    fun openAlarmPreview() = nav.navigate(Routes.ALARM_PREVIEW)
    fun openPermissionPriming() = nav.navigate(Routes.PERMISSION_PRIMING)

    // Add-medicine flow
    fun startAddMedicine() = nav.navigate(Routes.ADD_ROUTE)
    fun addScan() = nav.navigate(Routes.ADD_SCAN)
    fun addSearch() = nav.navigate(Routes.ADD_SEARCH)
    fun addPrescription() = nav.navigate(Routes.ADD_PRESCRIPTION)
    fun addTiming() = nav.navigate(Routes.ADD_TIMING)
    fun addQuantity() = nav.navigate(Routes.ADD_QUANTITY)
    fun addReview() = nav.navigate(Routes.ADD_REVIEW)
    fun finishAddMedicine() {
        nav.navigate(Routes.MEDS) { popUpTo(Routes.ADD_ROUTE) { inclusive = true } }
    }
}
