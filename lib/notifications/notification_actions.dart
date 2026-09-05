import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/repository.dart';
import '../data/settings_store.dart';
import '../domain/models.dart';
import 'alarm_scheduler.dart';

/// Action ids carried on the reminder. Kept stable: they are baked into notifications that may
/// still be sitting on the shade when the app is next updated.
const String kActionTaken = 'nirbhor.taken';
const String kActionSnooze = 'nirbhor.snooze';

/// Entry point for an action tapped while the app is not running.
///
/// This executes on a background isolate that the plugin spawns, so nothing from the running app is
/// available — the plugin registrant has to be initialised by hand before any platform channel
/// (sqflite, shared_preferences) will answer.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  handleNotificationAction(response);
}

/// Applies an action to its dose. Safe to call from either isolate.
Future<void> handleNotificationAction(NotificationResponse response) async {
  final doseId = AlarmScheduler.doseIdFromPayload(response.payload);
  if (doseId == null) return;

  switch (response.actionId) {
    case kActionTaken:
      final repo = await NirbhorRepository.get();
      await repo.markTaken(doseId, source: DoseSource.alarm);
      // The reminder is ongoing and its repeats are already armed; both have to go.
      await AlarmScheduler.clearForDose(doseId);

    case kActionSnooze:
      final repo = await NirbhorRepository.get();
      await repo.snoozeDose(doseId);
      await AlarmScheduler.clearForDose(doseId);
      // The dose now sits at a new time, so its alarm has to be laid down again. Only this dose:
      // nothing else moved, and rewriting the whole fortnight from a headless engine (whose
      // locale reads as `und`) is how every reminder used to come back in English.
      final dwm = await repo.doseWithMedicine(doseId);
      if (dwm == null) return;
      final store = await SettingsStore.load();
      final code = ui.PlatformDispatcher.instance.locale.languageCode;
      await AlarmScheduler.scheduleDose(dwm, settings: AppSettingsView.from(store, code));
  }
}
