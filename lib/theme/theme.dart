import 'package:flutter/material.dart';

import '../i18n/numerals.dart';
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
    required this.isBangla,
    required this.is24Hour,
    required super.child,
  });

  final NirbhorType type;
  final bool isBangla;
  final bool is24Hour;

  static NirbhorTheme of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<NirbhorTheme>();
    assert(t != null, 'NirbhorTheme is missing above this widget');
    return t!;
  }

  @override
  bool updateShouldNotify(NirbhorTheme old) =>
      type != old.type || isBangla != old.isBangla || is24Hour != old.is24Hour;
}

/// The token accessors every widget uses in place of raw hexes and sizes.
extension NbContext on BuildContext {
  NirbhorColors get colors => nbColors;
  NirbhorType get type => NirbhorTheme.of(this).type;
  bool get isBangla => NirbhorTheme.of(this).isBangla;
  bool get is24Hour => NirbhorTheme.of(this).is24Hour;

  /// Picks Bangla or English copy for the active locale.
  String tr(String bn, String en) => isBangla ? bn : en;

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
