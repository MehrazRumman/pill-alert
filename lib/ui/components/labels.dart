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
