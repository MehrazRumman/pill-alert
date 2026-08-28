import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Caregiver notification settings (4a) — which channels are on, how often, and the escalation.
class CaregiverNotifyScreen extends StatelessWidget {
  const CaregiverNotifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: RepoBuilder<Caregiver?>(
        query: (repo) => repo.primaryCaregiver(),
        loading: Column(
          children: [
            NirbhorTopBar(
              title: context.tr('কাকে জানানো হবে', 'Caregiver notifications'),
              onBack: context.nav.back,
            ),
          ],
        ),
        builder: (context, caregiver) {
          if (caregiver == null) {
            return Column(
              children: [
                NirbhorTopBar(
                  title: context.tr('কাকে জানানো হবে', 'Caregiver notifications'),
                  onBack: context.nav.back,
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimens.screenPadding),
                  child: TintPanel(
                    background: colors.sage,
                    child: Text(
                      context.tr('আগে একজন যত্নকারী যুক্ত করুন।', 'Add a caregiver first.'),
                      style: context.type.body.copyWith(color: colors.ink2),
                    ),
                  ),
                ),
              ],
            );
          }

          Future<void> save(Caregiver updated) => context.repo.upsertCaregiver(updated);
          void toggleChannel(CaregiverChannel ch) {
            final next = Set<CaregiverChannel>.of(caregiver.channels);
            if (!next.remove(ch)) next.add(ch);
            save(caregiver.copyWith(channels: next));
          }

          return Column(
            children: [
              NirbhorTopBar(
                title: context.tr(
                  '${caregiver.name}-কে জানানো',
                  'Telling ${caregiver.name}', hi: '${caregiver.name} को बताना', es: 'Avisar a ${caregiver.name}',
                ),
                onBack: context.nav.back,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.screenPadding,
                    vertical: 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionLabel(context.tr('কীভাবে জানাব', 'How to tell them')),
                        const SizedBox(height: Dimens.cardGap),
                        _ChannelCard(
                          icon: Icons.mail,
                          title: context.tr('ইমেইল', 'Email'),
                          subtitle: context.tr(
                            'বিনামূল্যে · বিস্তারিত হিসাব পাঠানো যায়',
                            'Free · can send a full record',
                          ),
                          selected: caregiver.channels.contains(CaregiverChannel.email),
                          onTap: () => toggleChannel(CaregiverChannel.email),
                          verifiedEmail: caregiver.emailVerified ? caregiver.email : null,
                        ),
                        const SizedBox(height: Dimens.cardGap),
                        _ChannelCard(
                          icon: Icons.smartphone,
                          title: context.tr('এসএমএস', 'SMS'),
                          subtitle: context.tr(
                            'ইন্টারনেট ছাড়াও পৌঁছায় · ছোট বার্তা',
                            'Reaches without internet · short message',
                          ),
                          selected: caregiver.channels.contains(CaregiverChannel.sms),
                          onTap: () => toggleChannel(CaregiverChannel.sms),
                        ),
                        const SizedBox(height: Dimens.cardGap),
                        _ChannelCard(
                          icon: Icons.notifications_active,
                          title: context.tr('অ্যাপ নোটিফিকেশন', 'App notification'),
                          subtitle: context.tr('তাদের ফোনে জানানো হবে', 'On their phone'),
                          selected: caregiver.channels.contains(CaregiverChannel.app),
                          onTap: () => toggleChannel(CaregiverChannel.app),
                        ),
                        const SizedBox(height: 18),

                        SectionLabel(context.tr('কত ঘন ঘন', 'How often')),
                        const SizedBox(height: Dimens.cardGap),
                        _RadioCard(
                          title: context.tr(
                            'দিনে একবার, সব একসাথে',
                            'Once a day, all together',
                          ),
                          subtitle: context.tr(
                            'রাত ৯:৩০-এ দিনের হিসাব',
                            "Day's summary at 9:30 PM",
                          ),
                          selected: caregiver.digestFrequency == DigestFrequency.dailyDigest,
                          onTap: () => save(
                            caregiver.copyWith(digestFrequency: DigestFrequency.dailyDigest),
                          ),
                        ),
                        const SizedBox(height: Dimens.cardGap),
                        _RadioCard(
                          title: context.tr('প্রতিবার সাথে সাথে', 'Every time, right away'),
                          subtitle: context.tr('বেশি ইমেইল যাবে', 'More emails'),
                          selected: caregiver.digestFrequency == DigestFrequency.immediate,
                          onTap: () => save(
                            caregiver.copyWith(digestFrequency: DigestFrequency.immediate),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Container(
                          decoration: BoxDecoration(
                            color: colors.warmSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'পরপর দুবার বাদ পড়লে সাথে সাথেই জানাব',
                                    'If missed twice in a row, tell them right away',
                                  ),
                                  style: context.type.cardTitleSecondary
                                      .copyWith(color: colors.warmD),
                                ),
                              ),
                              const SizedBox(width: 12),
                              NbSwitch(
                                checked: caregiver.escalateOnSecondMiss,
                                onColor: colors.warmD,
                                onChanged: (v) =>
                                    save(caregiver.copyWith(escalateOnSecondMiss: v)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        TintPanel(
                          background: colors.sage,
                          child: Text(
                            context.tr(
                              'আপনার পরিবার যা যা বার্তা পায়, আপনি সবই দেখতে পান। সর্বশেষ পাঠানো হয়েছে গতকাল।',
                              'You can see every message your family gets. Last sent yesterday.',
                            ),
                            style: context.type.body.copyWith(color: colors.ink2),
                          ),
                        ),
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

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.verifiedEmail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? verifiedEmail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      checked: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.calm : colors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.sage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 24, color: colors.ink2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                        ),
                        Text(
                          subtitle,
                          style: context.type.meta.copyWith(color: colors.ink2),
                        ),
                      ],
                    ),
                  ),
                  CheckCircle(selected: selected, size: 28),
                ],
              ),
              if (verifiedEmail != null) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          verifiedEmail!,
                          // An email address is a Latin run whatever the active locale.
                          style: context.type
                              .asLatin(context.type.meta)
                              .copyWith(color: colors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: colors.calmD),
                      Text(
                        context.tr('যাচাই হয়েছে', 'Verified'),
                        style: context.type.statusPill.copyWith(color: colors.calmD),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.calm : colors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                    ),
                    Text(subtitle, style: context.type.meta.copyWith(color: colors.ink3)),
                  ],
                ),
              ),
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.calm : colors.line,
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
