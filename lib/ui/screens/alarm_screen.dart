import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/alarm_audio.dart';
import '../../notifications/alarm_scheduler.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../marks/medicine_mark.dart';

/// The real alarm (2k/2c) — what the patient sees when a reminder fires.
///
/// The Kotlin build put this in its own `showWhenLocked` activity; here it is a route reached
/// through the reminder's full-screen intent, and the manifest carries the same
/// `showWhenLocked`/`turnScreenOn` flags on the single Flutter activity.
///
/// Unlike [AlarmPreviewScreen], every button here writes: it confirms, snoozes or skips the dose,
/// and clears the ongoing reminder it came from.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key, required this.doseId});

  final int? doseId;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterTts _tts = FlutterTts();
  List<DoseWithMedicine> _doses = const [];
  bool _spoken = false;

  @override
  void initState() {
    super.initState();
    AlarmAudio.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    AlarmAudio.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.doseId;
    if (id == null) return;
    final dwm = await context.repo.doseWithMedicine(id);
    if (!mounted || dwm == null) return;
    setState(() => _doses = [dwm]);
    // The reminder is deliberately left on the shade. It is posted ongoing precisely so an
    // unanswered dose stays visible: backing out of this screen must not look like answering it.
    // Taken / Snooze / Skip are what clear it.
    await _speak();
  }

  Future<void> _speak() async {
    if (_spoken || !mounted) return;
    if (!context.settingsStore.value.readAloud || _doses.isEmpty) return;
    _spoken = true;
    try {
      await _tts.setLanguage(context.isBangla ? 'bn-BD' : 'en-US');
      await _tts.speak(_doses.map((d) => d.medicine.displayName).join(', '));
    } catch (_) {
      // A device without a Bangla voice must not take the alarm down with it.
    }
  }

  Future<void> _rearm() => AlarmScheduler.rescheduleAll(
        context.repo,
        settings: AppSettingsView.from(context.settingsStore, context.isBangla),
      );

  Future<void> _resolve(Future<void> Function(DoseWithMedicine dwm) action,
      {bool rearm = false}) async {
    final nav = context.nav;
    for (final dwm in _doses) {
      await action(dwm);
      await AlarmScheduler.clearForDose(dwm.dose.id);
    }
    if (rearm && mounted) await _rearm();
    await AlarmAudio.stop();
    await _tts.stop();
    nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final dose = _doses.isEmpty ? null : _doses.first.dose;
    return AlarmSurface(
      hour: dose?.hour ?? TimeOfDay.now().hour,
      minute: dose?.minute ?? TimeOfDay.now().minute,
      doses: _doses,
      subtitle: null,
      note: null,
      emptyMessage: context.tr(
        'এই ডোজটি আর বাকি নেই।',
        'This dose is no longer waiting.',
      ),
      enabled: _doses.isNotEmpty,
      onTaken: () => _resolve(
        (dwm) => context.repo.markTaken(dwm.dose.id, source: DoseSource.alarm),
      ),
      onSnooze: () => _resolve(
        (dwm) => context.repo.snoozeDose(dwm.dose.id),
        rearm: true,
      ),
      onSkip: () => _resolve(
        (dwm) => context.repo.skipDose(dwm.dose.id, source: DoseSource.alarm),
      ),
    );
  }
}

/// The dark alarm surface shared by the real alarm and its in-app preview.
class AlarmSurface extends StatelessWidget {
  const AlarmSurface({
    super.key,
    required this.hour,
    required this.minute,
    required this.doses,
    required this.onTaken,
    required this.onSnooze,
    required this.onSkip,
    this.subtitle,
    this.note,
    this.emptyMessage,
    this.enabled = true,
  });

  final int hour;
  final int minute;
  final List<DoseWithMedicine> doses;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final String? subtitle;
  final String? note;
  final String? emptyMessage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highRisk = doses.any((d) => d.medicine.highRisk);

    return Scaffold(
      backgroundColor: colors.calmD,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 18,
                    color: colors.alarmText.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('নির্ভর · মনে করিয়ে দিচ্ছে', 'Nirbhor · reminding you'),
                    style: context.type.meta
                        .copyWith(color: colors.alarmText.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.clock(hour, minute),
                style: context.type.alarmTime.copyWith(color: colors.alarmText),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: context.type.body
                      .copyWith(color: colors.alarmText.withValues(alpha: 0.85)),
                  textAlign: TextAlign.center,
                ),
              ],
              if (note != null) ...[
                const SizedBox(height: 10),
                Text(
                  note!,
                  style: context.type.meta
                      .copyWith(color: colors.alarmText.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (doses.isEmpty && emptyMessage != null)
                        Text(
                          emptyMessage!,
                          style: context.type.body
                              .copyWith(color: colors.alarmText.withValues(alpha: 0.85)),
                        ),
                      for (final dwm in doses) AlarmMedCard(dwm: dwm),
                    ],
                  ),
                ),
              ),
              if (highRisk)
                HoldToConfirmButton(
                  onConfirm: onTaken,
                  height: Dimens.alarmConfirm,
                  container: colors.alarmText,
                  content: colors.calmD,
                  progress: colors.markCalmOnDark,
                )
              else
                PrimaryButton(
                  text: context.tr('খেয়ে নিয়েছি', "I've taken it"),
                  onPressed: onTaken,
                  height: Dimens.alarmConfirm,
                  enabled: enabled,
                  container: colors.alarmText,
                  content: colors.calmD,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: context.tr('পরে মনে করাও', 'Snooze'),
                      onPressed: onSnooze,
                      height: 62,
                      enabled: enabled,
                      container: const Color(0x22FFFFFF),
                      content: colors.alarmText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 118,
                    child: SecondaryButton(
                      text: context.tr('আজ বাদ', 'Skip'),
                      onPressed: onSkip,
                      height: 62,
                      enabled: enabled,
                      // Filled with a translucent white rather than the card surface: a white
                      // button on this dark green left its pale label at 1.1:1 — invisible on the
                      // one screen that must be answerable half-asleep. This reads at 5.6:1.
                      container: const Color(0x24FFFFFF),
                      borderColor: colors.alarmText.withValues(alpha: 0.45),
                      content: colors.alarmText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class AlarmMedCard extends StatelessWidget {
  const AlarmMedCard({super.key, required this.dwm});

  final DoseWithMedicine dwm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // On the dark surface the stored mark colours lose contrast, so marks lighten to their
    // on-dark variants.
    final markColor = dwm.medicine.mark == MarkShape.roundedSquare
        ? colors.markSlateOnDark
        : colors.markCalmOnDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            MedicineMark(shape: dwm.medicine.mark, color: markColor, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dwm.medicine.displayName,
                    style: context.type.alarmName.copyWith(color: colors.alarmText),
                  ),
                  Text(
                    [dwm.medicine.strength, dwm.medicine.form]
                        .where((s) => s.trim().isNotEmpty)
                        .join(' · '),
                    style: context.type.meta
                        .copyWith(color: colors.alarmText.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
