import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/labels.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';

/// Medicine cabinet (2s/2e) — every medicine, its schedule in words, and its stock warning.
class CabinetScreen extends StatelessWidget {
  const CabinetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.paper,
      child: RepoBuilder<(List<Medicine>, List<StockStatus>)>(
        query: (repo) async => (await repo.medicines(), await repo.stockStatuses()),
        builder: (context, data) {
          final (medicines, stock) = data;
          final stockById = {for (final s in stock) s.medicineId: s};

          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.screenPadding,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Text(
                        context.tr('ওষুধের তালিকা', 'Medicines'),
                        style: context.type.titleHero.copyWith(color: colors.ink),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.sage,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          context.num(medicines.length),
                          style: context.type.statusPill.copyWith(color: colors.ink2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: medicines.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                'এখনও কোনো ওষুধ যোগ করা হয়নি',
                                'No medicines added yet',
                              ),
                              style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr(
                                'পাতা স্ক্যান করলে নাম আর শক্তি নিজেই পড়ে নেবে — অথবা নাম লিখে যোগ করুন।',
                                'Scanning a pack reads the name and strength for you — or add one by typing its name.',
                              ),
                              style: context.type.body.copyWith(color: colors.ink2),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Dimens.screenPadding,
                          0,
                          Dimens.screenPadding,
                          8,
                        ),
                        itemCount: medicines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: Dimens.cardGap),
                        itemBuilder: (context, i) {
                          final med = medicines[i];
                          return _MedicineRow(
                            med: med,
                            stock: stockById[med.id],
                            onTap: () => context.nav.openMedicine(med.id),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  0,
                  Dimens.screenPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      text: context.tr('ওষুধ যোগ করুন', 'Add a medicine'),
                      onPressed: context.nav.startAddMedicine,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    SecondaryButton(
                      text: context.tr('পাতা বা বাক্স স্ক্যান করুন', 'Scan a pack or box'),
                      onPressed: context.nav.startScan,
                      height: 60,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.med, required this.stock, required this.onTap});

  final Medicine med;
  final StockStatus? stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final low = stock != null && stock!.isLow;
    return NbCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.calmSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: MedicineMark(shape: med.mark, color: Color(med.markColor), size: 27),
          ),
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
                  scheduleSummary(context, med),
                  style: context.type.meta.copyWith(color: colors.ink3),
                ),
              ],
            ),
          ),
          if (low)
            StatusPill(
              text: context.tr(
                '${context.num(stock!.count)}টি বাকি',
                '${stock!.count} left', hi: '${stock!.count} बची', es: 'quedan ${stock!.count}',
              ),
              background: colors.warmSoft,
              contentColor: colors.warmD,
            )
          else
            Semantics(
              label: context.tr('ওষুধের বিস্তারিত খুলুন', 'Open medicine details'),
              child: Icon(Icons.keyboard_arrow_right, size: 24, color: colors.ink3),
            ),
        ],
      ),
    );
  }
}

/// Words, not clock times — e.g. "প্রতিদিন · সকাল, দুপুর, রাত".
String scheduleSummary(BuildContext context, Medicine med) {
  final frequency = switch (med.frequency) {
    Frequency.daily => context.tr('প্রতিদিন', 'Daily'),
    Frequency.alternate => context.tr('একদিন পরপর', 'Every other day'),
    Frequency.weekdays => context.tr('সপ্তাহের কর্মদিবসে', 'On weekdays'),
    Frequency.weekly => context.tr('নির্বাচিত দিনে', 'On selected days'),
  };
  final times = med.timeTokens.map((t) {
    return switch (TimeBlock.fromToken(t)) {
      TimeBlock.morning => context.tr('সকাল', 'morning'),
      TimeBlock.noon => context.tr('দুপুর', 'afternoon'),
      TimeBlock.night => context.tr('রাত', 'night'),
    };
  }).join(', ');
  return '$frequency · $times';
}
