import 'package:flutter/material.dart';

/// Nirbhor design tokens. Defined once, used everywhere (README > Design Tokens > Colour).
///
/// The palette is a calm health palette: primary is a healing green ([calm]); urgency is a muted
/// amber ([warm]) — never red. Accent colours ([markSlate], [markOchre], [markMauve]) are used ONLY
/// as medicine marks, never as UI chrome.
@immutable
class NirbhorColors {
  const NirbhorColors();

  final Color ink = const Color(0xFF1B2A26); // Primary text; deep green-black
  final Color ink2 = const Color(0xFF4A5C56); // Secondary text, body copy on cards
  // Tertiary text, labels, placeholder. Darkened from the design's #8B9A94, which measured
  // 2.62:1 on paper and 2.94:1 on card — well under the 4.5:1 WCAG AA floor for body text, and
  // this is the colour carrying every dose subtitle, meta line and section label in an app whose
  // users are elderly. #566964 keeps the same desaturated green-grey and reads at 5.21:1 on
  // paper, 5.83:1 on card, 4.76:1 on sage.
  final Color ink3 = const Color(0xFF566964);
  final Color paper = const Color(0xFFF4F2EC); // App background (warm off-white)
  final Color card = const Color(0xFFFFFFFF); // Card / sheet / nav-bar surface
  final Color sage = const Color(0xFFE3EAE4); // Neutral tinted fill (secondary chips, empty track)
  final Color line = const Color(0xFFDCD8CE); // Hairline border, 1px dividers
  final Color calm = const Color(0xFF2F6B5B); // PRIMARY. Buttons, selected, "taken", progress
  final Color calmD = const Color(0xFF1F4F42); // Primary dark — alarm background, text on calm-soft
  final Color calmSoft = const Color(0xFFDCEAE4); // Primary tinted fill (info panels, selected chips)
  final Color warm = const Color(0xFFC07138); // URGENCY. Due now, missed, low stock
  final Color warmSoft = const Color(0xFFF6E7D8); // Urgency tinted fill
  final Color warmD = const Color(0xFF8A4A1C); // Text and solid buttons on warm-soft

  // Accent colours — medicine marks ONLY, never UI chrome.
  final Color markSlate = const Color(0xFF7D94A8);
  final Color markOchre = const Color(0xFFB9975B);
  final Color markMauve = const Color(0xFFA8788F);

  // On the dark alarm background, marks lighten to these.
  final Color markCalmOnDark = const Color(0xFF7FC0AC);
  final Color markSlateOnDark = const Color(0xFF9FB6C8);

  // Alarm surface text.
  final Color alarmText = const Color(0xFFEEF3F0);
}

const nbColors = NirbhorColors();
