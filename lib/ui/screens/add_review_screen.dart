import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/dose_scheduler.dart';
import '../../domain/models.dart';
import '../../i18n/numerals.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/alarm_scheduler.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/overlays.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';
import 'add_flow_common.dart';

/// Review and confirm (3e) — the summary, the duplicate warning, and a live alarm preview.
class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  bool _saving = false;
  bool _saveError = false;

  Future<void> _save() async {
    if (_saving) return;
    final draft = context.draft;

    // Checked before anything is written. Nirbhor gives no medical advice, so this asks rather than
    // blocks — the patient may well have been told to take it anyway.
    final matches = context.settingsStore.profile.allergyMatches(draft.allergyHaystack);
    if (matches.isNotEmpty) {
      final named = matches.join(', ');
      final proceed = await confirmAction(
        context,
        title: context.tr('অ্যালার্জির সঙ্গে মিলছে', 'This matches a recorded allergy'),
        message: context.tr(
          'আপনার তথ্যে "$named" অ্যালার্জি হিসেবে লেখা আছে। নিশ্চিত না হলে ডাক্তারকে জিজ্ঞেস করুন।',
          'Your details record "$named" as an allergy. Ask your doctor if you are unsure.', hi: 'आपकी जानकारी में "$named" एलर्जी के रूप में दर्ज है। संदेह हो तो डॉक्टर से पूछें।', es: 'Sus datos registran "$named" como alergia. Pregunte a su médico si tiene dudas.',
        ),
        confirmLabel: context.tr('তবুও যোগ করুন', 'Add anyway'),
        cancelLabel: context.tr('ফিরে যান', 'Go back'),
      );
      if (!proceed || !mounted) return;
    }

    setState(() {
      _saving = true;
      _saveError = false;
    });
    final repo = context.repo;
    final store = context.settingsStore;
    final localeCode = context.locale.code;
    final nav = context.nav;
    try {
      final removed = await repo.upsertMedicine(draft.toMedicine());
      await AlarmScheduler.clearForDoses(removed);
      await AlarmScheduler.rescheduleAll(
        repo,
        settings: AppSettingsView.from(store, localeCode),
      );
      // Don't reset here — this screen is still mounted during the transition and would flash
      // empty. Every entry point into the flow resets the draft.
      nav.finishAddMedicine();
    } catch (_) {
      if (mounted) setState(() => _saveError = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final draft = context.draft;
    final bangla = context.isBangla;

    final whenWords = draft.timeTokens.map((t) {
      return switch (TimeBlock.fromToken(t)) {
        TimeBlock.morning => context.tr('সকাল', 'morning'),
        TimeBlock.noon => context.tr('দুপুর', 'afternoon'),
        TimeBlock.night => context.tr('রাত', 'night'),
      };
    }).join(', ');

    final foodWords = switch (draft.foodRelation) {
      FoodRelation.before => context.tr('খাবারের আগে', 'before food'),
      FoodRelation.after => context.tr('খাবারের পরে', 'after food'),
      FoodRelation.none => context.tr('যেকোনো সময়', 'any time'),
    };

    final frequencyWords = switch (draft.frequency) {
      Frequency.daily => context.tr('প্রতিদিন', 'Daily'),
      Frequency.alternate => context.tr('একদিন পরপর', 'Every other day'),
      Frequency.weekdays => context.tr('কর্মদিবসে', 'Weekdays'),
      Frequency.weekly => context.tr('নির্বাচিত দিনে', 'Selected days'),
    };

    final firstTime = draft.resolvedTimes.isEmpty
        ? (8, 0)
        : DoseScheduler.parseHhmm(draft.resolvedTimes.first) ?? (8, 0);

    final details =
        [draft.strength, draft.form].where((s) => s.trim().isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: colors.paper,
      body: RepoBuilder<List<Medicine>>(
        query: (repo) => repo.medicines(),
        loading: Column(children: [AddFlowHeader(step: 3, onBack: context.nav.back)]),
        builder: (context, existing) {
          final name = draft.displayName.trim().toLowerCase();
          final strength = draft.strength.trim().toLowerCase();
          final allergyHits =
              context.settingsStore.profile.allergyMatches(draft.allergyHaystack);
          final duplicate = existing.any((m) =>
              m.displayName.trim().toLowerCase() == name &&
              m.strength.trim().toLowerCase() == strength);

          return Column(
            children: [
              AddFlowHeader(step: 3, onBack: context.nav.back),
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
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.calmSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.check, size: 34, color: colors.calmD),
                        ),
                        const SizedBox(height: Dimens.groupGap),
                        Text(
                          context.tr('একবার মিলিয়ে নিন', 'Just double-check'),
                          style: context.type.titleHero.copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        if (allergyHits.isNotEmpty) ...[
                          TintPanel(
                            background: colors.warmSoft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'আপনার অ্যালার্জির তালিকার সঙ্গে মিলছে',
                                    'This matches your allergy list',
                                  ),
                                  style: context.type.cardTitleSecondary
                                      .copyWith(color: colors.warmD),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr(
                                    '"${allergyHits.join(', ')}" আপনার তথ্যে অ্যালার্জি হিসেবে লেখা আছে।',
                                    '"${allergyHits.join(', ')}" is recorded in your details as an allergy.',
                                    hi: '"${allergyHits.join(', ')}" आपकी जानकारी में एलर्जी के रूप में दर्ज है।',
                                    es: '"${allergyHits.join(', ')}" está registrada en sus datos como alergia.',
                                  ),
                                  style: context.type.body.copyWith(color: colors.warmD),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Dimens.groupGap),
                        ],

                        if (duplicate) ...[
                          TintPanel(
                            background: colors.warmSoft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'একই নামের ওষুধ আগে থেকেই আছে',
                                    'A medicine with this name already exists',
                                  ),
                                  style: context.type.cardTitleSecondary
                                      .copyWith(color: colors.warmD),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr(
                                    'নির্ভর পরামর্শ দেয় না — দিনে তিনবারও ঠিক হতে পারে। প্রয়োজনে ডাক্তারকে জিজ্ঞেস করুন।',
                                    'Nirbhor gives no advice — three times daily can be correct. Ask your doctor if unsure.',
                                  ),
                                  style: context.type.meta.copyWith(color: colors.ink2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Dimens.groupGap),
                        ],

                        NbCard(
                          padding: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                color: colors.calmSoft,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    MedicineMark(
                                      shape: draft.mark,
                                      color: Color(draft.markColor),
                                      size: 42,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            draft.displayName.trim().isEmpty
                                                ? context.tr('নতুন ওষুধ', 'New medicine')
                                                : draft.displayName,
                                            style: context.type.cardTitlePrimary
                                                .copyWith(color: colors.ink),
                                          ),
                                          if (details.isNotEmpty)
                                            Text(
                                              details,
                                              style: context.type.meta
                                                  .copyWith(color: colors.ink3),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _ReviewRow(
                                label: context.tr('কখন', 'When'),
                                value: '$whenWords · $foodWords',
                              ),
                              _ReviewRow(
                                label: context.tr('কত ঘন ঘন', 'Frequency'),
                                value: frequencyWords,
                              ),
                              _ReviewRow(
                                label: context.tr('কতটা', 'How much'),
                                value:
                                    '${Numerals.quantity(draft.dosePerIntake, bangla)} ${draft.form}',
                              ),
                              if (draft.stockCount > 0)
                                _ReviewRow(
                                  label: context.tr('ঘরে আছে', 'In stock'),
                                  value: context.tr(
                                    '${context.num(draft.stockCount)}টি',
                                    '${draft.stockCount}',
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (_saveError) ...[
                          const SizedBox(height: Dimens.groupGap),
                          TintPanel(
                            background: colors.warmSoft,
                            child: Text(
                              context.tr(
                                'ওষুধটি সেভ হয়নি। আবার চেষ্টা করুন।',
                                "The medicine wasn't saved. Please try again.",
                              ),
                              style: context.type.body.copyWith(color: colors.warmD),
                            ),
                          ),
                        ],
                        const SizedBox(height: Dimens.groupGap),

                        // Live alarm preview.
                        Container(
                          decoration: BoxDecoration(
                            color: colors.calmD,
                            borderRadius: BorderRadius.circular(Dimens.radiusLargeCard),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'অ্যালার্মে এমন দেখাবে',
                                  'The alarm will look like this',
                                ),
                                style: context.type.meta.copyWith(
                                  color: colors.alarmText.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.clock(firstTime.$1, firstTime.$2),
                                style:
                                    context.type.header.copyWith(color: colors.alarmText),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    // On the dark surface the mark lightens, exactly as it will
                                    // on the real alarm.
                                    MedicineMark(
                                      shape: draft.mark,
                                      color: colors.markCalmOnDark,
                                      size: 34,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        draft.displayName.trim().isEmpty
                                            ? '—'
                                            : draft.displayName,
                                        style: context.type.alarmName
                                            .copyWith(color: colors.alarmText),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        PrimaryButton(
                          text: context.tr('যোগ করুন', 'Add medicine'),
                          height: 68,
                          enabled: !_saving &&
                              draft.displayName.trim().isNotEmpty &&
                              draft.timeTokens.isNotEmpty,
                          onPressed: _save,
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: context.type.meta.copyWith(color: colors.ink3)),
          ),
          Expanded(
            child: Text(
              value,
              style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
