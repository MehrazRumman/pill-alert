import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/nirbhor_notifications.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/surfaces.dart';

/// Permission priming (5b). Explains what the reminder permissions buy before the system dialog
/// appears, then walks the chain: notifications → exact alarms.
class PermissionPrimingScreen extends StatelessWidget {
  const PermissionPrimingScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final nav = context.nav;
    await context.settingsStore.setPrimingShown(true);
    nav.back();
  }

  /// Exact-alarm access is a separate system screen from the notification prompt, and a reminder
  /// needs both: one to be shown at all, the other to be shown *at the dose time*.
  Future<void> _ask(BuildContext context) async {
    await NirbhorNotifications.requestPermission();
    if (!await NirbhorNotifications.canScheduleExact()) {
      await NirbhorNotifications.requestExactAlarmPermission();
    }
    if (context.mounted) await _finish(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Dimens.screenPadding,
            40,
            Dimens.screenPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.calmSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.notifications_active, size: 38, color: colors.calmD),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr(
                  'সময়মতো জানাতে অনুমতি দরকার',
                  'We need permission to remind you',
                ),
                style: context.type.titleHero.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr(
                  'পরের পর্দায় “অনুমতি দিন” চাপুন — তাহলেই ওষুধের সময় হলে নির্ভর জানাতে পারবে।',
                  'On the next screen, tap "Allow" so Nirbhor can tell you when it\'s time.',
                ),
                style: context.type.body.copyWith(color: colors.ink2),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(Dimens.radiusCard),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _ValueRow(
                      icon: Icons.schedule,
                      text: context.tr('ওষুধের সময় মনে করিয়ে দেবে', 'Reminds you at dose time'),
                    ),
                    _ValueRow(
                      icon: Icons.inventory_2,
                      text: context.tr(
                        'ওষুধ ফুরিয়ে এলে জানাবে',
                        'Warns when a medicine runs low',
                      ),
                    ),
                    _ValueRow(
                      icon: Icons.block,
                      text: context.tr('কোনো বিজ্ঞাপন বা খবর নয়', 'No ads, no news'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TintPanel(
                background: colors.warmSoft,
                child: Text(
                  context.tr(
                    'অনুমতি না দিলেও অ্যাপ চলবে, তবে চুপচাপ — কোনো শব্দ বা মনে করানো থাকবে না।',
                    'The app still works without permission, but silently — no sound or reminders.',
                  ),
                  style: context.type.body.copyWith(color: colors.warmD),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: context.tr('ঠিক আছে, জিজ্ঞেস করুন', 'OK, ask me'),
                height: 68,
                onPressed: () => _ask(context),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => _finish(context),
                child: Text(
                  context.tr('এখন নয়', 'Not now'),
                  style: context.type.buttonLabel.copyWith(color: colors.ink3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
