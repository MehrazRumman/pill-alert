import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../domain/patient_profile.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/labels.dart';
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

                  _YouCard(medicineCount: medicines.length),
                  const SizedBox(height: Dimens.groupGap),

                  // Two groups, each one card with hairline dividers rather than a stack of
                  // separate cards. Six shadowed rectangles read as six competing objects; one
                  // grouped surface reads as one list, and the group gap carries the meaning the
                  // per-card gaps used to.
                  _HubGroup(
                    rows: [
                      _HubRow(
                        icon: Icons.people,
                        label: context.tr('পরিবার ও যত্নকারী', 'Family & caregivers'),
                        explainer:
                            context.tr('কে হিসাব পায় তা ঠিক করুন', 'Choose who follows along'),
                        // Flagged here too, so the patient knows before they invest in setting it up.
                        tag: context.tr('শীঘ্রই', 'Soon'),
                        onTap: context.nav.openFamily,
                      ),
                      _HubRow(
                        icon: Icons.inventory_2,
                        label: context.tr('ওষুধের মজুত', 'Stock'),
                        explainer: context.tr("ঘরে কতটা আছে দেখুন", "See what's left at home"),
                        amber: lowCount > 0
                            ? context.tr(
                                '${context.num(lowCount)}টি ফুরিয়ে আসছে',
                                '$lowCount running low', hi: '$lowCount कम पड़ रही हैं', es: '$lowCount con pocas existencias',
                              )
                            : null,
                        onTap: context.nav.openRefill,
                      ),
                      _HubRow(
                        icon: Icons.picture_as_pdf,
                        label: context.tr('ডাক্তারের রিপোর্ট', 'Doctor report'),
                        explainer: context.tr('পিডিএফ বানিয়ে পাঠান', 'Make and share a PDF'),
                        onTap: context.nav.openDoctorReport,
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  _HubGroup(
                    rows: [
                      _HubRow(
                        icon: Icons.settings,
                        label: context.tr('সেটিংস', 'Settings'),
                        explainer: context.tr(
                          'ভাষা, মনে করিয়ে দেওয়া, পড়ার সুবিধা',
                          'Language, reminders, reading',
                        ),
                        onTap: context.nav.openSettings,
                      ),
                      _HubRow(
                        icon: Icons.help_outline,
                        label: context.tr('সাহায্য', 'Help'),
                        explainer: context.tr('সাধারণ প্রশ্ন ও যোগাযোগ', 'FAQ and contact'),
                        onTap: context.nav.openHelp,
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimens.groupGap),

                  Text(
                    context.tr(
                      'নির্ভর · সংস্করণ ${context.numStr(kAppVersion)}',
                      'Nirbhor · version $kAppVersion', hi: 'निर्भर · संस्करण $kAppVersion', es: 'Nirbhor · versión $kAppVersion',
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

/// One grouped list surface. The rows sit on a single card, separated by hairlines indented past
/// the icon column so the divider reads as belonging to the text, not cutting the row in half.
class _HubGroup extends StatelessWidget {
  const _HubGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: Dimens.cardPadding + 38),
            child: Divider(height: 1, thickness: 1, color: context.colors.line),
          ),
        );
      }
      children.add(rows[i]);
    }
    return NbCard(
      padding: 0,
      radius: Dimens.radiusLargeCard,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
    this.tag,
  });

  final IconData icon;
  final String label;
  final String explainer;
  final String? amber;

  /// A short status word shown in place of the chevron, for a destination that is set up but not
  /// yet doing anything.
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Dimens.tapMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.cardPadding,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Bare icon rather than a tinted tile. Six filled tiles down the screen read as
                // decoration competing with the labels; the label is what the patient is scanning.
                SizedBox(
                  width: 22,
                  child: Icon(icon, size: 22, color: colors.ink3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                      ),
                      Text(
                        amber ?? explainer,
                        style: context.type.meta
                            .copyWith(color: amber != null ? colors.warmD : colors.ink3),
                      ),
                    ],
                  ),
                ),
                if (tag != null)
                  StatusPill(
                    text: tag!,
                    background: colors.warmSoft,
                    contentColor: colors.warmD,
                  )
                else
                  Icon(Icons.chevron_right, size: 20, color: colors.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The patient card. Doubles as the entry point to Your details and, once an emergency number is
/// saved, as a one-tap call button — the two things most worth reaching quickly from this hub.
class _YouCard extends StatelessWidget {
  const _YouCard({required this.medicineCount});

  final int medicineCount;

  @override
  Widget build(BuildContext context) {
    final store = context.settingsStore;
    // Rebuilds when the profile is saved, so returning from Your details shows the new name
    // immediately rather than on the next visit.
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _build(context, store.profile),
    );
  }

  Widget _build(BuildContext context, PatientProfile p) {
    final colors = context.colors;
    final name = p.name.trim();
    final age = p.ageOn(DateTime.now());

    // Second line: medicine count first — it is the one fact that is always true — then whichever
    // details have been filled in.
    final bits = <String>[
      context.tr('${context.num(medicineCount)}টি ওষুধ', '$medicineCount medicines', hi: '$medicineCount दवाइयाँ', es: '$medicineCount medicamentos'),
      if (age != null) context.tr('${context.num(age)} বছর', '$age years', hi: '$age वर्ष', es: '$age años'),
      if (p.bloodGroup.isNotEmpty) p.bloodGroup,
    ];

    return NbCard(
      padding: 0,
      radius: Dimens.radiusLargeCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: context.nav.openProfile,
              child: Padding(
                padding: const EdgeInsets.all(Dimens.cardPadding),
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
                        name.isEmpty
                            ? context.tr('আ', 'Y')
                            : name.characters.first.toUpperCase(),
                        style: context.type.header.copyWith(color: colors.calmD),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? context.tr('আপনি', 'You') : name,
                            style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                          ),
                          Text(
                            bits.join(' · '),
                            style: context.type.meta.copyWith(color: colors.ink3),
                          ),
                          if (p.isEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              context.tr('আপনার তথ্য যোগ করুন', 'Add your details'),
                              style: context.type.meta.copyWith(color: colors.calm),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: colors.ink3),
                  ],
                ),
              ),
            ),
          ),
          if (p.hasEmergencyContact) ...[
            Padding(
              padding: const EdgeInsets.only(left: Dimens.cardPadding),
              child: Divider(height: 1, thickness: 1, color: colors.line),
            ),
            _EmergencyCallRow(profile: p),
          ],
        ],
      ),
    );
  }
}

/// One-tap dial for the emergency contact. Handing the number to the dialer rather than placing the
/// call means a mis-tap costs a tap to undo, not an unwanted call.
class _EmergencyCallRow extends StatelessWidget {
  const _EmergencyCallRow({required this.profile});

  final PatientProfile profile;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: profile.emergencyPhone.trim());
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.tr('ফোন অ্যাপ খোলা গেল না।', "Couldn't open the phone app.");
    // A device without a dialer (a tablet) throws here rather than returning false.
    bool launched;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final who = profile.emergencyName.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _call(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Dimens.tapMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.cardPadding,
              vertical: 14,
            ),
            child: Row(
              children: [
                SizedBox(width: 22, child: Icon(Icons.call, size: 22, color: colors.calm)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        who.isEmpty
                            ? context.tr('জরুরি যোগাযোগে ফোন করুন', 'Call emergency contact')
                            : context.tr('$who-কে ফোন করুন', 'Call $who', hi: '$who को फ़ोन करें', es: 'Llamar a $who'),
                        style: context.type.cardTitleSecondary.copyWith(color: colors.calm),
                      ),
                      Text(
                        context.type.isBangla
                            ? context.numStr(profile.emergencyPhone)
                            : profile.emergencyPhone,
                        // Bengali digits need the Bengali face; Archivo has none.
                        style: (context.type.isBangla
                                ? context.type.meta
                                : context.type.asLatin(context.type.meta))
                            .copyWith(color: colors.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
