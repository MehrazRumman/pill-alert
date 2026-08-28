import 'package:flutter/material.dart';

import 'data/app_scope.dart';
import 'data/repository.dart';
import 'data/settings_store.dart';
import 'domain/dose_scheduler.dart';
import 'navigation/app_root.dart';
import 'notifications/alarm_scheduler.dart';
import 'notifications/missed_dose_notifier.dart';
import 'notifications/nirbhor_notifications.dart';

/// App entry point. Builds the container, generates dose occurrences for the next two weeks from
/// whatever medicines exist, then arms reminders for the upcoming ones.
///
/// There is no demo/seed data — the app starts empty and the patient adds their own medicines.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await NirbhorRepository.get();
  final settings = await SettingsStore.load();
  final container = AppContainer(repository: repository, settings: settings);

  int? launchDoseId;
  await NirbhorNotifications.init(onTap: (response) => _handleTap(response.payload));

  final launch = await NirbhorNotifications.plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    launchDoseId = AlarmScheduler.doseIdFromPayload(launch!.notificationResponse?.payload);
  }

  runApp(NirbhorAppRoot(container: container, launchDoseId: launchDoseId));

  // Off the critical path: the first frame must not wait on two weeks of dose generation.
  unawaited(_armReminders(repository, settings));
}

Future<void> _armReminders(NirbhorRepository repo, SettingsStore settings) async {
  final today = dateOnly(DateTime.now());
  for (var i = 0; i <= 14; i++) {
    await repo.ensureDosesFor(today.add(Duration(days: i)), notify: false);
  }
  await MissedDoseNotifier.sweep(repo);
  await AlarmScheduler.rescheduleAll(
    repo,
    settings: AppSettingsView.from(settings, deviceIsBangla()),
  );
}

/// A reminder tapped while the app is already running routes straight to the alarm screen.
void _handleTap(String? payload) {
  final doseId = AlarmScheduler.doseIdFromPayload(payload);
  if (doseId == null) return;
  pendingAlarmDoseId.value = doseId;
}

/// Set when a reminder is tapped in a warm process; the app root watches it and opens the alarm.
final ValueNotifier<int?> pendingAlarmDoseId = ValueNotifier<int?>(null);

bool deviceIsBangla() =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'bn';

void unawaited(Future<void> future) {
  future.catchError((Object _) {
    // Startup work is best-effort: a failure here must not take the app down.
  });
}
