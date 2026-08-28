import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/repository.dart';
import '../../domain/dose_scheduler.dart';
import '../../domain/models.dart';
import '../../i18n/dates.dart';
import '../../navigation/nav_actions.dart';
import '../../i18n/app_locale.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/overlays.dart';
import '../components/progress_ring.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';

/// Adherence record (2t/2f) — the donut summary, the day grid, and the per-medicine bars.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _weekly = true;

  int get _days => _weekly ? 7 : 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.paper,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('রেকর্ড', 'Record'),
                      style: context.type.titleHero.copyWith(color: colors.ink),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: SegmentedControl(
                      options: [
                        context.tr('সপ্তাহ', 'Week'),
                        context.tr('মাস', 'Month'),
                      ],
                      selectedIndex: _weekly ? 0 : 1,
                      onSelect: (i) => setState(() => _weekly = i == 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RepoBuilder<_RecordData>(
              key: ValueKey(_days),
              query: (repo) async => _RecordData(
                window: await repo.adherenceOver(_days),
                cells: await repo.dayCells(_days),
                perMed: await repo.perMedicineAdherence(_days),
                streak: await repo.currentStreak(),
                insight: await repo.weakestBlock(),
              ),
              builder: (context, data) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  0,
                  Dimens.screenPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(window: data.window),
                    if (data.streak >= 2) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StreakChip(days: data.streak),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _DayGrid(cells: data.cells),
                    const SizedBox(height: 18),
                    if (data.insight != null) ...[
                      _InsightCard(insight: data.insight!),
                      const SizedBox(height: 18),
                    ],
                    for (final m in data.perMed.where((m) => m.total > 0)) ...[
                      _MedBar(m: m),
                      const SizedBox(height: 18),
                    ],
                    SecondaryButton(
                      text: context.tr(
                        'ডাক্তারের জন্য পিডিএফ বানান',
                        'Make a PDF for the doctor',
                      ),
                      onPressed: context.nav.openDoctorReport,
                      height: 50,
                      enabled: data.window.total > 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordData {
  const _RecordData({
    required this.window,
    required this.cells,
    required this.perMed,
    required this.streak,
    required this.insight,
  });

  final AdherenceWindow window;
  final List<DayCell> cells;
  final List<MedAdherence> perMed;
  final int streak;

  /// Null unless the history genuinely supports a claim about one time of day.
  final BlockInsight? insight;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.window});

  final AdherenceWindow window;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // With nothing counted yet, a 0% ring reads as a failing grade rather than an empty record.
    if (window.total == 0) {
      return NbCard(
        padding: 13,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('এখনও কিছু হিসাব হয়নি', 'Nothing counted yet'),
              style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(
                'ওষুধ খাওয়া শুরু করলে এখানে হিসাব জমতে থাকবে।',
                'Your record builds up here once you start confirming doses.',
              ),
              style: context.type.body.copyWith(color: colors.ink2),
            ),
          ],
        ),
      );
    }

    final pct = window.percent;
    return NbCard(
      padding: 13,
      child: Row(
        children: [
          ProgressRing(
            fraction: pct / 100,
            diameter: 74,
            strokeWidth: 8,
            center: Text(
              context.percent(pct),
              style: context.type.cardTitlePrimary.copyWith(
                fontSize: 20,
                color: colors.calmD,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pct >= 90
                      ? context.tr('বেশ ভালো চলছে', 'Going well')
                      : pct >= 70
                          ? context.tr('মোটামুটি চলছে', 'Fairly steady')
                          : context.tr('আরও যত্ন দরকার', 'Needs more care'),
                  style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                ),
                Text(
                  window.missed == 0
                      ? context.tr(
                          'এই সময়ে কোনো ডোজ বাদ পড়েনি।',
                          'No doses were missed in this period.',
                        )
                      : context.tr(
                          'এই সময়ে ${context.num(window.missed)}টি ডোজ বাদ পড়েছে।',
                          '${window.missed} doses were missed in this period.', hi: 'इस अवधि में ${window.missed} खुराक छूटीं।', es: 'En este periodo se saltaron ${window.missed} dosis.',
                        ),
                  style: context.type.meta.copyWith(color: colors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _bnWeekHeaders = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];
const List<String> _enWeekHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _hiWeekHeaders = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
const List<String> _esWeekHeaders = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.cells});

  final List<DayCell> cells;

  /// Opens the day that was tapped. A missed day is only useful if it can be investigated and
  /// corrected, rather than merely noted.
  Future<void> _openDay(BuildContext context, DayCell cell) async {
    if (cell.state == DayState.future && cell.date.isAfter(dateOnly(DateTime.now()))) return;
    await showNbSheet(context, (context) => _DaySheet(date: cell.date));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final headers = switch (context.locale) {
      AppLocale.bn => _bnWeekHeaders,
      AppLocale.en => _enWeekHeaders,
      AppLocale.hi => _hiWeekHeaders,
      AppLocale.es => _esWeekHeaders,
    };
    final today = dateOnly(DateTime.now());

    // Chunk cells into weeks of 7. Pad the first week so weekday columns align (Mon = column 0).
    final firstDow = cells.isEmpty ? 0 : cells.first.date.weekday - 1;
    final padded = <DayCell?>[...List<DayCell?>.filled(firstDow, null), ...cells];
    final weeks = <List<DayCell?>>[];
    for (var i = 0; i < padded.length; i += 7) {
      weeks.add(padded.sublist(i, i + 7 > padded.length ? padded.length : i + 7));
    }

    final first = cells.isEmpty ? today : cells.first.date;
    final last = cells.isEmpty ? today : cells.last.date;

    return NbCard(
      padding: 13,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The window in words, so the range is never left to be inferred from the columns.
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${shortDateFor(first, context.locale)} – ${shortDateFor(last, context.locale)}',
              style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
            ),
          ),
          Row(
            children: [
              for (final h in headers)
                Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: context.type.meta.copyWith(fontSize: 12, color: colors.ink3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final week in weeks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: i < week.length && week[i] != null
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _openDay(context, week[i]!),
                                child: _DayCellView(
                                  cell: week[i]!,
                                  isToday: week[i]!.date == today,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendSwatch(color: colors.calm, label: context.tr('সব নেওয়া', 'All taken')),
              _LegendSwatch(color: colors.warm, label: context.tr('বাদ', 'Missed')),
              _LegendSwatch(color: colors.sage, label: context.tr('বাকি', 'Future')),
              _LegendSwatch(
                color: colors.calm,
                label: context.tr('কিছুটা', 'Some taken'),
                half: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCellView extends StatelessWidget {
  const _DayCellView({required this.cell, required this.isToday});

  final DayCell cell;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = switch (cell.state) {
      DayState.full => colors.calm,
      DayState.missed => colors.warm,
      _ => colors.sage,
    };
    // The date sits on the cell, so "did I miss Tuesday?" can be answered by reading rather than
    // by counting columns.
    final onFill = switch (cell.state) {
      DayState.full || DayState.missed => colors.paper,
      DayState.partial => colors.ink,
      _ => colors.ink3,
    };
    final label = Center(
      child: Text(
        context.num(cell.date.day),
        style: context.type.meta.copyWith(
          fontSize: 11,
          height: 1.0,
          color: onFill,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(9),
        // The "today" ring sits outside the cell, so it must not shrink the fill.
        border: isToday ? Border.all(color: colors.ink, width: 2.5) : null,
      ),
      child: cell.state == DayState.partial
          // 135° diagonal split: calm top-left triangle over the sage base.
          ? ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CustomPaint(
                painter: _DiagonalHalfPainter(colors.calm),
                child: label,
              ),
            )
          : label,
    );
  }
}

class _DiagonalHalfPainter extends CustomPainter {
  const _DiagonalHalfPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DiagonalHalfPainter old) => old.color != color;
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label, this.half = false});

  final Color color;
  final String label;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ColoredBox(
              color: half ? colors.sage : color,
              // Mirrors the grid cell's 135° split so the legend matches what's drawn.
              child: half
                  ? CustomPaint(painter: _DiagonalHalfPainter(color))
                  : const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: context.type.meta.copyWith(color: colors.ink3)),
      ],
    );
  }
}

class _MedBar extends StatelessWidget {
  const _MedBar({required this.m});

  final MedAdherence m;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final good = m.percent >= 80;
    return Row(
      children: [
        MedicineMark(shape: m.medicine.mark, color: Color(m.medicine.markColor), size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(
            m.medicine.displayName,
            style: context.type.meta.copyWith(color: colors.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 9,
              child: ColoredBox(
                color: colors.sage,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (m.percent / 100).clamp(0.0, 1.0),
                  child: ColoredBox(color: good ? colors.calm : colors.warm),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(context.percent(m.percent), style: context.type.meta.copyWith(color: colors.ink2)),
      ],
    );
  }
}


/// What happened on one day, opened by tapping its cell in the grid.
class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepoBuilder<List<TimelineBlock>>(
      query: (repo) => repo.timelineFor(date),
      loading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: SizedBox(height: 20),
      ),
      builder: (context, blocks) {
        final doses = [for (final b in blocks) ...b.doses];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateStringFor(date, context.locale),
              style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 14),
            if (doses.isEmpty)
              Text(
                context.tr(
                  'এই দিনে কোনো ডোজ ছিল না।',
                  'No doses were scheduled that day.',
                ),
                style: context.type.body.copyWith(color: colors.ink2),
              )
            else
              for (final d in doses)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimens.cardGap),
                  child: Row(
                    children: [
                      MedicineMark(
                        shape: d.medicine.mark,
                        color: Color(d.medicine.markColor),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.medicine.displayName,
                              style: context.type.cardTitleSecondary
                                  .copyWith(color: colors.ink),
                            ),
                            Text(
                              context.clock(d.dose.hour, d.dose.minute),
                              style: context.type.meta.copyWith(color: colors.ink3),
                            ),
                          ],
                        ),
                      ),
                      _StatusWord(status: d.dose.status),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StatusWord extends StatelessWidget {
  const _StatusWord({required this.status});

  final DoseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (text, bg, fg) = switch (status) {
      DoseStatus.taken => (context.tr('নেওয়া হয়েছে', 'Taken'), colors.calmSoft, colors.calmD),
      DoseStatus.takenLate =>
        (context.tr('দেরিতে নেওয়া', 'Taken late'), colors.calmSoft, colors.calmD),
      DoseStatus.missed => (context.tr('বাদ পড়েছে', 'Missed'), colors.warmSoft, colors.warmD),
      DoseStatus.skipped => (context.tr('বাদ দেওয়া', 'Skipped'), colors.sage, colors.ink2),
      DoseStatus.upcoming => (context.tr('বাকি', 'Upcoming'), colors.sage, colors.ink2),
    };
    return StatusPill(text: text, background: bg, contentColor: fg);
  }
}


/// The one place the app volunteers a pattern rather than a number. Worded as an observation with
/// a concrete next step, never as a reprimand — and it only appears when [NirbhorRepository
/// .weakestBlock] finds evidence strong enough to stand behind.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final BlockInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Inflected into the sentence below, so it is written per language rather than looked up:
    // Bangla takes a genitive ending and Spanish needs no article here.
    final blockName = switch ((context.locale, insight.block)) {
      (AppLocale.bn, TimeBlock.morning) => 'সকালের',
      (AppLocale.bn, TimeBlock.noon) => 'দুপুরের',
      (AppLocale.bn, TimeBlock.night) => 'রাতের',
      (AppLocale.hi, TimeBlock.morning) => 'सुबह',
      (AppLocale.hi, TimeBlock.noon) => 'दोपहर',
      (AppLocale.hi, TimeBlock.night) => 'रात',
      (AppLocale.es, TimeBlock.morning) => 'la mañana',
      (AppLocale.es, TimeBlock.noon) => 'el mediodía',
      (AppLocale.es, TimeBlock.night) => 'la noche',
      (_, TimeBlock.morning) => 'morning',
      (_, TimeBlock.noon) => 'midday',
      (_, TimeBlock.night) => 'evening',
    };

    return NbCard(
      radius: Dimens.radiusLargeCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: colors.calm),
              const SizedBox(width: 8),
              Text(
                context.tr('একটা জিনিস চোখে পড়ল', 'One thing worth noticing'),
                style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              '$blockName ডোজ বাকিগুলোর চেয়ে বেশি বাদ পড়ছে — গত ৩০ দিনে '
                  '${context.num(insight.missed)}টি।',
              'The $blockName dose is missed more than the rest — '
                  '${insight.missed} times in the last 30 days.', hi: '$blockName की खुराक बाकियों से ज़्यादा छूटती है — पिछले 30 दिनों में ${insight.missed} बार।', es: 'La dosis de $blockName se salta más que las demás: ${insight.missed} veces en los últimos 30 días.',
            ),
            style: context.type.body.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'ওই সময়টা বদলে দিলে হয়তো সুবিধা হবে। ওষুধের পাতায় সময় বদলানো যায়।',
              'Moving that time might help. You can change it on the medicine.',
            ),
            style: context.type.meta.copyWith(color: colors.ink3),
          ),
        ],
      ),
    );
  }
}
