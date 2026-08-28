import 'package:flutter/material.dart';

import '../../domain/dose_scheduler.dart';
import '../../domain/models.dart';
import '../../i18n/numerals.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import 'add_flow_common.dart';

/// When to take it (3c) — the time blocks, the frequency, and the meal relation.
class AddTimingScreen extends StatelessWidget {
  const AddTimingScreen({super.key});

  void _toggle(BuildContext context, String token) {
    final draft = context.draft;
    draft.update(() {
      final tokens = List.of(draft.timeTokens);
      if (!tokens.remove(token)) tokens.add(token);
      // Keep resolved times aligned to selected tokens in block order.
      final ordered = TimeBlock.values.where((b) => tokens.contains(b.token)).toList();
      draft.timeTokens = ordered.map((b) => b.token).toList();
      draft.resolvedTimes = ordered.map(DoseScheduler.blockDefaultTime).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final draft = context.draft;

    return Scaffold(
      backgroundColor: colors.paper,
      body: ListenableBuilder(
        listenable: draft,
        builder: (context, _) {
          final selectedIndex = switch (draft.frequency) {
            Frequency.daily => 0,
            Frequency.alternate => 1,
            Frequency.weekdays || Frequency.weekly => 2,
          };
          final showDays =
              draft.frequency == Frequency.weekly || draft.frequency == Frequency.weekdays;

          final sep = context.tr(' আর ', ' and ');
          final times = draft.resolvedTimes
              .map((hhmm) {
                final parsed = DoseScheduler.parseHhmm(hhmm) ?? (8, 0);
                return Numerals.time(parsed.$1, parsed.$2, context.isBangla, context.is24Hour);
              })
              .join(sep);

          return Column(
            children: [
              AddFlowHeader(step: 1, onBack: context.nav.back),
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
                          context.tr('কখন খাবেন?', 'When do you take it?'),
                          style: context.type.titleHero.copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: Dimens.groupGap),
                        _TimeChoice(
                          icon: Icons.wb_sunny,
                          label: context.tr('সকাল', 'Morning'),
                          selected: draft.timeTokens.contains(TimeBlock.morning.token),
                          onTap: () => _toggle(context, TimeBlock.morning.token),
                        ),
                        const SizedBox(height: Dimens.cardGap),
                        _TimeChoice(
                          icon: Icons.brightness_5,
                          label: context.tr('দুপুর', 'Afternoon'),
                          selected: draft.timeTokens.contains(TimeBlock.noon.token),
                          onTap: () => _toggle(context, TimeBlock.noon.token),
                        ),
                        const SizedBox(height: Dimens.cardGap),
                        _TimeChoice(
                          icon: Icons.dark_mode,
                          label: context.tr('রাত', 'Night'),
                          selected: draft.timeTokens.contains(TimeBlock.night.token),
                          onTap: () => _toggle(context, TimeBlock.night.token),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        Text(
                          context.tr('কত ঘন ঘন?', 'How often?'),
                          style: context.type.header.copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: Dimens.groupGap),
                        SegmentedControl(
                          options: [
                            context.tr('প্রতিদিন', 'Daily'),
                            context.tr('একদিন পরপর', 'Alternate'),
                            context.tr('দিন বেছে', 'Select days'),
                          ],
                          selectedIndex: selectedIndex,
                          onSelect: (index) => draft.update(() {
                            draft.frequency = switch (index) {
                              1 => Frequency.alternate,
                              2 => Frequency.weekly,
                              _ => Frequency.daily,
                            };
                            // Landing on "select days" with nothing ticked would silently mean
                            // "never" — start from today.
                            if (index == 2 && draft.weekdaysMask == 0) {
                              draft.weekdaysMask =
                                  DoseScheduler.weekdayBit(DateTime.now().weekday);
                            }
                          }),
                        ),
                        if (showDays) ...[
                          const SizedBox(height: Dimens.groupGap),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var index = 0; index < 7; index++)
                                SizedBox(
                                  width: 76,
                                  child: QuickChip(
                                    label: [
                                      context.tr('সোম', 'Mon'),
                                      context.tr('মঙ্গল', 'Tue'),
                                      context.tr('বুধ', 'Wed'),
                                      context.tr('বৃহঃ', 'Thu'),
                                      context.tr('শুক্র', 'Fri'),
                                      context.tr('শনি', 'Sat'),
                                      context.tr('রবি', 'Sun'),
                                    ][index],
                                    height: 48,
                                    multiSelect: true,
                                    selected: draft.weekdaysMask & (1 << index) != 0,
                                    onTap: () => draft.update(() {
                                      final next = draft.weekdaysMask ^ (1 << index);
                                      // Never let the last day be unticked into "never".
                                      if (next != 0) draft.weekdaysMask = next;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: Dimens.groupGap),

                        Text(
                          context.tr('খাবারের আগে না পরে?', 'Before or after food?'),
                          style: context.type.header.copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: Dimens.groupGap),
                        Row(
                          children: [
                            Expanded(
                              child: _FoodCard(
                                label: context.tr('আগে / খালি পেটে', 'Before / empty'),
                                selected: draft.foodRelation == FoodRelation.before,
                                onTap: () => draft
                                    .update(() => draft.foodRelation = FoodRelation.before),
                              ),
                            ),
                            const SizedBox(width: Dimens.cardGap),
                            Expanded(
                              child: _FoodCard(
                                label: context.tr('পরে / ভরা পেটে', 'After / full'),
                                selected: draft.foodRelation == FoodRelation.after,
                                onTap: () => draft
                                    .update(() => draft.foodRelation = FoodRelation.after),
                              ),
                            ),
                          ],
                        ),

                        if (draft.timeTokens.isNotEmpty) ...[
                          const SizedBox(height: Dimens.groupGap),
                          TintPanel(
                            background: colors.calmSoft,
                            child: Text(
                              context.tr(
                                'তাহলে অ্যালার্ম বাজবে $times-এ। সময় পছন্দ না হলে পরে বদলে নিতে পারবেন।',
                                'Alarms will ring at $times. You can change the times later.', hi: 'अलार्म $times पर बजेंगे। समय बाद में बदल सकते हैं।', es: 'Las alarmas sonarán a las $times. Puede cambiar las horas después.',
                              ),
                              style: context.type.body.copyWith(color: colors.calmD),
                            ),
                          ),
                        ],
                        const SizedBox(height: Dimens.groupGap),
                        PrimaryButton(
                          text: context.tr('পরের ধাপ', 'Next'),
                          onPressed: context.nav.addQuantity,
                          enabled: draft.timeTokens.isNotEmpty,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeChoice extends StatelessWidget {
  const _TimeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectableRow(
      title: label,
      selected: selected,
      onTap: onTap,
      leading: Icon(icon, size: 34, color: selected ? colors.paper : colors.ink2),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 76,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? colors.calm : colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.calm : colors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: context.type.cardTitleSecondary
                .copyWith(color: selected ? colors.paper : colors.ink),
          ),
        ),
      ),
    );
  }
}
