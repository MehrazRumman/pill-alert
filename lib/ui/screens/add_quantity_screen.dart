import 'package:flutter/material.dart';

import '../../domain/stock_calculator.dart';
import '../../i18n/numerals.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import 'add_flow_common.dart';

/// How much each time, and how many at home (3d).
class AddQuantityScreen extends StatefulWidget {
  const AddQuantityScreen({super.key});

  @override
  State<AddQuantityScreen> createState() => _AddQuantityScreenState();
}

class _AddQuantityScreenState extends State<AddQuantityScreen> {
  double? _dose;
  double? _stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final draft = context.draft;
    final dose = _dose ??= draft.dosePerIntake > 0 ? draft.dosePerIntake : 1;
    final stock = _stock ??= draft.stockCount.toDouble();

    final days = StockCalculator.estimatedDaysFrom(
      stockCount: stock.toInt(),
      dosePerIntake: dose,
      timesPerScheduledDay: draft.timeTokens.length,
      frequency: draft.frequency,
      weekdaysMask: draft.weekdaysMask,
    );

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          AddFlowHeader(step: 2, onBack: context.nav.back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 8,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('একবারে কতটা?', 'How much each time?'),
                      style: context.type.titleHero.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: Dimens.groupGap),
                    NbCard(
                      padding: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuantityStepper(
                            value: dose,
                            onChanged: (v) {
                              final next = v.clamp(0.5, 10.0);
                              setState(() => _dose = next);
                              draft.update(() => draft.dosePerIntake = next);
                            },
                            valueLabel: Numerals.quantity(dose, context.isBangla),
                            unitLabel: draft.form.trim().isEmpty
                                ? context.tr('ট্যাবলেট', 'tablet')
                                : draft.form,
                            step: 0.5,
                            min: 0.5,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final option in <(double, String)>[
                                (0.5, context.tr('আধা', '½')),
                                (1, context.num(1)),
                                (2, context.num(2)),
                                (3, context.num(3)),
                              ]) ...[
                                if (option.$1 != 0.5) const SizedBox(width: 8),
                                Expanded(
                                  child: QuickChip(
                                    label: option.$2,
                                    selected: dose == option.$1,
                                    onTap: () {
                                      setState(() => _dose = option.$1);
                                      draft.update(() => draft.dosePerIntake = option.$1);
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    Text(
                      context.tr('ঘরে এখন কয়টা আছে?', 'How many at home now?'),
                      style: context.type.header.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: Dimens.groupGap),
                    NbCard(
                      padding: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuantityStepper(
                            value: stock,
                            onChanged: (v) {
                              final next = v > 10000 ? 10000.0 : v;
                              setState(() => _stock = next);
                              draft.update(() => draft.stockCount = next.toInt());
                            },
                            valueLabel: context.num(stock.toInt()),
                            unitLabel: context.tr('টি', 'left'),
                            size: 60,
                          ),
                          if (stock > 0) ...[
                            const SizedBox(height: 10),
                            TintPanel(
                              background: colors.calmSoft,
                              child: Text(
                                days == null
                                    ? context.tr(
                                        'সময়সূচি বেছে নিন',
                                        'Choose a valid schedule',
                                      )
                                    : context.tr(
                                        'প্রায় ${context.num(days)} দিন চলবে',
                                        'About $days days',
                                      ),
                                style: context.type.body.copyWith(color: colors.calmD),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    PrimaryButton(
                      text: context.tr('পরের ধাপ', 'Next'),
                      onPressed: () {
                        draft.update(() {
                          draft.dosePerIntake = dose;
                          draft.stockCount = stock.toInt();
                        });
                        context.nav.addReview();
                      },
                    ),
                    const SizedBox(height: 8),
                    SecondaryButton(
                      text: context.tr('বাদ দিন', 'Skip'),
                      onPressed: () {
                        draft.update(() => draft.stockCount = 0);
                        context.nav.addReview();
                      },
                    ),
                    const SizedBox(height: 8),
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
