import 'package:flutter/material.dart';

import '../i18n/numerals.dart';
import '../i18n/app_locale.dart';
import '../i18n/translations.dart';
import 'colors.dart';
import 'typography.dart';

export 'colors.dart';
export 'dimens.dart';
export 'typography.dart';

/// Reads the Nirbhor design tokens and locale primitives. Compose held these in composition-locals;
/// here one [InheritedWidget] carries the same four values down the tree.
///
/// Bangla is primary. Rather than a central strings file (a merge bottleneck when many screens are
/// built at once), screens pair the two languages at the call site with [NbContext.tr] — which
/// mirrors how the design pairs bn/en copy. Numerals/time formatting read the same values.
class NirbhorTheme extends InheritedWidget {
  const NirbhorTheme({
    super.key,
    required this.type,
    required this.locale,
    required this.is24Hour,
    required super.child,
  });

  final NirbhorType type;

  /// The language the app is actually being read in, already resolved from the patient's
  /// preference and the device.
  final AppLocale locale;
  final bool is24Hour;

  static NirbhorTheme of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<NirbhorTheme>();
    assert(t != null, 'NirbhorTheme is missing above this widget');
    return t!;
  }

  @override
  bool updateShouldNotify(NirbhorTheme old) =>
      type != old.type || locale != old.locale || is24Hour != old.is24Hour;
}

/// The token accessors every widget uses in place of raw hexes and sizes.
extension NbContext on BuildContext {
  NirbhorColors get colors => nbColors;
  NirbhorType get type => NirbhorTheme.of(this).type;
  AppLocale get locale => NirbhorTheme.of(this).locale;

  /// Kept because numerals, date words and time-of-day periods are Bangla-specific, not merely
  /// non-Latin — Hindi uses Western digits and its own month names.
  bool get isBangla => locale.isBangla;
  bool get is24Hour => NirbhorTheme.of(this).is24Hour;

  /// Picks copy for the active locale.
  ///
  /// Bangla and English are passed at the call site, as they always were — that pairing mirrors how
  /// the design is written and there are 440 of them. Hindi and Spanish are looked up by the
  /// English string, which acts as the message key, so adding a language touches no call site. Only
  /// the handful that interpolate a value have to pass [hi] and [es] explicitly, because their
  /// English text is built at runtime and cannot be a key.
  ///
  /// An untranslated string falls back to English rather than showing a key or an empty box.
  String tr(String bn, String en, {String? hi, String? es}) =>
      trIn(locale, bn, en, hi: hi, es: es);

  /// Localised integer (Bengali numerals in the Bangla locale).
  String num(int value) => Numerals.number(value, isBangla);

  /// Localises the digits in an already-formatted string (e.g. "৫৪টি").
  String numStr(String text) => Numerals.digits(text, isBangla);

  String percent(int value) => Numerals.percent(value, isBangla);

  String qty(double value) => Numerals.quantity(value, isBangla);

  /// Localised clock time for the active locale + time-format.
  String clock(int hour, int minute) => Numerals.time(hour, minute, isBangla, is24Hour);
}

/// Material theme mapped from our tokens so stock Material components stay on-palette.
/// `error` maps to warm (never red).
///
/// The palette is a single warm-light scheme; the design does not define a dark variant, so we keep
/// the calm health palette in both system themes rather than inverting it.
ThemeData buildMaterialTheme(NirbhorType type, bool isBangla) {
  const c = nbColors;
  final family = isBangla ? kAnekBangla : kArchivo;
  return ThemeData(
    useMaterial3: true,
    fontFamily: family,
    scaffoldBackgroundColor: c.paper,
    splashFactory: InkRipple.splashFactory,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: c.calm,
      onPrimary: c.paper,
      primaryContainer: c.calmSoft,
      onPrimaryContainer: c.calmD,
      secondary: c.calm,
      onSecondary: c.paper,
      secondaryContainer: c.sage,
      onSecondaryContainer: c.ink,
      surface: c.card,
      onSurface: c.ink,
      surfaceContainerHighest: c.sage,
      onSurfaceVariant: c.ink2,
      outline: c.line,
      outlineVariant: c.line,
      error: c.warm,
      onError: c.paper,
      errorContainer: c.warmSoft,
      onErrorContainer: c.warmD,
    ),
    textTheme: TextTheme(
      bodyLarge: type.body,
      bodyMedium: type.body,
      bodySmall: type.meta,
      titleLarge: type.header,
      labelLarge: type.buttonLabel,
    ),
  );
}
