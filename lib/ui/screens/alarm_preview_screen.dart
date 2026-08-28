import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import 'alarm_screen.dart';

/// In-app alarm preview, reached from Settings.
///
/// It must stay write-free: this is a rehearsal, not a confirmation. Every button simply returns to
/// Settings — nothing is marked taken, snoozed or skipped, and no alarm is cleared.
class AlarmPreviewScreen extends StatelessWidget {
  const AlarmPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepoBuilder<List<TimelineBlock>>(
      query: (repo) => repo.timelineFor(DateTime.now()),
      loading: ColoredBox(color: context.colors.calmD, child: const SizedBox.expand()),
      builder: (context, blocks) {
        TimelineBlock? block;
        for (final b in blocks) {
          if (b.doses.any((d) => d.dose.status == DoseStatus.upcoming)) {
            block = b;
            break;
          }
        }
        block ??= blocks.isEmpty ? null : blocks.first;

        var due = <DoseWithMedicine>[];
        if (block != null) {
          due = block.doses.where((d) => d.dose.status == DoseStatus.upcoming).toList();
          if (due.isEmpty) due = block.doses;
        }

        final back = context.nav.back;
        return AlarmSurface(
          hour: block?.hour ?? 8,
          minute: block?.minute ?? 0,
          doses: due,
          subtitle: context.tr('ওষুধ খাওয়ার সময় হয়েছে', "It's time for your medicine"),
          note: context.tr(
            'এটি শুধু দেখার জন্য — কিছুই রেকর্ড হবে না।',
            'This is a preview only — nothing is recorded.',
          ),
          emptyMessage: context.tr(
            'আজ আর কোনো ডোজ বাকি নেই — ওষুধ যোগ করলে এখানে দেখা যাবে।',
            'No doses left today — add a medicine and it will appear here.',
          ),
          onTaken: back,
          onSnooze: back,
          onSkip: back,
        );
      },
    );
  }
}
