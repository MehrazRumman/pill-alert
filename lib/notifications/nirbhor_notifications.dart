import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Small-icon resource name, as the plugin wants it: a bare name it can hand to
/// `getIdentifier(name, "drawable", package)`. Anything with an `@drawable/` or `@mipmap/` prefix
/// resolves to 0, and a notification with a 0 small icon is dropped without a word.
const String kNotificationIcon = 'ic_stat_nirbhor';

/// Notification channels. Reminders is high-importance (full-screen intent over the lock screen).
class NirbhorNotifications {
  NirbhorNotifications._();

  /// A channel's sound, importance and vibration are frozen the moment it is created —
  /// creating a channel on an existing id only refreshes its name and description. So a channel
  /// that was once created with a null sound (which is what the platform hands back when the
  /// user's alarm sound is "None") stays silent forever, no matter what this code asks for. The
  /// only way out is a new id: bump [_channelVersion] whenever the audio config below changes, and
  /// the superseded channels are deleted on next launch.
  static const int _channelVersion = 3;

  static const String channelReminders = 'reminders_audible_v$_channelVersion';
  static const String channelStock = 'low_stock';
  static const String channelCaregiver = 'caregiver';
  static const String channelMissed = 'missed_doses';

  /// Reminder-channel ids this build has outgrown.
  static const List<String> _supersededReminderChannels = [
    'reminders',
    'reminders_audible',
    'reminders_audible_v2',
  ];

  /// The reminder tone is a raw resource bundled in the APK rather than a system ringtone URI.
  /// The platform's default-alarm lookup returns nothing when the user's alarm sound is "None",
  /// and can name a ringtone this app cannot open (one on a removed card, or another profile's) —
  /// either of which freezes a silent channel. A bundled tone can never resolve to silence.
  static const AndroidNotificationSound alarmSound =
      RawResourceAndroidNotificationSound('alarm_tone');

  static final Int64List vibrationPattern =
      Int64List.fromList(const [0, 500, 350, 500, 350, 700]);

  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static bool _ready = false;

  /// Initialises the plugin, the timezone database (scheduling is zoned) and the channels.
  static Future<void> init({
    void Function(NotificationResponse response)? onTap,
    void Function(NotificationResponse response)? onBackgroundTap,
  }) async {
    if (_ready) return;
    _ready = true;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      // An unknown zone name must not stop reminders from being scheduled at all.
    }

    await plugin.initialize(
      settings: const InitializationSettings(
        // A notification's small icon is reduced to its alpha channel and painted white, so a
        // full-colour launcher icon renders as a featureless blob. This is a purpose-drawn
        // silhouette of the same mark.
        //
        // The name is bare, with no '@drawable/' prefix: the plugin resolves it with
        // getIdentifier(name, "drawable", package), which returns 0 for a prefixed name — and a
        // small icon of 0 means the notification is never posted at all. The commonly-copied
        // '@mipmap/ic_launcher' fails the same way, silently.
        android: AndroidInitializationSettings(kNotificationIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    await createChannels();
  }

  static Future<void> createChannels() async {
    final android = _android;
    if (android == null) return;

    for (final old in _supersededReminderChannels) {
      try {
        await android.deleteNotificationChannel(channelId: old);
      } catch (_) {
        // Deleting a channel that was never created is not an error worth surfacing.
      }
    }

    await android.createNotificationChannel(AndroidNotificationChannel(
      channelReminders,
      'মনে করিয়ে দেওয়া',
      description: 'ওষুধ খাওয়ার সময় হলে জানানো হয়',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      sound: alarmSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelStock,
      'ওষুধ ফুরিয়ে আসা',
      description: 'ওষুধ কমে গেলে জানানো হয়',
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelCaregiver,
      'পরিবারকে জানানো',
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelMissed,
      'বাদ পড়া ডোজ',
      description: 'নির্ধারিত ওষুধের ডোজ খাওয়া না হলে জানানো হয়',
    ));
  }

  /// POST_NOTIFICATIONS (Android 13+). Returns false when the patient declines.
  static Future<bool> requestPermission() async {
    final granted = await _android?.requestNotificationsPermission();
    return granted ?? true;
  }

  static Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  /// Opens the system screen where the patient grants exact-alarm access.
  static Future<void> requestExactAlarmPermission() async {
    await _android?.requestExactAlarmsPermission();
  }

  static Future<void> cancel(int id) => plugin.cancel(id: id);
}
