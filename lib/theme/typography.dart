import 'package:flutter/material.dart';

import '../i18n/app_locale.dart';

/// The two bundled families. Both ship as variable TTFs, so every weight is instantiated from the
/// single file's `wght` axis via [FontVariation] rather than from separate static files.
const String kAnekBangla = 'AnekBangla';
const String kAnekDevanagari = 'AnekDevanagari';
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

/// Devanagari, measured the same way from Anek Devanagari's own glyph boxes: ink runs +0.972em
/// (U+0951 udatta) to −0.474em (U+0963 vocalic vowel sign) = **1.446em**. Like Bengali it stacks
/// marks above the headline and hangs below the baseline, so it needs a floor of its own — smaller
/// than Bangla's because its descending signs do not reach as far.
const double kDevanagariMinLine = 1.48;
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
    required this.script,
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

  /// The script the scale was built for. Components read [isBangla] / [isIndic] off this to skip
  /// uppercase and letter-spacing, neither of which may be applied to a script that forms
  /// conjuncts — splitting one reorders its vowel signs.
  final NbScript script;

  bool get isBangla => script == NbScript.bengali;
  bool get isIndic => script != NbScript.latin;

  /// Archivo is always used for Latin runs (codes, emails, pack names) even in Bangla.
  String get latin => kArchivo;

  /// Anek Bangla, whatever the active locale. Archivo has **no Bengali glyphs at all**, so any
  /// Bangla literal that shows in another locale (the brand name, the "বাংলা" language option)
  /// must use this or it falls through to a system font — or to tofu on a device without one.
  String get bangla => kAnekBangla;

  /// Anek Devanagari, whatever the active locale — same reasoning as [bangla]. The "हिन्दी"
  /// option in the language list is rendered with this even when the app is in Spanish.
  String get devanagari => kAnekDevanagari;

  /// Restyles [style] onto the Latin family, keeping its size/weight. Use for codes, emails and
  /// pack names, which stay Latin in both locales.
  TextStyle asLatin(TextStyle style) => style.copyWith(fontFamily: kArchivo);

  /// Restyles [style] onto Anek Bangla — required for any Bangla literal shown in another locale.
  TextStyle asBangla(TextStyle style) => style.copyWith(
        fontFamily: kAnekBangla,
        // The floor travels with the face: a Latin-authored 1.2 header re-set in Anek Bangla would
        // otherwise slice its matras off, which is the exact failure the floor was measured from.
        height: _floored(style.height, kBanglaMinLine),
      );

  /// Restyles [style] onto Anek Devanagari — required for any Hindi literal shown elsewhere.
  TextStyle asDevanagari(TextStyle style) => style.copyWith(
        fontFamily: kAnekDevanagari,
        height: _floored(style.height, kDevanagariMinLine),
      );

  static double _floored(double? height, double floor) =>
      height == null || height < floor ? floor : height;

  /// The face a language's own name must be set in, for a list that names each option in itself.
  TextStyle asScriptOf(AppLocale locale, TextStyle style) => switch (locale.script) {
        NbScript.bengali => asBangla(style),
        NbScript.devanagari => asDevanagari(style),
        NbScript.latin => asLatin(style),
      };
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
  final floor = switch (family) {
    kAnekBangla => kBanglaMinLine,
    kAnekDevanagari => kDevanagariMinLine,
    _ => kLatinMinLine,
  };
  return TextStyle(
    fontFamily: family,
    // None of the three faces covers another script, and patient-typed text (a medicine form, a
    // caregiver's name) is stored in whatever locale it was typed in and shown in every other. A
    // per-glyph fallback to the other two faces is what keeps that from rendering as tofu.
    fontFamilyFallback: [
      for (final f in const [kAnekBangla, kAnekDevanagari, kArchivo])
        if (f != family) f,
    ],
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
NirbhorType buildNirbhorType({required NbScript script, double scale = 1}) {
  final family = switch (script) {
    NbScript.bengali => kAnekBangla,
    NbScript.devanagari => kAnekDevanagari,
    NbScript.latin => kArchivo,
  };
  // Sizing follows the script, not the language: Devanagari renders as tall as Bengali at the same
  // px and needs the same one-to-two-point reduction, while Spanish is metrically English.
  final indic = script != NbScript.latin;
  // Letter spacing / uppercase only exist in the Latin locales.
  double ls(double em) => indic ? 0 : em;

  TextStyle s(double px, int weight, double lineMult, {double letterEm = 0, String? fam}) => _style(
        family: fam ?? family,
        px: px,
        weight: weight,
        lineMult: lineMult,
        scale: scale,
        letterEm: letterEm,
      );

  return NirbhorType(
    titleHero: s(indic ? 28 : 27, 700, 1.28),
    header: s(indic ? 23 : 22, 700, 1.2),
    // The Bangla clock carries a period word ("সকাল ৮:০০"), so it is far wider than "08:00" and has
    // to be set smaller to stay on one line — and, like every Bangla role, it is floored to
    // kBanglaMinLine, which is why the designed 0.90x was slicing the tops off its glyphs.
    alarmTime: s(indic ? 58 : 84, 700, 0.90, letterEm: ls(-0.045)),
    alarmName: s(indic ? 23 : 22, 700, 1.1),
    bigStat: s(46, 700, 1.0, letterEm: ls(-0.03)),
    cardTitlePrimary: s(indic ? 19 : 18, 700, 1.3),
    cardTitleSecondary: s(indic ? 17 : 16, 600, 1.35),
    body: s(indic ? 17 : 16, 400, indic ? 1.55 : 1.5),
    meta: s(indic ? 14 : 13.5, 400, 1.45),
    // Section label: English uses uppercase + spacing; Bangla remains sentence case.
    sectionLabel: indic ? s(14, 600, 1.25) : s(12, 600, 1.2, letterEm: 0.1),
    buttonLabel: s(indic ? 18 : 17, 700, 1.1),
    statusPill: s(indic ? 12 : 11, 600, 1.0),
    script: script,
  );
}
