import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/app_settings.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';

/// Onboarding (2q/2a) — the calm-filled welcome, the three-step promise, and the language choice.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final store = context.settingsStore;

    final steps = [
      context.tr('পাতা স্ক্যান করে ওষুধ যোগ করুন', 'Add a medicine by scanning the pack'),
      context.tr('সময়মতো মনে করিয়ে দেওয়া হবে', 'Get reminded at the right time'),
      context.tr('পরিবার চাইলে হিসাব পায়', 'Your family can follow along'),
    ];

    return Scaffold(
      backgroundColor: colors.calm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                // Pill glyph.
                child: Container(
                  width: 28,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Archivo carries no Bengali, so the brand name must name its family explicitly.
              Text(
                'নির্ভর',
                style: context.type
                    .asBangla(context.type.header)
                    .copyWith(color: colors.paper.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(
                  'সময়মতো ওষুধ,\nনিশ্চিন্ত পরিবার।',
                  'Medicine on time,\na family at ease.',
                ),
                style: context.type.titleHero.copyWith(
                  fontSize: 40,
                  height: context.isBangla ? kBanglaMinLine : 1.2,
                  color: colors.paper,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr(
                  'নির্ভর আপনাকে প্রতিটি ডোজ মনে করিয়ে দেয়, হিসাব রাখে, আর দরকারে পরিবারকে জানায়।',
                  'Nirbhor reminds you of every dose, keeps the record, and tells your family when it matters.',
                ),
                style: context.type.body.copyWith(color: colors.paper.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 26),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            context.num(i + 1),
                            style: context.type.cardTitleSecondary.copyWith(color: colors.paper),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: context.type.cardTitleSecondary.copyWith(color: colors.paper),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              Material(
                color: colors.paper,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final nav = context.nav;
                    await store.setOnboardingComplete(true);
                    nav.finishOnboarding();
                    // Ask for the alarm permissions right after the first screen lands, while the
                    // patient still has the promise in mind.
                    await nav.openPermissionPriming();
                  },
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('শুরু করুন', 'Get started'),
                          style: context.type.buttonLabel.copyWith(color: colors.calm),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: colors.calm),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _LangPill(
                    label: 'বাংলা',
                    selected: context.isBangla,
                    bangla: true,
                    onTap: () => store.setLocale(LocalePref.bn),
                  ),
                  const SizedBox(width: 10),
                  _LangPill(
                    label: 'English',
                    selected: !context.isBangla,
                    bangla: false,
                    onTap: () => store.setLocale(LocalePref.en),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('· যেকোনো সময় বদলানো যাবে', '· change any time'),
                      style: context.type.meta
                          .copyWith(color: colors.paper.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.bangla,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// "বাংলা" must be set in Anek Bangla even while the English locale is active — Archivo has no
  /// Bengali glyphs, so it would otherwise fall through to a system font or to tofu.
  final bool bangla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.type.cardTitleSecondary;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Dimens.tapMin),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.paper : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.paper.withValues(alpha: selected ? 1 : 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: (bangla ? context.type.asBangla(base) : context.type.asLatin(base))
                .copyWith(color: selected ? colors.calm : colors.paper),
          ),
        ),
      ),
    );
  }
}
