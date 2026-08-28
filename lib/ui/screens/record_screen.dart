import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/repository.dart';
import '../../domain/dose_scheduler.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
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
                    const SizedBox(height: 18),
                    _DayGrid(cells: data.cells),
                    const SizedBox(height: 18),
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
  const _RecordData({required this.window, required this.cells, required this.perMed});

  final AdherenceWindow window;
  final List<DayCell> cells;
  final List<MedAdherence> perMed;
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
                          '${window.missed} doses were missed in this period.',
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

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.cells});

  final List<DayCell> cells;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final headers = context.isBangla ? _bnWeekHeaders : _enWeekHeaders;
    final today = dateOnly(DateTime.now());

    // Chunk cells into weeks of 7. Pad the first week so weekday columns align (Mon = column 0).
    final firstDow = cells.isEmpty ? 0 : cells.first.date.weekday - 1;
    final padded = <DayCell?>[...List<DayCell?>.filled(firstDow, null), ...cells];
    final weeks = <List<DayCell?>>[];
    for (var i = 0; i < padded.length; i += 7) {
      weeks.add(padded.sublist(i, i + 7 > padded.length ? padded.length : i + 7));
    }

    return NbCard(
      padding: 13,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                            ? _DayCellView(
                                cell: week[i]!,
                                isToday: week[i]!.date == today,
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
                child: const SizedBox.expand(),
              ),
            )
          : const SizedBox.expand(),
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
