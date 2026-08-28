import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../domain/stock_calculator.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/overlays.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';

/// Refill & stock (2u/2g) — the low-stock alert, the per-medicine bars, and the restock sheet.
class RefillScreen extends StatelessWidget {
  const RefillScreen({super.key});

  Future<void> _restock(BuildContext context, Medicine med, int current) async {
    final added = await showNbSheet<int>(
      context,
      (context) => _RestockSheet(medicine: med, current: current),
    );
    if (added != null && added > 0 && context.mounted) {
      await context.repo.addStock(med.id, added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('রিফিল ও মজুত', 'Refill & stock'),
            onBack: context.nav.back,
          ),
          Expanded(
            child: RepoBuilder<(List<Medicine>, List<StockStatus>)>(
              query: (repo) async => (await repo.medicines(), await repo.stockStatuses()),
              builder: (context, data) {
                final (medicines, stock) = data;
                final stockById = {for (final s in stock) s.medicineId: s};

                Medicine? lowest;
                var lowestDays = 1 << 30;
                for (final m in medicines) {
                  final d = stockById[m.id]?.daysRemaining ?? (1 << 30);
                  if (d < lowestDays) {
                    lowestDays = d;
                    lowest = m;
                  }
                }
                final lowestStock = lowest == null ? null : stockById[lowest.id];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.screenPadding,
                    vertical: 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lowest != null && lowestStock != null && lowestStock.isLow) ...[
                          _LowAlertCard(
                            med: lowest,
                            stock: lowestStock,
                            onRestock: () => _restock(context, lowest!, lowestStock.count),
                          ),
                          const SizedBox(height: Dimens.groupGap),
                        ],
                        if (medicines.isEmpty) ...[
                          Text(
                            context.tr(
                              'এখনও কোনো ওষুধ যোগ করা হয়নি।',
                              'No medicines have been added yet.',
                            ),
                            style: context.type.body.copyWith(color: colors.ink2),
                          ),
                          const SizedBox(height: Dimens.cardGap),
                          PrimaryButton(
                            text: context.tr('ওষুধ যোগ করুন', 'Add a medicine'),
                            onPressed: context.nav.startAddMedicine,
                          ),
                        ] else
                          for (final m in medicines) ...[
                            _StockRow(
                              med: m,
                              stock: stockById[m.id],
                              onRestock: () =>
                                  _restock(context, m, stockById[m.id]?.count ?? 0),
                            ),
                            const SizedBox(height: Dimens.cardGap),
                          ],
                        const SizedBox(height: Dimens.groupGap),
                        TintPanel(
                          background: colors.sage,
                          child: Text(
                            context.tr(
                              'প্রতিটি ওষুধ কত দিন চলবে তা রোজ হিসাব করা হয়। ৫ দিনের কম থাকলে সতর্কবার্তা যায়।',
                              "Days remaining is recalculated daily. You're warned when fewer than 5 days are left.",
                            ),
                            style: context.type.body.copyWith(color: colors.ink2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LowAlertCard extends StatelessWidget {
  const _LowAlertCard({required this.med, required this.stock, required this.onRestock});

  final Medicine med;
  final StockStatus stock;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remainingDays = stock.daysRemaining ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: colors.warmSoft,
        borderRadius: BorderRadius.circular(Dimens.radiusLargeCard),
        border: Border.all(color: colors.warm.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(context.tr('ফুরিয়ে আসছে', 'Running low'), color: colors.warmD),
          const SizedBox(height: 10),
          Row(
            children: [
              MedicineMark(shape: med.mark, color: Color(med.markColor), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.displayName,
                      style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                    ),
                    Text(
                      context.tr(
                        '${context.num(stock.count)}টি ${med.form} বাকি · ${context.num(remainingDays)} দিন চলবে',
                        '${stock.count} ${med.form} left · $remainingDays days',
                      ),
                      style: context.type.meta.copyWith(color: colors.warmD),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SegmentBar(filled: stock.count.clamp(0, 10)),
          const SizedBox(height: 12),
          PrimaryButton(
            text: context.tr('আরও কিনেছি', 'Bought more'),
            onPressed: onRestock,
            height: 58,
            container: colors.warmD,
            content: colors.paper,
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 0; i < 10; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: i < filled ? colors.warm : colors.warm.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.med, required this.stock, required this.onRestock});

  final Medicine med;
  final StockStatus? stock;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // null means "no rate to divide by" (paused, or no times set) — never an infinite supply.
    final days = stock?.daysRemaining;
    final low = stock?.isLow ?? false;
    final count = stock?.count ?? 0;

    return NbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MedicineMark(shape: med.mark, color: Color(med.markColor), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.displayName,
                      style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                    ),
                    Text(
                      days == null
                          ? context.tr(
                              '${context.num(count)}টি ${med.form} · ${med.paused ? "এখন বন্ধ" : "সময় ঠিক করা নেই"}',
                              '$count ${med.form} · ${med.paused ? "paused" : "no times set"}',
                            )
                          : context.tr(
                              '${context.num(count)}টি ${med.form} · ${context.num(days)} দিন চলবে',
                              '$count ${med.form} · $days days',
                            ),
                      style: context.type.meta.copyWith(color: colors.ink3),
                    ),
                  ],
                ),
              ),
              if (low)
                StatusPill(
                  text: context.tr('শীঘ্রই', 'Soon'),
                  background: colors.warmSoft,
                  contentColor: colors.warmD,
                )
              else if (days == null)
                StatusPill(
                  text: context.tr('বন্ধ', 'Paused'),
                  background: colors.sage,
                  contentColor: colors.ink2,
                )
              else
                StatusPill(
                  text: context.tr('ঠিক আছে', 'OK'),
                  background: colors.calmSoft,
                  contentColor: colors.calmD,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: ColoredBox(
                color: colors.sage,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((days ?? 0) / 30).clamp(0.0, 1.0),
                  child: ColoredBox(color: low ? colors.warm : colors.calm),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // The sheet only adds to the count; correcting it downward lives on the medicine screen.
          PrimaryButton(
            text: context.tr('আরও যোগ করুন', 'Add more'),
            onPressed: onRestock,
            height: 48,
          ),
        ],
      ),
    );
  }
}

class _RestockSheet extends StatefulWidget {
  const _RestockSheet({required this.medicine, required this.current});

  final Medicine medicine;
  final int current;

  @override
  State<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<_RestockSheet> {
  double _amount = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final medicine = widget.medicine;
    final result = widget.current + _amount.toInt();
    final days = StockCalculator.estimatedDaysFrom(
      stockCount: result,
      dosePerIntake: medicine.dosePerIntake,
      timesPerScheduledDay: medicine.timeTokens.length,
      frequency: medicine.frequency,
      weekdaysMask: medicine.weekdaysMask,
      paused: medicine.paused,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MedicineMark(shape: medicine.mark, color: Color(medicine.markColor), size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                medicine.displayName,
                style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuantityStepper(
          value: _amount,
          onChanged: (v) => setState(() => _amount = v.clamp(1, 10000)),
          valueLabel: context.num(_amount.toInt()),
          unitLabel: context.tr('টি যোগ করুন', 'to add'),
          step: 1,
          min: 1,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final q in const [10, 30, 60, 90]) ...[
              if (q != 10) const SizedBox(width: 8),
              Expanded(
                child: QuickChip(
                  label: context.num(q),
                  selected: _amount.toInt() == q,
                  onTap: () => setState(() => _amount = q.toDouble()),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        TintPanel(
          background: colors.calmSoft,
          child: Text(
            days == null
                ? context.tr(
                    'ঘরে হবে ${context.num(result)}টি — ওষুধটি এখন বন্ধ আছে।',
                    "You'll have $result — this medicine is paused.",
                  )
                : context.tr(
                    'ঘরে হবে ${context.num(result)}টি — প্রায় ${context.num(days)} দিন চলবে।',
                    "You'll have $result — about $days days.",
                  ),
            style: context.type.body.copyWith(color: colors.calmD),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          text: context.tr('যোগ করুন', 'Add'),
          onPressed: () => Navigator.of(context).pop(_amount.toInt()),
        ),
      ],
    );
  }
}
