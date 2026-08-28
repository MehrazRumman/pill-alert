/// ভাষা — locale preference. `system` follows the device locale (the default).
enum LocalePref {
  system('SYSTEM'),
  bn('BN'),
  en('EN');

  const LocalePref(this.stored);
  final String stored;

  static LocalePref fromStored(String? s) =>
      LocalePref.values.firstWhere((l) => l.stored == s, orElse: () => LocalePref.system);
}

enum TimeFormat {
  h12('H12'),
  h24('H24');

  const TimeFormat(this.stored);
  final String stored;

  static TimeFormat? fromStored(String? s) {
    if (s == null) return null;
    for (final v in TimeFormat.values) {
      if (v.stored == s) return v;
    }
    return null;
  }
}

/// App-level settings (README > State Management > App-level). Persisted in SharedPreferences.
class AppSettings {
  const AppSettings({
    this.localePref = LocalePref.system,
    this.timeFormat, // null → locale default (BN→12h, EN→24h)
    this.biggerText = false,
    this.readAloud = true, // ON in Bangla; TTS speaks the medicine name at alarm
    this.fullScreenAlarm = true,
    this.alarmSound = 'default',
    this.repeatEveryMinutes = 10,
    this.repeatMax = 3,
    this.onboardingComplete = false,
    this.notificationPrimingShown = false,
    this.inboxReadSignature = '',
  });

  final LocalePref localePref;
  final TimeFormat? timeFormat;
  final bool biggerText;
  final bool readAloud;
  final bool fullScreenAlarm;
  final String alarmSound;
  final int repeatEveryMinutes;
  final int repeatMax;
  final bool onboardingComplete;
  final bool notificationPrimingShown;
  final String inboxReadSignature;

  /// Resolves the effective Bangla flag given the device's Bangla state.
  bool isBangla(bool deviceIsBangla) => switch (localePref) {
        LocalePref.bn => true,
        LocalePref.en => false,
        LocalePref.system => deviceIsBangla,
      };

  /// Resolves the effective 24-hour flag. BN defaults to 12h, EN to 24h.
  bool is24Hour(bool bangla) => switch (timeFormat) {
        TimeFormat.h24 => true,
        TimeFormat.h12 => false,
        null => !bangla,
      };
}
