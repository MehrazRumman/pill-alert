package com.nirbhor.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp

/**
 * Spacing, radius, elevation and touch-target tokens from README > Design Tokens.
 * These are px in the design; on Android we treat them as dp (the design was authored at the
 * 412×892 logical viewport, so px ≈ dp).
 */
object Dimens {
    // Screen padding
    val screenPadding = 20.dp
    val denseHeaderPadding = 18.dp

    // Gaps
    val cardGap = 8.dp          // 7–9px between cards in a list
    val cardGapTight = 7.dp
    val groupGap = 20.dp        // 18–22px between logical groups

    // Card / sheet padding
    val cardPadding = 16.dp     // 14–18px
    val cardPaddingTight = 14.dp
    val sheetPadding = 20.dp

    // Radius
    val radiusCard = 14.dp
    val radiusLargeCard = 18.dp // 16–20px
    val radiusSheetTop = 24.dp
    val radiusButton = 14.dp    // 12–16px
    val radiusChip = 10.dp      // 7–12px
    val radiusChipSmall = 8.dp
    val radiusIconTile = 14.dp  // 10–20px
    val radiusPhoneFrame = 26.dp

    // Touch targets (non-negotiable minimums)
    val tapMin = 48.dp
    val doseConfirm = 56.dp     // primary dose-confirm on home
    val flowButton = 64.dp      // 60–68px add-medicine / alarm buttons
    val stepper = 72.dp         // quantity steppers
    val alarmConfirm = 80.dp    // alarm "I took it"

    // Nav
    val bottomNavItem = 60.dp
    val navIcon = 21.dp
}

/** Corner shapes reused across the app. */
object NirbhorShapes {
    val card = RoundedCornerShape(Dimens.radiusCard)
    val largeCard = RoundedCornerShape(Dimens.radiusLargeCard)
    val button = RoundedCornerShape(Dimens.radiusButton)
    val chip = RoundedCornerShape(Dimens.radiusChip)
    val chipSmall = RoundedCornerShape(Dimens.radiusChipSmall)
    val iconTile = RoundedCornerShape(Dimens.radiusIconTile)
    val sheetTop = RoundedCornerShape(
        topStart = Dimens.radiusSheetTop, topEnd = Dimens.radiusSheetTop,
        bottomStart = 0.dp, bottomEnd = 0.dp,
    )
}
