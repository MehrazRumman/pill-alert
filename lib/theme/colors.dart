import 'package:flutter/material.dart';

/// Nirbhor design tokens. Defined once, used everywhere (README > Design Tokens > Colour).
///
/// The palette is a calm health palette: primary is a healing teal-green ([calm]); urgency is a
/// muted amber ([warm]) — never red. Accent colours ([markSlate], [markOchre], [markMauve]) are
/// used ONLY as medicine marks, never as UI chrome.
///
/// Every value below is held above its WCAG floor on each surface it actually lands on. Text
/// pairs clear 4.5:1; purely graphical marks clear the 3:1 of WCAG 1.4.11. Changing one token
/// means re-checking the pairs noted alongside it.
@immutable
class NirbhorColors {
  const NirbhorColors();

  final Color ink = const Color(0xFF14262A); // Primary text; deep teal-black
  final Color ink2 = const Color(0xFF42585D); // Secondary text, body copy on cards
  // Tertiary text, labels, placeholder. This is the colour carrying every dose subtitle, meta
  // line and section label in an app whose users are elderly, so it is the tightest text token
  // in the palette: 5.49:1 on paper, 6.11:1 on card, 4.90:1 on sage — all above the 4.5:1 floor.
  final Color ink3 = const Color(0xFF4E666B);
  final Color paper = const Color(0xFFF1F3F3); // App background (cool off-white)
  final Color card = const Color(0xFFFFFFFF); // Card / sheet / nav-bar surface
  final Color sage = const Color(0xFFDFE8E9); // Neutral tinted fill (secondary chips, empty track)
  final Color line = const Color(0xFFD2DADA); // Hairline border, 1px dividers
  final Color calm = const Color(0xFF1F6B70); // PRIMARY. Buttons, selected, "taken", progress
  final Color calmD = const Color(0xFF12474B); // Primary dark — alarm background, text on calm-soft
  final Color calmSoft = const Color(0xFFD5E9EA); // Primary tinted fill (info panels, selected chips)
  // URGENCY. Due now, missed, low stock. Never sits behind text — it is dots, borders, bar fills
  // and legend swatches only, so the 3:1 of WCAG 1.4.11 applies rather than 4.5:1. This is the
  // weakest link in the palette and the one carrying the "something is wrong" signal, so it is
  // kept deliberately clear of the floor: 3.89:1 on paper, 4.34:1 on card.
  final Color warm = const Color(0xFFB4652F);
  final Color warmSoft = const Color(0xFFF5E4D6); // Urgency tinted fill
  final Color warmD = const Color(0xFF7C4218); // Text and solid buttons on warm-soft

  // Accent colours — medicine marks ONLY, never UI chrome. Each clears 3:1 on both paper and
  // card, and each is far enough from [calm] and [warm] to never be mistaken for state.
  final Color markSlate = const Color(0xFF7C86AD);
  final Color markOchre = const Color(0xFFA8873F);
  final Color markMauve = const Color(0xFF9A6A82);

  // On the dark alarm background, marks lighten to these.
  final Color markCalmOnDark = const Color(0xFF6FC2C6);
  final Color markSlateOnDark = const Color(0xFF9BA6CE);

  // Alarm surface text. Drawn as low as alpha 0.7 on [calmD], which still reads 5.40:1.
  final Color alarmText = const Color(0xFFEDF3F3);
}

const nbColors = NirbhorColors();
