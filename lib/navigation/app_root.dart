import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_scope.dart';
import '../data/repository.dart';
import '../data/settings_store.dart';
import '../main.dart' show pendingAlarmDoseId;
import '../notifications/alarm_scheduler.dart';
import '../notifications/missed_dose_notifier.dart';
import '../theme/theme.dart';
import '../ui/components/scaffold.dart';
import '../ui/screens/add_flow_common.dart';
import '../ui/screens/add_quantity_screen.dart';
import '../ui/screens/add_review_screen.dart';
import '../ui/screens/add_route_screen.dart';
import '../ui/screens/add_scan_screen.dart';
import '../ui/screens/add_search_screen.dart';
import '../ui/screens/add_timing_screen.dart';
import '../ui/screens/alarm_preview_screen.dart';
import '../ui/screens/alarm_screen.dart';
import '../ui/screens/cabinet_screen.dart';
import '../ui/screens/caregiver_code_screen.dart';
import '../ui/screens/caregiver_notify_screen.dart';
import '../ui/screens/doctor_report_screen.dart';
import '../ui/screens/family_screen.dart';
import '../ui/screens/help_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/inbox_screen.dart';
import '../ui/screens/medicine_detail_screen.dart';
import '../ui/screens/more_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/permission_priming_screen.dart';
import '../ui/screens/record_screen.dart';
import '../ui/screens/refill_screen.dart';
import '../ui/screens/settings_screen.dart';
import 'nav_actions.dart';
import 'routes.dart';

/// App root: resolves the effective locale + time-format from settings, sets up the design theme,
/// locale scope and DI scope, and hosts the navigator. The four main tabs share one shell that
/// keeps the bottom nav; pushed screens hide it (they carry their own back chevron).
class NirbhorAppRoot extends StatefulWidget {
  const NirbhorAppRoot({
    super.key,
    required this.container,
    this.launchDoseId,
  });

  final AppContainer container;

  /// Set when the app was cold-started by tapping a reminder — the alarm screen opens over the
  /// timeline as soon as the tree is up.
  final int? launchDoseId;

  @override
  State<NirbhorAppRoot> createState() => _NirbhorAppRootState();
}

class _NirbhorAppRootState extends State<NirbhorAppRoot> with WidgetsBindingObserver {
  final _navKey = GlobalKey<NavigatorState>();
  // The tab shell owns which tab is showing. A route's page is built once and cached by the
  // navigator, so a `setState` up here would never reach it — the selection has to live inside the
  // shell and be driven through its state.
  final _tabShellKey = GlobalKey<TabShellState>();
  final _draft = AddMedicineDraft();
  late final NavActions _actions;

  /// Fixed for the life of the process. Recomputing it would hand the navigator a new start route
  /// the moment onboarding completes, which resets the back stack out from under whatever was just
  /// pushed.
  late final String _initialRoute;

  SettingsStore get _settings => widget.container.settings;
  NirbhorRepository get _repo => widget.container.repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialRoute = _settings.value.onboardingComplete ? '/' : Routes.onboarding;
    _actions = NavActions(
      navigatorKey: _navKey,
      resetAddDraft: _draft.reset,
      selectTabRoute: (route) => _tabShellKey.currentState?.select(route),
    );
    _settings.addListener(_onSettingsChanged);

    // A reminder tapped while the app is already running arrives here; a cold start arrives as
    // widget.launchDoseId. Both open the alarm over whatever the patient was looking at.
    pendingAlarmDoseId.addListener(_onPendingAlarm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doseId = widget.launchDoseId;
      if (doseId != null) _actions.openAlarm(doseId);
    });
  }

  void _onPendingAlarm() {
    final doseId = pendingAlarmDoseId.value;
    if (doseId == null) return;
    pendingAlarmDoseId.value = null;
    _actions.openAlarm(doseId);
  }

  @override
  void dispose() {
    pendingAlarmDoseId.removeListener(_onPendingAlarm);
    _settings.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _draft.dispose();
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Doses that went unanswered while the app was away are marked missed here, and their ongoing
    // reminders cleared, so the timeline is never showing a dose the record has moved past.
    unawaitedSweep();
  }

  Future<void> unawaitedSweep() async {
    await MissedDoseNotifier.sweep(_repo);
    await AlarmScheduler.rescheduleAll(
      _repo,
      settings: AppSettingsView.from(_settings, _deviceIsBangla),
    );
  }

  bool get _deviceIsBangla => ui.PlatformDispatcher.instance.locale.languageCode == 'bn';

  @override
  Widget build(BuildContext context) {
    final settings = _settings.value;
    final isBangla = settings.isBangla(_deviceIsBangla);
    final is24 = settings.is24Hour(isBangla);
    final type = buildNirbhorType(
      isBangla: isBangla,
      // The "সহজে পড়ার জন্য / bigger text" accessibility setting (up to ~1.2× per the responsive spec).
      scale: settings.biggerText ? 1.2 : 1,
    );

    return MaterialApp(
      title: 'Nirbhor',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      theme: buildMaterialTheme(type, isBangla),
      initialRoute: _initialRoute,
      onGenerateRoute: _onGenerateRoute,
      builder: (context, child) => AppScope(
        container: widget.container,
        child: NirbhorTheme(
          type: type,
          isBangla: isBangla,
          is24Hour: is24,
          child: AddDraftScope(
            draft: _draft,
            child: NavScope(
              actions: _actions,
              // The palette is light-only in both system themes, so the status bar icons are
              // forced dark rather than following the system's night setting.
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                  systemNavigationBarColor: Color(0xFFFFFFFF),
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = TabShell(key: _tabShellKey);
      case Routes.onboarding:
        page = const OnboardingScreen();
      case Routes.permissionPriming:
        page = const PermissionPrimingScreen();
      case Routes.alarmPreview:
        page = const AlarmPreviewScreen();
      case Routes.alarmFullScreen:
        page = AlarmScreen(doseId: settings.arguments as int?);
      case Routes.inbox:
        page = const InboxScreen();
      case Routes.refill:
        page = const RefillScreen();
      case Routes.family:
        page = const FamilyScreen();
      case Routes.caregiverNotify:
        page = const CaregiverNotifyScreen();
      case Routes.caregiverCode:
        page = const CaregiverCodeScreen();
      case Routes.doctorReport:
        page = const DoctorReportScreen();
      case Routes.settings:
        page = const SettingsScreen();
      case Routes.help:
        page = const HelpScreen();
      case Routes.medicineDetail:
        page = MedicineDetailScreen(medicineId: settings.arguments as String? ?? '');
      case Routes.addRoute:
        page = const AddRouteScreen();
      case Routes.addScan:
        page = const AddScanScreen();
      case Routes.addSearch:
        page = const AddSearchScreen();
      case Routes.addTiming:
        page = const AddTimingScreen();
      case Routes.addQuantity:
        page = const AddQuantityScreen();
      case Routes.addReview:
        page = const AddReviewScreen();
      default:
        return null;
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}

/// The four main tabs. They live in one [IndexedStack] so switching tabs keeps each one's scroll
/// position and in-progress state — the Compose original's `saveState`/`restoreState`.
class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => TabShellState();
}

class TabShellState extends State<TabShell> {
  static const _order = [Routes.today, Routes.meds, Routes.record, Routes.more];

  String _currentRoute = Routes.today;

  /// Switches tabs. Called both by a nav-bar tap and by [NavActions.selectTab], so a screen that
  /// finishes a flow (adding a medicine, say) can land the patient on the right tab.
  void select(String route) {
    if (!_order.contains(route) || route == _currentRoute) return;
    setState(() => _currentRoute = route);
  }

  @override
  Widget build(BuildContext context) {
    final index = _order.indexOf(_currentRoute).clamp(0, _order.length - 1);
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          CabinetScreen(),
          RecordScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        tabs: navTabs,
        currentRoute: _currentRoute,
        onSelect: (tab) => select(tab.route),
      ),
    );
  }
}
