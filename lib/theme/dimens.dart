import 'package:flutter/material.dart';

/// Spacing, radius, elevation and touch-target tokens from README > Design Tokens.
/// These are px in the design; the design was authored at the 412×892 logical viewport, so
/// px ≈ logical pixels.
class Dimens {
  Dimens._();

  // Screen padding
  static const double screenPadding = 24;
  static const double denseHeaderPadding = 18;

  // Gaps
  static const double cardGap = 8; // 7–9px between cards in a list
  static const double cardGapTight = 7;
  static const double groupGap = 28; // Widened from the design's 20: grouped lists carry the
  // separation that per-card gaps used to, so the space between groups has to do more work.

  // Card / sheet padding
  static const double cardPadding = 18; // 14–18px
  static const double cardPaddingTight = 14;
  static const double sheetPadding = 20;

  // Radius
  static const double radiusCard = 18;
  static const double radiusLargeCard = 22; // 16–20px
  static const double radiusSheetTop = 24;
  static const double radiusButton = 16; // 12–16px
  static const double radiusChip = 10; // 7–12px
  static const double radiusChipSmall = 8;
  static const double radiusIconTile = 14; // 10–20px
  static const double radiusPhoneFrame = 26;
  static const double radiusNavBar = 26; // floating nav bar shell
  static const double radiusNavPill = 20; // sliding active indicator inside it

  // Touch targets (non-negotiable minimums)
  static const double tapMin = 48;
  static const double doseConfirm = 56; // primary dose-confirm on home
  static const double flowButton = 64; // 60–68px add-medicine / alarm buttons
  static const double stepper = 72; // quantity steppers
  static const double alarmConfirm = 80; // alarm "I took it"

  // Nav
  static const double bottomNavItem = 66; // raised with the label size
  static const double navIcon = 24;
}

/// Corner shapes reused across the app.
class NbShapes {
  NbShapes._();

  static final BorderRadius card = BorderRadius.circular(Dimens.radiusCard);
  static final BorderRadius largeCard = BorderRadius.circular(Dimens.radiusLargeCard);
  static final BorderRadius button = BorderRadius.circular(Dimens.radiusButton);
  static final BorderRadius chip = BorderRadius.circular(Dimens.radiusChip);
  static final BorderRadius chipSmall = BorderRadius.circular(Dimens.radiusChipSmall);
  static final BorderRadius iconTile = BorderRadius.circular(Dimens.radiusIconTile);
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(Dimens.radiusSheetTop),
    topRight: Radius.circular(Dimens.radiusSheetTop),
  );
}
