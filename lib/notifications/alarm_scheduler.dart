import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/repository.dart';
import '../data/settings_store.dart';
import '../i18n/app_locale.dart';
import '../i18n/translations.dart';
import '../domain/dose_scheduler.dart';
import '../domain/models.dart';
import '../i18n/numerals.dart';
import 'nirbhor_notifications.dart';
import 'notification_actions.dart';

/// Schedules exact alarms for upcoming doses (README > Alarms: full-screen intent at each dose
/// time). Every upcoming dose in the scheduling window gets its own exact alarm keyed by dose id,
/// and this is re-run after any change (dose taken, medicine added, boot).
///
/// Where the Kotlin build re-armed each repeat from a BroadcastReceiver as it fired, here all the
/// repeats for a dose are laid down at scheduling time and cancelled together when the dose is
/// answered — Dart has no code running at alarm time to re-arm from, and the patient-visible result
/// (a reminder every N minutes, at most `repeatMax` times, stopping the moment they confirm) is the
/// same.
class AlarmScheduler {
  AlarmScheduler._();

  static const int _scheduleDays = 15;

  /// Notification ids are derived from the dose id so a dose's reminder and all of its repeats can
  /// be cancelled without storing anything. Slot 0 is the reminder itself, 1..repeatMax the
  /// repeats, and the last slot the missed-dose check.
  static const int _slots = 16;
  static const int _missCheckSlot = _slots - 1;

  static int notificationId(int doseId, int slot) => (doseId * _slots + slot) & 0x3FFFFFFF;

  static const String _payloadPrefix = 'dose:';

  static String payloadFor(int doseId) => '$_payloadPrefix$doseId';

  /// Parses the payload carried by a reminder notification back to its dose id.
  static int? doseIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    return int.tryParse(payload.substring(_payloadPrefix.length));
  }

  /// Answering from the shade is the common case: an ongoing reminder the patient cannot swipe away
  /// and cannot answer without opening the app is the shape of a problem, not a reminder.
  static List<AndroidNotificationAction> _actions(AppLocale locale) => [
        AndroidNotificationAction(
          kActionTaken,
          trIn(locale, 'খেয়েছি', "I've taken it"),
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          kActionSnooze,
          trIn(locale, 'পরে', 'Later', hi: 'बाद में', es: 'Más tarde'),
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

  static NotificationDetails _reminderDetails({
    required bool fullScreen,
    required AppLocale locale,
  }) => NotificationDetails(
        android: AndroidNotificationDetails(
          NirbhorNotifications.channelReminders,
          'মনে করিয়ে দেওয়া',
          channelDescription: 'ওষুধ খাওয়ার সময় হলে জানানো হয়',
          icon: kNotificationIcon,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: fullScreen,
          // Posted ongoing so it cannot be swiped away unanswered — which is exactly why every
          // path that resolves a dose must call [clearForDose].
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          playSound: true,
          sound: NirbhorNotifications.alarmSound,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          vibrationPattern: NirbhorNotifications.vibrationPattern,
          // Mirrors NirbhorColors.calm. Cannot reference the token: this sits in a
          // const NotificationDetails, and the token fields are final, not const.
          color: Color(0xFF1F6B70),
          actions: _actions(locale),
        ),
      );

  static NotificationDetails get _missedDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          NirbhorNotifications.channelMissed,
          'বাদ পড়া ডোজ',
          channelDescription: 'নির্ধারিত ওষুধের ডোজ খাওয়া না হলে জানানো হয়',
          icon: kNotificationIcon,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
          color: Color(0xFFB4652F), // Mirrors NirbhorColors.warm — see note above.
        ),
      );

  static Future<AndroidScheduleMode> _mode() async =>
      await NirbhorNotifications.canScheduleExact()
          // Still wake the device when exact-alarm access is unavailable. Android then chooses the
          // nearest battery-friendly delivery time.
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

  static Future<void> _scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required NotificationDetails details,
    required String payload,
    required AndroidScheduleMode mode,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    try {
      await NirbhorNotifications.plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    } catch (_) {
      // Exact-alarm access can be revoked between the check above and this call; an inexact
      // reminder is far better than none.
      try {
        await NirbhorNotifications.plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        // Nothing further to try; the in-app timeline still shows the dose as due.
      }
    }
  }

  /// Arms one dose: the reminder, its repeats, and the missed-dose check.
  static Future<void> scheduleDose(
    DoseWithMedicine item, {
    required AppSettingsView settings,
    AndroidScheduleMode? mode,
  }) async {
    final scheduleMode = mode ?? await _mode();
    final dose = item.dose;
    final medicine = item.medicine;
    final at = dose.scheduledAt;

    final time = Numerals.time(dose.hour, dose.minute, settings.isBangla, settings.is24Hour);
    final title = trIn(settings.locale, 'ওষুধ খাওয়ার সময়', 'Time for your medicine',
        hi: 'दवा लेने का समय', es: 'Hora de su medicamento');
    final qty = Numerals.quantity(medicine.dosePerIntake, settings.isBangla);
    final body = settings.isBangla
        ? '${medicine.displayName} · $qty${medicine.form.isEmpty ? '' : ' ${medicine.form}'} · $time'
        : '${medicine.displayName} · $qty${medicine.form.isEmpty ? '' : ' ${medicine.form}'} · $time';

    await _scheduleAt(
      id: notificationId(dose.id, 0),
      when: at,
      title: title,
      body: body,
      details: _reminderDetails(
        fullScreen: settings.fullScreenAlarm,
        locale: settings.locale,
      ),
      payload: payloadFor(dose.id),
      mode: scheduleMode,
    );

    for (var i = 1; i <= settings.repeatMax && i < _missCheckSlot; i++) {
      await _scheduleAt(
        id: notificationId(dose.id, i),
        when: at.add(Duration(minutes: settings.repeatEveryMinutes * i)),
        title: title,
        body: settings.isBangla
            ? '$body — এখনও জানানো হয়নি'
            : '$body — ${trIn(settings.locale, '', 'still unanswered', hi: 'अब तक कोई जवाब नहीं', es: 'aún sin respuesta')}',
        details: _reminderDetails(
          fullScreen: settings.fullScreenAlarm,
          locale: settings.locale,
        ),
        payload: payloadFor(dose.id),
        mode: scheduleMode,
      );
    }

    // Checks an unanswered dose after the grace period, independently of repeat settings.
    await _scheduleAt(
      id: notificationId(dose.id, _missCheckSlot),
      when: at.add(const Duration(minutes: 31)),
      title: trIn(settings.locale, 'ওষুধের ডোজ বাদ পড়েছে', 'Medicine dose missed',
          hi: 'दवा की खुराक छूट गई', es: 'Dosis de medicamento saltada'),
      body: settings.isBangla
          ? '${medicine.displayName} · $time — খাওয়া হয়ে থাকলে অ্যাপে জানান'
          : '${medicine.displayName} · $time — ${trIn(settings.locale, '', 'open the app if you took it', hi: 'ली हो तो ऐप में बताएँ', es: 'abra la app si ya la tomó')}',
      details: _missedDetails,
      payload: payloadFor(dose.id),
      mode: scheduleMode,
    );
  }

  /// Reschedules alarms for all upcoming doses. Safe to call often.
  static Future<void> rescheduleAll(
    NirbhorRepository repo, {
    required AppSettingsView settings,
  }) async {
    final today = dateOnly(DateTime.now());
    for (var offset = 0; offset < _scheduleDays; offset++) {
      await repo.ensureDosesFor(today.add(Duration(days: offset)), notify: false);
    }
    final doses = await repo.upcomingDoses(within: const Duration(days: _scheduleDays));
    if (doses.isEmpty) return;
    final meds = {for (final m in await repo.medicines()) m.id: m};
    final mode = await _mode();
    for (final dose in doses) {
      final medicine = meds[dose.medicineId];
      if (medicine == null) continue;
      await scheduleDose(
        DoseWithMedicine(dose, medicine),
        settings: settings,
        mode: mode,
      );
    }
  }

  /// Called once a dose stops being answerable — taken, skipped, snoozed to a new time, or its
  /// medicine removed. The reminder notification is posted `ongoing`, so nothing but this clears
  /// it: without it a dose confirmed from Home leaves an undismissable notification on the shade.
  static Future<void> clearForDose(int doseId) async {
    for (var slot = 0; slot < _slots; slot++) {
      try {
        await NirbhorNotifications.plugin.cancel(id: notificationId(doseId, slot));
      } catch (_) {
        // Cancelling an id that was never posted is a no-op on Android; swallow the rare failure.
      }
    }
  }

  static Future<void> clearForDoses(Iterable<int> doseIds) async {
    for (final id in doseIds) {
      await clearForDose(id);
    }
  }
}

/// The slice of [SettingsStore] the scheduler needs, resolved for the active locale.
class AppSettingsView {
  const AppSettingsView({
    required this.locale,
    required this.is24Hour,
    required this.fullScreenAlarm,
    required this.repeatEveryMinutes,
    required this.repeatMax,
  });

  final AppLocale locale;

  /// Bengali numerals and period words are the only Bangla-specific behaviour left down here.
  bool get isBangla => locale.isBangla;
  final bool is24Hour;
  final bool fullScreenAlarm;
  final int repeatEveryMinutes;
  final int repeatMax;

  factory AppSettingsView.from(SettingsStore store, String deviceLanguageCode) {
    final s = store.value;
    final locale = s.resolve(deviceLanguageCode);
    return AppSettingsView(
      locale: locale,
      is24Hour: s.is24Hour(locale.isBangla),
      fullScreenAlarm: s.fullScreenAlarm,
      repeatEveryMinutes: s.repeatEveryMinutes,
      repeatMax: s.repeatMax,
    );
  }
}
