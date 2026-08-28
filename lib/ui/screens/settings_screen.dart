import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/app_scope.dart';
import '../../domain/app_settings.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/nirbhor_notifications.dart';
import '../../theme/theme.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Settings (2l/2i) — language, reminders, and reading aids.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _exactEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Both switches live in system Settings, so re-read them every time we come back.
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final notifications = await Permission.notification.isGranted;
    final exact = await NirbhorNotifications.canScheduleExact();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications;
      _exactEnabled = exact;
    });
  }

  /// What "follow the phone" actually resolves to right now, rather than a hard-coded guess.
  String get _phoneLanguage {
    final device = ui.PlatformDispatcher.instance.locale;
    return switch (device.languageCode) {
      'bn' => context.tr('বাংলা', 'Bangla'),
      'en' => context.tr('ইংরেজি', 'English'),
      _ => device.toLanguageTag(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final store = context.settingsStore;

    return Scaffold(
      backgroundColor: colors.paper,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final settings = store.value;
          return Column(
            children: [
              NirbhorTopBar(
                title: context.tr('সেটিংস', 'Settings'),
                onBack: context.nav.back,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ভাষা · Language
                        SectionLabel(context.tr('ভাষা', 'Language')),
                        const SizedBox(height: 8),
                        NbCard(
                          child: Column(
                            children: [
                              _RadioRow(
                                title: context.tr(
                                  'ফোনের ভাষা অনুসরণ করুন',
                                  'Follow phone language',
                                ),
                                subtitle: context.tr(
                                  'এখন $_phoneLanguage',
                                  'Now $_phoneLanguage',
                                ),
                                selected: settings.localePref == LocalePref.system,
                                onTap: () => store.setLocale(LocalePref.system),
                              ),
                              const _Divider(),
                              _RadioRow(
                                title: 'বাংলা',
                                // Archivo has no Bengali; this label must name Anek explicitly.
                                bangla: true,
                                selected: settings.localePref == LocalePref.bn,
                                onTap: () => store.setLocale(LocalePref.bn),
                              ),
                              const _Divider(),
                              _RadioRow(
                                title: 'English',
                                latin: true,
                                selected: settings.localePref == LocalePref.en,
                                onTap: () => store.setLocale(LocalePref.en),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // মনে করিয়ে দেওয়া · Reminders
                        SectionLabel(context.tr('মনে করিয়ে দেওয়া', 'Reminders')),
                        const SizedBox(height: 8),
                        NbCard(
                          child: Column(
                            children: [
                              _DrillRow(
                                title: context.tr('নোটিফিকেশন অনুমতি', 'Notification access'),
                                value: _notificationsEnabled
                                    ? context.tr('চালু', 'On')
                                    : context.tr('বন্ধ — ঠিক করুন', 'Off — fix'),
                                onTap: () async {
                                  final granted =
                                      await NirbhorNotifications.requestPermission();
                                  if (!granted) await openAppSettings();
                                  await _refreshPermissions();
                                },
                              ),
                              const _Divider(),
                              _DrillRow(
                                title: context.tr('ঠিক সময়ের অ্যালার্ম', 'Exact alarm access'),
                                value: _exactEnabled
                                    ? context.tr('চালু', 'On')
                                    : context.tr('বন্ধ — ঠিক করুন', 'Off — fix'),
                                onTap: () async {
                                  await NirbhorNotifications.requestExactAlarmPermission();
                                  await _refreshPermissions();
                                },
                              ),
                              const _Divider(),
                              _ToggleRow(
                                title: context.tr('পূর্ণ-স্ক্রিন অ্যালার্ম', 'Full-screen alarm'),
                                subtitle: context.tr(
                                  'লক স্ক্রিনেও দেখা যাবে',
                                  'Shows over the lock screen',
                                ),
                                checked: settings.fullScreenAlarm,
                                onChanged: store.setFullScreenAlarm,
                              ),
                              const _Divider(),
                              _DrillRow(
                                title: context.tr('অ্যালার্মের শব্দ', 'Alarm sound'),
                                value: context.tr('সিস্টেম সেটিংস', 'System settings'),
                                // The reminder channel's sound is owned by Android; the app only
                                // points at the page where it can be changed.
                                onTap: openAppSettings,
                              ),
                              const _Divider(),
                              _DrillRow(
                                title: context.tr(
                                  'অ্যালার্ম কেমন দেখাবে',
                                  'See what the alarm looks like',
                                ),
                                value: context.tr('দেখে নিন', 'Preview'),
                                onTap: context.nav.openAlarmPreview,
                              ),
                              const _Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      context.tr('সাড়া না দিলে আবার', 'Repeat if ignored'),
                                      style: context.type.cardTitleSecondary
                                          .copyWith(color: colors.ink),
                                    ),
                                    Text(
                                      settings.repeatMax == 0
                                          ? context.tr(
                                              'একবারই মনে করানো হবে',
                                              'Remind once, no repeats',
                                            )
                                          : context.tr(
                                              'প্রতি ${context.num(settings.repeatEveryMinutes)} মিনিটে, ${context.num(settings.repeatMax)} বার পর্যন্ত',
                                              'Every ${settings.repeatEveryMinutes} min, up to ${settings.repeatMax} times',
                                            ),
                                      style:
                                          context.type.meta.copyWith(color: colors.ink3),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        for (final preset in <(int, int, String)>[
                                          (5, 3, context.tr('৫ মিনিট', '5 min')),
                                          (10, 3, context.tr('১০ মিনিট', '10 min')),
                                          (15, 2, context.tr('১৫ মিনিট', '15 min')),
                                          (10, 0, context.tr('বন্ধ', 'Off')),
                                        ]) ...[
                                          if (preset.$3 !=
                                              context.tr('৫ মিনিট', '5 min'))
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: QuickChip(
                                              label: preset.$3,
                                              height: 48,
                                              selected: settings.repeatMax == preset.$2 &&
                                                  (preset.$2 == 0 ||
                                                      settings.repeatEveryMinutes ==
                                                          preset.$1),
                                              onTap: () => store.setRepeat(
                                                everyMinutes: preset.$1,
                                                maxRepeats: preset.$2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const _Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.tr('সময়ের ধরন', 'Time format'),
                                        style: context.type.cardTitleSecondary
                                            .copyWith(color: colors.ink),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: SegmentedControl(
                                        options: [
                                          context.tr('১২ ঘণ্টা', '12h'),
                                          context.tr('২৪ ঘণ্টা', '24h'),
                                        ],
                                        selectedIndex: context.is24Hour ? 1 : 0,
                                        onSelect: (i) => store.setTimeFormat(
                                          i == 1 ? TimeFormat.h24 : TimeFormat.h12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // সহজে পড়ার জন্য · Reading
                        SectionLabel(context.tr('সহজে পড়ার জন্য', 'For easy reading')),
                        const SizedBox(height: 8),
                        NbCard(
                          child: Column(
                            children: [
                              _ToggleRow(
                                title: context.tr('বড় লেখা', 'Bigger text'),
                                subtitle: context.tr(
                                  'সব স্ক্রিনে লেখা বড় হবে',
                                  'Larger text everywhere',
                                ),
                                checked: settings.biggerText,
                                onChanged: store.setBiggerText,
                              ),
                              const _Divider(),
                              _ToggleRow(
                                title: context.tr('পড়ে শোনানো', 'Read aloud'),
                                subtitle: context.tr(
                                  'অ্যালার্মে ওষুধের নাম বলা হবে',
                                  'Speaks the medicine name at alarm time',
                                ),
                                checked: settings.readAloud,
                                onChanged: store.setReadAloud,
                              ),
                            ],
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

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.bangla = false,
    this.latin = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool bangla;
  final bool latin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.type.cardTitleSecondary;
    final style = bangla
        ? context.type.asBangla(base)
        : latin
            ? context.type.asLatin(base)
            : base;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: style.copyWith(color: colors.ink)),
                    if (subtitle != null)
                      Text(subtitle!, style: context.type.meta.copyWith(color: colors.ink3)),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(width: 12),
          NbSwitch(checked: checked, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DrillRow extends StatelessWidget {
  const _DrillRow({required this.title, required this.value, required this.onTap});

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Dimens.tapMin),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                ),
              ),
              Text(value, style: context.type.meta.copyWith(color: colors.ink3)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_right, size: 20, color: colors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(height: 1, color: context.colors.line);
}
