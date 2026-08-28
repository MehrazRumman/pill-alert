import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Section label. English is UPPERCASE with letter-spacing; Bangla is sentence-case, NO uppercase
/// and NO letter-spacing (Bengali script has no case, and spacing breaks conjuncts).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        context.isBangla ? text : text.toUpperCase(),
        style: context.type.sectionLabel.copyWith(color: color ?? context.colors.ink3),
      );
}

/// Status pill — the coloured capsule that carries a dose-state word (এখন সময় / নেওয়া হয়েছে /
/// ৪টি বাকি). Three redundant signals per state are the caller's job (shape + fill + word); this
/// renders fill + word.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.background,
    required this.contentColor,
  });

  final String text;
  final Color background;
  final Color contentColor;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: context.type.statusPill.copyWith(color: contentColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

/// Consecutive fully-taken days. Deliberately quiet: adherence is not a game, and a patient who
/// breaks a long run because they were ill should not be made to feel they lost something. The
/// number is stated, not celebrated, and it simply disappears below two days.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.onDark = false});

  final int days;

  /// True on the calm-filled day-complete card, where the chip inverts.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = onDark ? colors.paper.withValues(alpha: 0.16) : colors.calmSoft;
    final fg = onDark ? colors.paper : colors.calmD;
    return Semantics(
      label: context.tr('টানা $days দিন', '$days day streak', hi: 'लगातार $days दिन', es: 'racha de $days días'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: NbShapes.chip),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              context.tr('${context.num(days)} দিন টানা', '$days days in a row', hi: '$days दिन लगातार', es: '$days días seguidos'),
              style: context.type.meta.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
