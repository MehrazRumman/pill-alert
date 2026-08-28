import 'package:flutter/material.dart';

import 'routes.dart';

/// All navigation intents, as plain methods. Screens receive this instead of the navigator so each
/// screen stays decoupled from the route table and testable in isolation.
class NavActions {
  const NavActions({
    required GlobalKey<NavigatorState> navigatorKey,
    required this.resetAddDraft,
    required this.selectTabRoute,
  }) : _navKey = navigatorKey;

  final GlobalKey<NavigatorState> _navKey;

  /// Clears the add-medicine draft. Every entry point into the flow calls this, so a half-finished
  /// medicine never leaks into the next one.
  final VoidCallback resetAddDraft;

  /// Switches the tab shell to a main-tab route.
  final ValueChanged<String> selectTabRoute;

  NavigatorState get _nav => _navKey.currentState!;

  void back() {
    if (_nav.canPop()) _nav.pop();
  }

  /// Switches the tab shell. The four tabs live in one IndexedStack, so each keeps its scroll
  /// position and state exactly as the Compose `saveState`/`restoreState` did.
  void selectTab(String route) => selectTabRoute(route);

  void finishOnboarding() => _nav.pushNamedAndRemoveUntil('/', (_) => false);

  Future<T?> _push<T>(String route, {Object? args}) =>
      _nav.pushNamed<T>(route, arguments: args);

  Future<void> openMedicine(String id) => _push(Routes.medicineDetail, args: id);
  Future<void> openInbox() => _push(Routes.inbox);
  Future<void> openRefill() => _push(Routes.refill);
  Future<void> openFamily() => _push(Routes.family);
  Future<void> openCaregiverNotify() => _push(Routes.caregiverNotify);
  Future<void> openCaregiverCode() => _push(Routes.caregiverCode);
  Future<void> openDoctorReport() => _push(Routes.doctorReport);
  Future<void> openSettings() => _push(Routes.settings);
  Future<void> openHelp() => _push(Routes.help);
  Future<void> openProfile() => _push(Routes.profile);
  Future<void> openAlarmPreview() => _push(Routes.alarmPreview);
  Future<void> openPermissionPriming() => _push(Routes.permissionPriming);
  Future<void> openAlarm(int doseId) => _push(Routes.alarmFullScreen, args: doseId);

  // Add-medicine flow
  Future<void> startAddMedicine() {
    resetAddDraft();
    return _push(Routes.addRoute);
  }

  Future<void> startScan() {
    resetAddDraft();
    return _push(Routes.addScan);
  }

  Future<void> startSearch() {
    resetAddDraft();
    return _push(Routes.addSearch);
  }

  /// Enters the flow at the timing step to edit a medicine already in the cabinet. The draft is
  /// loaded by the caller; resetting it here would wipe what it just filled in.
  Future<void> editSchedule() => _push(Routes.addTiming);

  Future<void> addScan() => _push(Routes.addScan);
  Future<void> addSearch() => _push(Routes.addSearch);
  Future<void> addTiming() => _push(Routes.addTiming);
  Future<void> addQuantity() => _push(Routes.addQuantity);
  Future<void> addReview() => _push(Routes.addReview);

  /// Leaves the add flow on the cabinet tab, where the new medicine now appears.
  void finishAddMedicine() {
    _nav.popUntil((route) => route.isFirst);
    selectTabRoute(Routes.meds);
  }
}

/// Gives every screen the navigation intents without threading them through constructors.
class NavScope extends InheritedWidget {
  const NavScope({super.key, required this.actions, required super.child});

  final NavActions actions;

  static NavActions of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavScope>();
    assert(scope != null, 'NavScope is missing above this widget');
    return scope!.actions;
  }

  @override
  bool updateShouldNotify(NavScope old) => actions != old.actions;
}

extension NavContext on BuildContext {
  NavActions get nav => NavScope.of(this);
}
