import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'data/app_scope.dart';
import 'data/repository.dart';
import 'data/settings_store.dart';
import 'domain/dose_scheduler.dart';
import 'navigation/app_root.dart';
import 'notifications/alarm_scheduler.dart';
import 'notifications/missed_dose_notifier.dart';
import 'notifications/nirbhor_notifications.dart';
import 'notifications/notification_actions.dart';

/// App entry point. Builds the container, generates dose occurrences for the next two weeks from
/// whatever medicines exist, then arms reminders for the upcoming ones.
///
/// There is no demo/seed data — the app starts empty and the patient adds their own medicines.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NirbhorRepository repository;
  final SettingsStore settings;
  try {
    repository = await NirbhorRepository.get();
    settings = await SettingsStore.load();
  } catch (error, stack) {
    // A corrupt database or a full disk here would otherwise leave the process sitting on the
    // launch theme forever — the same blank-screen failure described below, with nothing to read.
    debugPrint('Storage failed to open: $error\n$stack');
    runApp(const _StorageFailureApp());
    return;
  }
  final container = AppContainer(repository: repository, settings: settings);

  int? launchDoseId;
  try {
    await NirbhorNotifications.init(
      onTap: _onNotificationResponse,
      onBackgroundTap: onBackgroundNotificationAction,
    );

    final launch = await NirbhorNotifications.plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchDoseId = AlarmScheduler.doseIdFromPayload(launch!.notificationResponse?.payload);
    }
  } catch (error, stack) {
    // Nothing set up here is worth a blank screen. An uncaught throw before runApp leaves the
    // process sitting on the launch theme with no Flutter tree and no crash dialog — which is
    // exactly how a resource-shrunk ic_stat_nirbhor bricked a release build. Reminders degrade,
    // the app still opens.
    debugPrint('Notification init failed; continuing without it: $error\n$stack');
  }

  runApp(NirbhorAppRoot(container: container, launchDoseId: launchDoseId));

  // Off the critical path: the first frame must not wait on two weeks of dose generation.
  unawaited(_armReminders(repository, settings));
}

Future<void> _armReminders(NirbhorRepository repo, SettingsStore settings) async {
  final today = dateOnly(DateTime.now());
  for (var i = 0; i <= 14; i++) {
    await repo.ensureDosesFor(addDays(today, i), notify: false);
  }
  await MissedDoseNotifier.sweep(repo);
  await AlarmScheduler.rescheduleAll(
    repo,
    settings: AppSettingsView.from(settings, deviceLanguageCode()),
  );
}

/// A reminder answered while the app is running. An action button resolves the dose in place; a tap
/// on the notification body opens the alarm screen instead.
void _onNotificationResponse(NotificationResponse response) {
  if (response.actionId != null && response.actionId!.isNotEmpty) {
    unawaited(handleNotificationAction(response));
    return;
  }
  final doseId = AlarmScheduler.doseIdFromPayload(response.payload);
  if (doseId == null) return;
  pendingAlarmDoseId.value = doseId;
}

/// Set when a reminder is tapped in a warm process; the app root watches it and opens the alarm.
final ValueNotifier<int?> pendingAlarmDoseId = ValueNotifier<int?>(null);

String deviceLanguageCode() =>
    ui.PlatformDispatcher.instance.locale.languageCode;

/// Shown when local storage cannot be opened at all. Bilingual and font-free on purpose: the
/// theme, locale and font machinery all sit behind the settings that failed to load.
class _StorageFailureApp extends StatelessWidget {
  const _StorageFailureApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'অ্যাপের তথ্য খোলা যাচ্ছে না। ফোন রিস্টার্ট করে আবার চেষ্টা করুন।\n\n'
                "The app's data could not be opened. Restart the phone and try again.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
            ),
          ),
        ),
      );
}

void unawaited(Future<void> future) {
  future.catchError((Object _) {
    // Startup work is best-effort: a failure here must not take the app down.
  });
}
