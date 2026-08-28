import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

const String _supportEmail = 'support@nirbhor.app';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _showAddress = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final questions = <(String, String)>[
      (
        context.tr("অ্যালার্ম না এলে কী করব?", "What if alarms don't appear?"),
        context.tr(
          'সেটিংসে নোটিফিকেশন, অ্যালার্ম ও ব্যাটারি অনুমতি চালু আছে কি না দেখুন।',
          'Check notification, alarm, and battery permissions in Android settings.',
        ),
      ),
      (
        context.tr('ভুল করে খেয়েছি চাপলে?', 'What if I tap Taken by mistake?'),
        context.tr(
          'হোম স্ক্রিনের নিচে ৫ সেকেন্ডের জন্য ফিরে নেওয়ার বোতাম আসে।',
          'Use Undo at the bottom of Home within five seconds.',
        ),
      ),
      (
        context.tr('স্ক্যান কাজ না করলে?', 'What if scanning fails?'),
        context.tr(
          'আলো বাড়িয়ে আবার চেষ্টা করুন, গ্যালারি থেকে পরিষ্কার ছবি নিন, অথবা নাম লিখুন।',
          'Try better lighting, choose a clear gallery photo, or enter the name manually.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(title: context.tr('সাহায্য', 'Help'), onBack: context.nav.back),
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
                    for (final (question, answer) in questions) ...[
                      NbCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question,
                              style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                answer,
                                style: context.type.body.copyWith(color: colors.ink2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SecondaryButton(
                      text: context.tr('ইমেইলে যোগাযোগ করুন', 'Contact by email'),
                      onPressed: () async {
                        final uri = Uri(scheme: 'mailto', path: _supportEmail);
                        // A phone with no mail app would otherwise make this button look broken.
                        final launched = await canLaunchUrl(uri) &&
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!launched && mounted) setState(() => _showAddress = true);
                      },
                    ),
                    if (_showAddress) ...[
                      const SizedBox(height: 12),
                      TintPanel(
                        background: colors.sage,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'এই ফোনে ইমেইল অ্যাপ পাওয়া যায়নি। ঠিকানাটি হলো:',
                                'No email app was found on this phone. The address is:',
                              ),
                              style: context.type.body.copyWith(color: colors.ink2),
                            ),
                            Text(
                              _supportEmail,
                              // An email address is a Latin run whatever the active locale.
                              style: context.type
                                  .asLatin(context.type.cardTitleSecondary)
                                  .copyWith(color: colors.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
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
