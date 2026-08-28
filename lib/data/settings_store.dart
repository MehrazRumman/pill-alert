import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Persists [AppSettings] in SharedPreferences (the DataStore equivalent). Holds the current value
/// in memory and notifies on every write, so the app root can rebuild the theme and locale
/// synchronously — a locale switch must not flash the previous language.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs, this._value);

  final SharedPreferences _prefs;
  AppSettings _value;

  AppSettings get value => _value;

  static const _kLocale = 'locale_pref';
  static const _kTimeFormat = 'time_format';
  static const _kBiggerText = 'bigger_text';
  static const _kReadAloud = 'read_aloud';
  static const _kFullScreenAlarm = 'full_screen_alarm';
  static const _kAlarmSound = 'alarm_sound';
  static const _kRepeatEvery = 'repeat_every';
  static const _kRepeatMax = 'repeat_max';
  static const _kOnboarding = 'onboarding_complete';
  static const _kPriming = 'priming_shown';
  static const _kInboxReadSignature = 'inbox_read_signature';

  static Future<SettingsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStore._(prefs, _read(prefs));
  }

  static AppSettings _read(SharedPreferences p) => AppSettings(
        localePref: LocalePref.fromStored(p.getString(_kLocale)),
        timeFormat: TimeFormat.fromStored(p.getString(_kTimeFormat)),
        biggerText: p.getBool(_kBiggerText) ?? false,
        readAloud: p.getBool(_kReadAloud) ?? true,
        fullScreenAlarm: p.getBool(_kFullScreenAlarm) ?? true,
        alarmSound: p.getString(_kAlarmSound) ?? 'default',
        repeatEveryMinutes: (p.getInt(_kRepeatEvery) ?? 10).clamp(1, 60),
        repeatMax: (p.getInt(_kRepeatMax) ?? 3).clamp(0, 10),
        onboardingComplete: p.getBool(_kOnboarding) ?? false,
        notificationPrimingShown: p.getBool(_kPriming) ?? false,
        inboxReadSignature: p.getString(_kInboxReadSignature) ?? '',
      );

  Future<void> _commit(Future<void> Function() write) async {
    await write();
    _value = _read(_prefs);
    notifyListeners();
  }

  Future<void> setLocale(LocalePref pref) =>
      _commit(() => _prefs.setString(_kLocale, pref.stored));

  Future<void> setTimeFormat(TimeFormat? fmt) => _commit(() async {
        if (fmt == null) {
          await _prefs.remove(_kTimeFormat);
        } else {
          await _prefs.setString(_kTimeFormat, fmt.stored);
        }
      });

  Future<void> setBiggerText(bool v) => _commit(() => _prefs.setBool(_kBiggerText, v));
  Future<void> setReadAloud(bool v) => _commit(() => _prefs.setBool(_kReadAloud, v));
  Future<void> setFullScreenAlarm(bool v) => _commit(() => _prefs.setBool(_kFullScreenAlarm, v));
  Future<void> setAlarmSound(String v) => _commit(() => _prefs.setString(_kAlarmSound, v));

  Future<void> setRepeat({required int everyMinutes, required int maxRepeats}) =>
      _commit(() async {
        await _prefs.setInt(_kRepeatEvery, everyMinutes.clamp(1, 60));
        await _prefs.setInt(_kRepeatMax, maxRepeats.clamp(0, 10));
      });

  Future<void> setOnboardingComplete(bool v) => _commit(() => _prefs.setBool(_kOnboarding, v));
  Future<void> setPrimingShown(bool v) => _commit(() => _prefs.setBool(_kPriming, v));
  Future<void> setInboxReadSignature(String v) =>
      _commit(() => _prefs.setString(_kInboxReadSignature, v));
}
