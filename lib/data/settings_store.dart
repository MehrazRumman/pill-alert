import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/patient_profile.dart';

/// Persists [AppSettings] in SharedPreferences (the DataStore equivalent). Holds the current value
/// in memory and notifies on every write, so the app root can rebuild the theme and locale
/// synchronously — a locale switch must not flash the previous language.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs, this._value);

  final SharedPreferences _prefs;
  AppSettings _value;

  AppSettings get value => _value;

  /// Who the medicines belong to. Read on every rebuild of the More hub and the doctor report, so
  /// it is held in memory beside the settings rather than re-read from disk.
  PatientProfile get profile => _readProfile(_prefs);

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
  static const _kDeviceLanguage = 'device_language';

  // Patient profile.
  static const _kName = 'profile_name';
  static const _kBirthYear = 'profile_birth_year';
  static const _kBloodGroup = 'profile_blood_group';
  static const _kAllergies = 'profile_allergies';
  static const _kConditions = 'profile_conditions';
  static const _kEmergencyName = 'profile_emergency_name';
  static const _kEmergencyPhone = 'profile_emergency_phone';

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
        deviceLanguage: p.getString(_kDeviceLanguage) ?? '',
      );

  static PatientProfile _readProfile(SharedPreferences p) => PatientProfile(
        name: p.getString(_kName) ?? '',
        yearOfBirth: p.getInt(_kBirthYear),
        bloodGroup: p.getString(_kBloodGroup) ?? '',
        allergies: p.getString(_kAllergies) ?? '',
        conditions: p.getString(_kConditions) ?? '',
        emergencyName: p.getString(_kEmergencyName) ?? '',
        emergencyPhone: p.getString(_kEmergencyPhone) ?? '',
      );

  /// Writes the whole profile at once. Partial saves are deliberately not offered: the edit screen
  /// commits one complete object, so a half-written profile can never be persisted.
  Future<void> saveProfile(PatientProfile profile) => _commit(() async {
        await _prefs.setString(_kName, profile.name.trim());
        final year = profile.yearOfBirth;
        if (year == null) {
          await _prefs.remove(_kBirthYear);
        } else {
          await _prefs.setInt(_kBirthYear, year);
        }
        await _prefs.setString(_kBloodGroup, profile.bloodGroup);
        await _prefs.setString(_kAllergies, profile.allergies.trim());
        await _prefs.setString(_kConditions, profile.conditions.trim());
        await _prefs.setString(_kEmergencyName, profile.emergencyName.trim());
        await _prefs.setString(_kEmergencyPhone, profile.emergencyPhone.trim());
      });

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

  /// Records the device language the foreground app resolved against; see
  /// [AppSettings.deviceLanguage]. Silent when unchanged so it can be called on every launch.
  Future<void> rememberDeviceLanguage(String code) async {
    if (code.isEmpty || code == 'und' || code == _value.deviceLanguage) return;
    await _commit(() => _prefs.setString(_kDeviceLanguage, code));
  }
}
