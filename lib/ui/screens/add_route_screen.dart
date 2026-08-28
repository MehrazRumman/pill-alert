import 'package:flutter/material.dart';

import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Route chooser (3a) — scan the pack, or type the name.
class AddRouteScreen extends StatelessWidget {
  const AddRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('ওষুধ যোগ করুন', 'Add a medicine'),
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
                    // Hero primary card.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.calm,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: nbCardShadow(),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: context.nav.addScan,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: colors.calmD,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    context.tr('সবচেয়ে সহজ', 'Easiest'),
                                    style: context.type.statusPill
                                        .copyWith(color: colors.paper),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: 62,
                                  height: 62,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.calmD,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 30,
                                    color: colors.paper,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  context.tr(
                                    'পাতা বা বাক্স স্ক্যান করুন',
                                    'Scan the pack or box',
                                  ),
                                  style:
                                      context.type.header.copyWith(color: colors.paper),
                                ),
                                Text(
                                  context.tr(
                                    'ক্যামেরা ধরলেই নাম-শক্তি পড়ে নেবে',
                                    'Point the camera; it reads the name and strength',
                                  ),
                                  style: context.type.body.copyWith(
                                    color: colors.paper.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimens.cardGap),
                    _RouteCard(
                      icon: Icons.search,
                      title: context.tr('নাম দিয়ে খুঁজুন', 'Search by name'),
                      subtitle: context.tr('টাইপ বা বলে খুঁজুন', 'Type or speak the name'),
                      onTap: context.nav.addSearch,
                    ),
                    const SizedBox(height: Dimens.cardGap),
                    TintPanel(
                      background: colors.sage,
                      child: Text(
                        context.tr(
                          'চাইলে পরিবারের কেউ আপনার হয়ে ওষুধ যোগ করে দিতে পারেন।',
                          'A family member can add your medicines for you.',
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
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NbCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sage,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: colors.ink2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.type.cardTitlePrimary.copyWith(color: colors.ink)),
                Text(subtitle, style: context.type.meta.copyWith(color: colors.ink3)),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_right, color: colors.ink3),
        ],
      ),
    );
  }
}
