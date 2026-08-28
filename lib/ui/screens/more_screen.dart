import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/surfaces.dart';

/// The app version shown at the foot of the hub. Kept here rather than read from the platform so
/// the number in the UI is the one this build was cut with.
const String kAppVersion = '1.0.0';

/// More hub (6a) — the patient card and the two groups of secondary destinations.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.paper,
      child: RepoBuilder<(List<Medicine>, List<StockStatus>)>(
        query: (repo) async => (await repo.medicines(), await repo.stockStatuses()),
        builder: (context, data) {
          final (medicines, stock) = data;
          final lowCount = stock.where((s) => s.isLow).length;

          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('আরও', 'More'),
                    style: context.type.titleHero.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  // Patient card.
                  NbCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.calmSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            context.tr('আ', 'Y'),
                            style: context.type.header.copyWith(color: colors.calmD),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('আপনি', 'You'),
                                style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                              ),
                              Text(
                                context.tr(
                                  '${context.num(medicines.length)}টি ওষুধ',
                                  '${medicines.length} medicines',
                                ),
                                style: context.type.meta.copyWith(color: colors.ink3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  _HubRow(
                    icon: Icons.people,
                    label: context.tr('পরিবার ও যত্নকারী', 'Family & caregivers'),
                    explainer: context.tr('কে হিসাব পায় তা ঠিক করুন', 'Choose who follows along'),
                    onTap: context.nav.openFamily,
                  ),
                  const SizedBox(height: Dimens.cardGap),
                  _HubRow(
                    icon: Icons.inventory_2,
                    label: context.tr('ওষুধের মজুত', 'Stock'),
                    explainer: context.tr("ঘরে কতটা আছে দেখুন", "See what's left at home"),
                    amber: lowCount > 0
                        ? context.tr(
                            '${context.num(lowCount)}টি ফুরিয়ে আসছে',
                            '$lowCount running low',
                          )
                        : null,
                    onTap: context.nav.openRefill,
                  ),
                  const SizedBox(height: Dimens.cardGap),
                  _HubRow(
                    icon: Icons.picture_as_pdf,
                    label: context.tr('ডাক্তারের রিপোর্ট', 'Doctor report'),
                    explainer: context.tr('পিডিএফ বানিয়ে পাঠান', 'Make and share a PDF'),
                    onTap: context.nav.openDoctorReport,
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  _HubRow(
                    icon: Icons.settings,
                    label: context.tr('সেটিংস', 'Settings'),
                    explainer: context.tr(
                      'ভাষা, মনে করিয়ে দেওয়া, পড়ার সুবিধা',
                      'Language, reminders, reading',
                    ),
                    onTap: context.nav.openSettings,
                  ),
                  const SizedBox(height: Dimens.cardGap),
                  _HubRow(
                    icon: Icons.help_outline,
                    label: context.tr('সাহায্য', 'Help'),
                    explainer: context.tr('সাধারণ প্রশ্ন ও যোগাযোগ', 'FAQ and contact'),
                    onTap: context.nav.openHelp,
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  Text(
                    context.tr(
                      'নির্ভর · সংস্করণ ${context.numStr(kAppVersion)}',
                      'Nirbhor · version $kAppVersion',
                    ),
                    style: context.type.meta.copyWith(color: colors.ink3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.label,
    required this.explainer,
    required this.onTap,
    this.amber,
  });

  final IconData icon;
  final String label;
  final String explainer;
  final String? amber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NbCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sage,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: colors.ink2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.type.cardTitleSecondary.copyWith(color: colors.ink)),
                Text(
                  amber ?? explainer,
                  style: context.type.meta
                      .copyWith(color: amber != null ? colors.warmD : colors.ink3),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_right, color: colors.ink3),
        ],
      ),
    );
  }
}
