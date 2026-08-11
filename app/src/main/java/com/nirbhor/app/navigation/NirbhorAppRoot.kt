package com.nirbhor.app.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.nirbhor.app.NirbhorApp
import com.nirbhor.app.domain.AddMedicineDraft
import com.nirbhor.app.domain.AppSettings
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.ui.components.BottomNavBar
import com.nirbhor.app.ui.i18n.LocalIs24Hour
import com.nirbhor.app.ui.i18n.LocalIsBangla
import com.nirbhor.app.ui.screens.AddPrescriptionScreen
import com.nirbhor.app.ui.screens.AddQuantityScreen
import com.nirbhor.app.ui.screens.AddReviewScreen
import com.nirbhor.app.ui.screens.AddRouteScreen
import com.nirbhor.app.ui.screens.AddScanScreen
import com.nirbhor.app.ui.screens.AddSearchScreen
import com.nirbhor.app.ui.screens.AddTimingScreen
import com.nirbhor.app.ui.screens.AlarmPreviewScreen
import com.nirbhor.app.ui.screens.CabinetScreen
import com.nirbhor.app.ui.screens.CaregiverCodeScreen
import com.nirbhor.app.ui.screens.CaregiverNotifyScreen
import com.nirbhor.app.ui.screens.DoctorReportScreen
import com.nirbhor.app.ui.screens.FamilyScreen
import com.nirbhor.app.ui.screens.HomeScreen
import com.nirbhor.app.ui.screens.InboxScreen
import com.nirbhor.app.ui.screens.MedicineDetailScreen
import com.nirbhor.app.ui.screens.MoreScreen
import com.nirbhor.app.ui.screens.OnboardingScreen
import com.nirbhor.app.ui.screens.PermissionPrimingScreen
import com.nirbhor.app.ui.screens.RecordScreen
import com.nirbhor.app.ui.screens.RefillScreen
import com.nirbhor.app.ui.screens.SettingsScreen
import com.nirbhor.app.ui.theme.NirbhorTheme
import java.util.Locale

/**
 * App root: resolves the effective locale + time-format from settings, sets up the design theme and
 * locale composition-locals, and hosts the NavHost. The four main tabs keep the bottom nav; pushed
 * screens hide it (they carry their own back chevron).
 */
@Composable
fun NirbhorAppRoot() {
    val context = LocalContext.current
    val container = remember { (context.applicationContext as NirbhorApp).container }
    val settings by container.settings.settings.collectAsStateWithLifecycle(initialValue = AppSettings())

    val deviceIsBangla = remember { Locale.getDefault().language == "bn" }
    val isBangla = settings.isBangla(deviceIsBangla)
    val is24 = settings.is24Hour(isBangla)

    val draft = remember { AddMedicineDraft() }
    val navController = rememberNavController()
    val actions = remember(navController) { NavActions(navController) }

    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomNav = currentRoute in Routes.mainTabs

    val start = if (settings.onboardingComplete) Routes.TODAY else Routes.ONBOARDING

    NirbhorTheme(isBangla = isBangla, biggerText = settings.biggerText) {
        CompositionLocalProvider(
            LocalIsBangla provides isBangla,
            LocalIs24Hour provides is24,
            LocalAppContainer provides container,
            LocalAddDraft provides draft,
        ) {
            Scaffold(
                containerColor = NirbhorTheme.colors.paper,
                bottomBar = {
                    if (showBottomNav) {
                        BottomNavBar(
                            tabs = navTabs,
                            currentRoute = currentRoute,
                            isBangla = isBangla,
                            onSelect = { actions.selectTab(it.route) },
                        )
                    }
                },
            ) { inner ->
                val contentModifier = if (showBottomNav) {
                    Modifier.fillMaxSize().padding(bottom = inner.calculateBottomPadding())
                } else {
                    Modifier.fillMaxSize()
                }
                Box(contentModifier.consumeWindowInsets(PaddingValues())) {
                    NirbhorNavHost(navController, actions, start)
                }
            }
        }
    }
}

@Composable
private fun NirbhorNavHost(
    navController: androidx.navigation.NavHostController,
    actions: NavActions,
    startDestination: String,
) {
    NavHost(navController = navController, startDestination = startDestination) {
        composable(Routes.ONBOARDING) { OnboardingScreen(actions) }
        composable(Routes.PERMISSION_PRIMING) { PermissionPrimingScreen(actions) }

        composable(Routes.TODAY) { HomeScreen(actions) }
        composable(Routes.MEDS) { CabinetScreen(actions) }
        composable(Routes.RECORD) { RecordScreen(actions) }
        composable(Routes.MORE) { MoreScreen(actions) }

        composable(Routes.ALARM_PREVIEW) { AlarmPreviewScreen(actions) }
        composable(Routes.INBOX) { InboxScreen(actions) }
        composable(Routes.REFILL) { RefillScreen(actions) }
        composable(Routes.FAMILY) { FamilyScreen(actions) }
        composable(Routes.CAREGIVER_NOTIFY) { CaregiverNotifyScreen(actions) }
        composable(Routes.CAREGIVER_CODE) { CaregiverCodeScreen(actions) }
        composable(Routes.DOCTOR_REPORT) { DoctorReportScreen(actions) }
        composable(Routes.SETTINGS) { SettingsScreen(actions) }

        composable(
            Routes.MEDICINE_DETAIL,
            arguments = listOf(navArgument("id") { type = NavType.StringType }),
        ) { entry ->
            MedicineDetailScreen(entry.arguments?.getString("id").orEmpty(), actions)
        }

        composable(Routes.ADD_ROUTE) { AddRouteScreen(actions) }
        composable(Routes.ADD_SCAN) { AddScanScreen(actions) }
        composable(Routes.ADD_SEARCH) { AddSearchScreen(actions) }
        composable(Routes.ADD_PRESCRIPTION) { AddPrescriptionScreen(actions) }
        composable(Routes.ADD_TIMING) { AddTimingScreen(actions) }
        composable(Routes.ADD_QUANTITY) { AddQuantityScreen(actions) }
        composable(Routes.ADD_REVIEW) { AddReviewScreen(actions) }
    }
}
