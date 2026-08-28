import 'package:flutter/material.dart';

/// The two bundled families. Both ship as variable TTFs, so every weight is instantiated from the
/// single file's `wght` axis via [FontVariation] rather than from separate static files.
const String kAnekBangla = 'AnekBangla';
const String kArchivo = 'Archivo';

/// Smallest line height, as a multiple of font size, that a family can be given before the layout
/// starts cutting its glyphs off. Measured from the shipped fonts' own glyph bounding boxes:
///
///  - Anek Bangla, Bengali block: ink runs +0.939em (chandrabindu) to −0.550em (vocalic vowel signs)
///    = **1.490em**. Bengali stacks a matra and vowel signs above the headline and hangs conjuncts
///    below the baseline, so it needs far more room than Latin.
///  - Archivo, Latin: ink runs +0.736em to −0.192em = **0.928em**.
///
/// The design's px line-heights were authored against a Latin face, so most roles sat well under the
/// Bangla figure — button labels (1.1×), status pills (1.0×) and the alarm clock (0.90×) were having
/// their matras and descenders sliced off in the app's *primary* locale. Roles that already ask for
/// more than the floor keep their designed value; only the too-tight ones are lifted.
const double kBanglaMinLine = 1.52;
const double kLatinMinLine = 1.0;

/// The type scale from README > Design Tokens > Typography. Bangla (Anek Bangla) renders visibly
/// taller than English (Archivo) at the same px, so most Bangla roles are 1–2px smaller and get a
/// touch more line-height. Letter-spacing and uppercase are NEVER applied to Bangla — splitting a
/// conjunct reorders vowel signs.
@immutable
class NirbhorType {
  const NirbhorType({
    required this.titleHero,
    required this.header,
    required this.alarmTime,
    required this.alarmName,
    required this.bigStat,
    required this.cardTitlePrimary,
    required this.cardTitleSecondary,
    required this.body,
    required this.meta,
    required this.sectionLabel,
    required this.buttonLabel,
    required this.statusPill,
    required this.isBangla,
  });

  final TextStyle titleHero;
  final TextStyle header;
  final TextStyle alarmTime;
  final TextStyle alarmName;
  final TextStyle bigStat;
  final TextStyle cardTitlePrimary;
  final TextStyle cardTitleSecondary;
  final TextStyle body;
  final TextStyle meta;
  final TextStyle sectionLabel;
  final TextStyle buttonLabel;
  final TextStyle statusPill;

  /// true when the active locale is Bangla — components use this to skip uppercase / spacing.
  final bool isBangla;

  /// Archivo is always used for Latin runs (codes, emails, pack names) even in Bangla.
  String get latin => kArchivo;

  /// Anek Bangla, whatever the active locale. Archivo has **no Bengali glyphs at all**, so any
  /// Bangla literal that shows in the English locale (the brand name, the "বাংলা" language option)
  /// must use this or it falls through to a system font — or to tofu on a device without one.
  String get bangla => kAnekBangla;

  /// Restyles [style] onto the Latin family, keeping its size/weight. Use for codes, emails and
  /// pack names, which stay Latin in both locales.
  TextStyle asLatin(TextStyle style) => style.copyWith(fontFamily: kArchivo);

  /// Restyles [style] onto Anek Bangla — required for any Bangla literal shown in English.
  TextStyle asBangla(TextStyle style) => style.copyWith(fontFamily: kAnekBangla);
}

TextStyle _style({
  required String family,
  required double px,
  required int weight,
  required double lineMult,
  required double scale,
  double letterEm = 0,
}) {
  final size = px * scale;
  final floor = family == kAnekBangla ? kBanglaMinLine : kLatinMinLine;
  return TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    // The bundled files are variable; without an explicit wght variation every weight would render
    // at the axis default (400) no matter what fontWeight says.
    fontVariations: [FontVariation('wght', weight.toDouble())],
    fontSize: size,
    height: lineMult < floor ? floor : lineMult,
    letterSpacing: letterEm == 0 ? null : letterEm * size,
    // Predictable metrics: line height comes from the numbers above, not from the font's own
    // (very generous) padding, which differs between the two families.
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// Builds the scale for the active locale. [scale] applies the OS / in-app "bigger text" setting.
NirbhorType buildNirbhorType({required bool isBangla, double scale = 1}) {
  final family = isBangla ? kAnekBangla : kArchivo;
  // Letter spacing / uppercase only exist in the English locale.
  double ls(double em) => isBangla ? 0 : em;

  TextStyle s(double px, int weight, double lineMult, {double letterEm = 0, String? fam}) => _style(
        family: fam ?? family,
        px: px,
        weight: weight,
        lineMult: lineMult,
        scale: scale,
        letterEm: letterEm,
      );

  return NirbhorType(
    titleHero: s(isBangla ? 28 : 27, 700, 1.28),
    header: s(isBangla ? 23 : 22, 700, 1.2),
    // The Bangla clock carries a period word ("সকাল ৮:০০"), so it is far wider than "08:00" and has
    // to be set smaller to stay on one line — and, like every Bangla role, it is floored to
    // kBanglaMinLine, which is why the designed 0.90x was slicing the tops off its glyphs.
    alarmTime: s(isBangla ? 58 : 84, 700, 0.90, letterEm: ls(-0.045)),
    alarmName: s(isBangla ? 23 : 22, 700, 1.1),
    bigStat: s(46, 700, 1.0, letterEm: ls(-0.03)),
    cardTitlePrimary: s(isBangla ? 19 : 18, 700, 1.3),
    cardTitleSecondary: s(isBangla ? 17 : 16, 600, 1.35),
    body: s(isBangla ? 17 : 16, 400, isBangla ? 1.55 : 1.5),
    meta: s(isBangla ? 14 : 13.5, 400, 1.45),
    // Section label: English uses uppercase + spacing; Bangla remains sentence case.
    sectionLabel: isBangla ? s(14, 600, 1.25) : s(12, 600, 1.2, letterEm: 0.1),
    buttonLabel: s(isBangla ? 18 : 17, 700, 1.1),
    statusPill: s(isBangla ? 12 : 11, 600, 1.0),
    isBangla: isBangla,
  );
}
