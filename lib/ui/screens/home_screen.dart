import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../i18n/dates.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/alarm_scheduler.dart';
import '../../notifications/nirbhor_notifications.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/labels.dart';
import '../components/overlays.dart';
import '../components/progress_ring.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';
import 'inbox_screen.dart';

/// Home — the time-blocked timeline (2j/2b), plus its empty (4d), day-complete (6f) and undo (4f)
/// states.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _today = DateTime.now();
  TimeOfDay _now = TimeOfDay.now();
  Timer? _tick;

  DoseWithMedicine? _lastTaken;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    // The first pulse waits for the first frame: reading the repository out of the scope is an
    // inherited-widget lookup, which initState is not allowed to make.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pulse());
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => _pulse());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _pulse() async {
    if (!mounted) return;
    final repo = context.repo;
    final currentDate = DateTime.now();
    await repo.ensureDosesFor(currentDate);
    await repo.markOverdueDoses();
    if (!mounted) return;
    setState(() {
      _today = currentDate;
      _now = TimeOfDay.now();
    });
  }

  void _showUndo(DoseWithMedicine dwm) {
    _undoTimer?.cancel();
    setState(() => _lastTaken = dwm);
    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _lastTaken = null);
    });
  }

  /// Confirming works at any hour. Someone who takes their morning pill at 7:40 must be able to
  /// record it; the old screen only offered a button once the block time had passed.
  Future<void> _confirm(DoseWithMedicine dwm) async {
    await context.repo.markTaken(dwm.dose.id);
    // The reminder notification is ongoing; nothing else clears it.
    await AlarmScheduler.clearForDose(dwm.dose.id);
    _showUndo(dwm);
  }

  Future<void> _undo(DoseWithMedicine dwm) async {
    _undoTimer?.cancel();
    if (mounted) setState(() => _lastTaken = null);
    await context.repo.undoTaken(dwm.dose.id);
    await _rearm();
  }

  Future<void> _snooze(DoseWithMedicine dwm) async {
    await context.repo.snoozeDose(dwm.dose.id);
    await AlarmScheduler.clearForDose(dwm.dose.id);
    await _rearm();
  }

  Future<void> _skip(DoseWithMedicine dwm) async {
    await context.repo.skipDose(dwm.dose.id);
    await AlarmScheduler.clearForDose(dwm.dose.id);
  }

  Future<void> _rearm() async {
    final repo = context.repo;
    final store = context.settingsStore;
    await AlarmScheduler.rescheduleAll(
      repo,
      settings: AppSettingsView.from(store, context.locale.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settingsStore = context.settingsStore;

    return ColoredBox(
      color: colors.paper,
      child: ListenableBuilder(
        listenable: settingsStore,
        builder: (context, _) => RepoBuilder<_HomeData>(
          query: (repo) async => _HomeData(
            blocks: await repo.timelineFor(_today),
            medicines: await repo.medicines(),
            stock: await repo.stockStatuses(),
            streak: await repo.currentStreak(),
          ),
          builder: (context, data) {
            final blocks = data.blocks;
            final stockById = {for (final s in data.stock) s.medicineId: s};
            final unread = hasUnreadInbox(
              data.medicines,
              data.stock,
              settingsStore.value.inboxReadSignature,
            );

            var total = 0;
            var taken = 0;
            var skipped = 0;
            for (final b in blocks) {
              total += b.doses.length;
              taken += b.doses.where((d) => d.dose.status.isTaken).length;
              skipped += b.doses.where((d) => d.dose.status == DoseStatus.skipped).length;
            }
            final allDone = total > 0 && taken + skipped == total;

            // The earliest dose still waiting — the one the screen should be about.
            DoseWithMedicine? nextDose;
            for (final b in blocks) {
              for (final d in b.doses) {
                if (d.dose.status != DoseStatus.upcoming) continue;
                if (nextDose == null ||
                    d.dose.scheduledEpochMillis < nextDose.dose.scheduledEpochMillis) {
                  nextDose = d;
                }
              }
            }
            final next = nextDose;

            return Stack(
              children: [
                Column(
                  children: [
                    _HomeHeader(
                      now: _now,
                      today: _today,
                      unread: unread,
                      onBell: context.nav.openInbox,
                      streak: data.streak,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          Dimens.screenPadding,
                          16,
                          Dimens.screenPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (data.medicines.isNotEmpty) ...[
                              const ReminderHealthBanner(),
                            ],
                            if (data.medicines.isEmpty)
                              const _EmptyHome()
                            else if (allDone)
                              _DayComplete(taken: taken, skipped: skipped, streak: data.streak)
                            else ...[
                              if (next != null)
                                _NextDoseCard(
                                  next: next,
                                  now: _now,
                                  taken: taken,
                                  total: total,
                                  onTaken: () => _confirm(next),
                                  onSnooze: () => _snooze(next),
                                )
                              else
                                _ProgressSummary(taken: taken, skipped: skipped, total: total),
                              for (final block in blocks) ...[
                                const SizedBox(height: Dimens.groupGap),
                                _TimeBlockSection(
                                  block: block,
                                  now: _now,
                                  stockById: stockById,
                                  onTaken: _confirm,
                                  onUndo: _undo,
                                  onSnooze: _snooze,
                                  onSkip: _skip,
                                  onOpenMedicine: (dwm) =>
                                      context.nav.openMedicine(dwm.medicine.id),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_lastTaken != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: UndoToast(
                      message: context.tr(
                        '${_lastTaken!.medicine.displayName} খাওয়া হয়েছে',
                        '${_lastTaken!.medicine.displayName} taken', hi: '${_lastTaken!.medicine.displayName} ली गई', es: '${_lastTaken!.medicine.displayName} tomada',
                      ),
                      actionLabel: context.tr('ফিরিয়ে নিন', 'Undo'),
                      onAction: () => _undo(_lastTaken!),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.blocks,
    required this.medicines,
    required this.stock,
    required this.streak,
  });

  final List<TimelineBlock> blocks;
  final List<Medicine> medicines;
  final List<StockStatus> stock;

  /// Consecutive fully-taken days ending today.
  final int streak;
}

/// A reminder that cannot ring is the one failure this app must never keep quiet about.
/// Notification access and exact-alarm access can both be refused at install time or revoked later,
/// and either one silently stops every dose alarm — so say so on the screen the patient actually
/// looks at, with the system page one tap away.
class ReminderHealthBanner extends StatefulWidget {
  const ReminderHealthBanner({super.key});

  @override
  State<ReminderHealthBanner> createState() => _ReminderHealthBannerState();
}

class _ReminderHealthBannerState extends State<ReminderHealthBanner>
    with WidgetsBindingObserver {
  bool _notificationsOff = false;
  bool _exactAlarmsOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Either permission can be changed from Settings while we are backgrounded.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final notificationsOn = await Permission.notification.isGranted;
    final exactOn = await NirbhorNotifications.canScheduleExact();
    if (!mounted) return;
    setState(() {
      _notificationsOff = !notificationsOn;
      _exactAlarmsOff = !exactOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_notificationsOff && !_exactAlarmsOff) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.groupGap),
      child: TintPanel(
        background: colors.warmSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 22, color: colors.warmD),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _notificationsOff
                            ? context.tr(
                                'মনে করিয়ে দেওয়া বন্ধ আছে', 'Reminders are switched off')
                            : context.tr(
                                'ঠিক সময়ে অ্যালার্ম বাজবে না', 'Alarms may not ring on time'),
                        style: context.type.cardTitleSecondary.copyWith(color: colors.warmD),
                      ),
                      Text(
                        _notificationsOff
                            ? context.tr(
                                'অনুমতি না দিলে ওষুধের সময় হলে কোনো শব্দ বা খবর আসবে না।',
                                'Without permission there is no sound and no notice when a dose is due.',
                              )
                            : context.tr(
                                '“ঠিক সময়ের অ্যালার্ম” অনুমতি দিলে ডোজের সময়েই বাজবে।',
                                'Allow exact alarms so reminders ring at the dose time.',
                              ),
                        style: context.type.meta.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: context.tr('ঠিক করুন', 'Fix this'),
              height: 52,
              container: colors.warmD,
              content: colors.paper,
              onPressed: () async {
                if (_notificationsOff) {
                  final granted = await NirbhorNotifications.requestPermission();
                  // A permanently-denied permission can only be turned back on from Settings.
                  if (!granted) await openAppSettings();
                } else {
                  await NirbhorNotifications.requestExactAlarmPermission();
                }
                await _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.now,
    required this.today,
    required this.unread,
    required this.onBell,
    required this.streak,
  });

  final TimeOfDay now;
  final DateTime today;
  final bool unread;
  final VoidCallback onBell;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final greeting = now.hour < 12
        ? context.tr('সুপ্রভাত', 'Good morning')
        : now.hour < 17
            ? context.tr('শুভ দুপুর', 'Good afternoon')
            : context.tr('শুভ সন্ধ্যা', 'Good evening');

    return ColoredBox(
      color: colors.card,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: context.type.header.copyWith(color: colors.ink)),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                dateStringFor(today, context.locale),
                                style: context.type.meta.copyWith(color: colors.ink3),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Shown from two days, not one: "1 day in a row" is not a run, and
                            // celebrating it cheapens the number once it is genuinely long.
                            if (streak >= 2) ...[
                              const SizedBox(width: 8),
                              StreakChip(days: streak),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: unread
                        ? context.tr('খবর — নতুন আছে', 'Notifications — new')
                        : context.tr('খবর', 'Notifications'),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onBell,
                      child: Container(
                        width: Dimens.tapMin,
                        height: Dimens.tapMin,
                        decoration: BoxDecoration(
                          color: colors.sage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.notifications, size: 21, color: colors.ink2),
                            if (unread)
                              Positioned(
                                top: 9,
                                right: 9,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.warm,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: colors.line),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.taken, required this.skipped, required this.total});

  final int taken;
  final int skipped;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolved = (taken + skipped).clamp(0, total);
    final remaining = (total - resolved).clamp(0, total);
    return TintPanel(
      background: colors.calmSoft,
      child: Row(
        children: [
          ProgressRing(fraction: total == 0 ? 0 : resolved / total),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    '${context.num(total)}টির মধ্যে ${context.num(taken)}টি ডোজ নেওয়া হয়েছে',
                    '$taken of $total doses taken', hi: '$total में से $taken खुराक ली गईं', es: '$taken de $total dosis tomadas',
                  ),
                  style: context.type.cardTitleSecondary.copyWith(color: colors.calmD),
                ),
                Text(
                  context.tr('আর ${context.num(remaining)}টি বাকি', '$remaining to go', hi: '$remaining बाकी', es: 'faltan $remaining'),
                  style: context.type.meta.copyWith(color: colors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BlockState { done, needsAttention, due, upcoming }

class _TimeBlockSection extends StatelessWidget {
  const _TimeBlockSection({
    required this.block,
    required this.now,
    required this.stockById,
    required this.onTaken,
    required this.onUndo,
    required this.onSnooze,
    required this.onSkip,
    required this.onOpenMedicine,
  });

  final TimelineBlock block;
  final TimeOfDay now;
  final Map<String, StockStatus> stockById;
  final ValueChanged<DoseWithMedicine> onTaken;
  final ValueChanged<DoseWithMedicine> onUndo;
  final ValueChanged<DoseWithMedicine> onSnooze;
  final ValueChanged<DoseWithMedicine> onSkip;
  final ValueChanged<DoseWithMedicine> onOpenMedicine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nowMinutes = now.hour * 60 + now.minute;
    final blockMinutes = block.hour * 60 + block.minute;
    final state = block.allResolved
        ? _BlockState.done
        : !block.doses.any((d) => d.dose.status == DoseStatus.upcoming)
            ? _BlockState.needsAttention
            : nowMinutes >= blockMinutes
                ? _BlockState.due
                : _BlockState.upcoming;

    final (icon, labelBn, labelEn) = switch (block.block) {
      TimeBlock.morning => (Icons.wb_sunny, 'সকাল', 'Morning'),
      TimeBlock.noon => (Icons.brightness_5, 'দুপুর', 'Afternoon'),
      TimeBlock.night => (Icons.dark_mode, 'রাত', 'Night'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 16, color: state == _BlockState.done ? colors.ink3 : colors.ink2),
            const SizedBox(width: 8),
            Text(
              context.tr(labelBn, labelEn),
              style: context.type.cardTitleSecondary.copyWith(
                color: state == _BlockState.done ? colors.ink3 : colors.ink,
              ),
            ),
            // The clock lives on each row now. In Bangla the clock string already opens with its
            // period word, so a heading of "সকাল  সকাল ৮:০০" said "morning" twice.
            const Spacer(),
            switch (state) {
              _BlockState.done => Row(
                  children: [
                    Icon(Icons.check, size: 16, color: colors.calm),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('শেষ', 'Done'),
                      style: context.type.statusPill.copyWith(color: colors.calm),
                    ),
                  ],
                ),
              _BlockState.due => StatusPill(
                  text: context.tr('এখন সময়', 'DUE NOW'),
                  // warm behind white measured 3.3:1, under the floor for an 11–12sp pill. The
                  // deeper amber keeps the urgency language and reads at 6.1:1.
                  background: colors.warmD,
                  contentColor: colors.paper,
                ),
              _BlockState.needsAttention => StatusPill(
                  text: context.tr('খেয়াল করুন', 'CHECK'),
                  background: colors.warmSoft,
                  contentColor: colors.warmD,
                ),
              _BlockState.upcoming => const SizedBox.shrink(),
            },
          ],
        ),
        for (final dwm in block.doses) ...[
          const SizedBox(height: Dimens.cardGap),
          Builder(builder: (context) {
            final ss = stockById[dwm.medicine.id];
            final low = ss != null && ss.isLow && dwm.dose.status == DoseStatus.upcoming;
            return DoseCard(
              dwm: dwm,
              due: state == _BlockState.due && dwm.dose.status == DoseStatus.upcoming,
              lowStock: low,
              lowCount: ss?.count ?? 0,
              onTaken: () => onTaken(dwm),
              onUndo: () => onUndo(dwm),
              onSnooze: () => onSnooze(dwm),
              onSkip: () => onSkip(dwm),
              onOpenMedicine: () => onOpenMedicine(dwm),
            );
          }),
        ],
      ],
    );
  }
}

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.dwm,
    required this.due,
    required this.lowStock,
    required this.lowCount,
    required this.onTaken,
    required this.onUndo,
    required this.onSnooze,
    required this.onSkip,
    required this.onOpenMedicine,
  });

  final DoseWithMedicine dwm;
  final bool due;
  final bool lowStock;
  final int lowCount;
  final VoidCallback onTaken;
  final VoidCallback onUndo;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onOpenMedicine;

  Future<void> _confirmSkip(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: context.tr('আজকের ডোজ বাদ দেবেন?', 'Skip this dose?'),
      message: context.tr(
        'এটি আজ বাদ দেওয়া হিসেবে হিসাব হবে। পরে রেকর্ড থেকে পরিবর্তন করা যাবে।',
        'This will be counted as skipped today. You can change it later from the record.',
      ),
      confirmLabel: context.tr('বাদ দিন', 'Skip dose'),
      cancelLabel: context.tr('ফিরে যান', 'Cancel'),
    );
    if (ok) onSkip();
  }

  Future<void> _missedActions(BuildContext context) async {
    final choice = await showMissedDoseDialog(context, medicineName: dwm.medicine.displayName);
    switch (choice) {
      case MissedDoseChoice.taken:
        onTaken();
      case MissedDoseChoice.skip:
        onSkip();
      case MissedDoseChoice.details:
        onOpenMedicine();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final med = dwm.medicine;
    final taken = dwm.dose.status.isTaken;
    final missed = dwm.dose.status == DoseStatus.missed;
    final skipped = dwm.dose.status == DoseStatus.skipped;

    if (due) {
      return GestureDetector(
        onTap: onOpenMedicine,
        child: UrgentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DoseIdentity(dwm: dwm, titleStyle: context.type.cardTitlePrimary),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: med.highRisk
                        ? HoldToConfirmButton(onConfirm: onTaken)
                        : PrimaryButton(
                            text: context.tr('খেয়েছি', 'Taken'),
                            onPressed: onTaken,
                            height: Dimens.doseConfirm,
                          ),
                  ),
                  const SizedBox(width: 8),
                  _SquareAction(
                    icon: Icons.schedule,
                    semanticLabel: context.tr('পরে মনে করান', 'Snooze'),
                    onTap: onSnooze,
                  ),
                  const SizedBox(width: 8),
                  _SquareAction(
                    icon: Icons.remove,
                    semanticLabel: context.tr('আজকের ডোজ বাদ দিন', 'Skip this dose'),
                    onTap: () => _confirmSkip(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // The row carries what a person needs to act: when, and how much. Two doses of the same
    // medicine used to render identically, told apart only by a heading centimetres away.
    final when = context.clock(dwm.dose.hour, dwm.dose.minute);
    final amount = '${context.qty(med.dosePerIntake)} ${med.form}'.trim();
    final sub = taken
        ? context.tr('$when-এ নেওয়া হয়েছে', 'Taken at $when', hi: '$when पर ली गई', es: 'Tomada a las $when')
        : missed
            ? context.tr('$when · বাদ পড়েছে', '$when · missed', hi: '$when · छूटी', es: '$when · saltada')
            : skipped
                ? context.tr('$when · আজ খাব না', '$when · skipped', hi: '$when · छोड़ी गई', es: '$when · omitida')
                : [when, amount].where((s) => s.trim().isNotEmpty).join(' · ');

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => missed ? _missedActions(context) : onOpenMedicine(),
        child: Opacity(
          opacity: taken || skipped ? 0.62 : 1,
          child: Padding(
            padding: const EdgeInsets.all(Dimens.cardPadding),
            child: Row(
              children: [
                if (missed) ...[
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.warm,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                _StatusTile(status: dwm.dose.status, med: med),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.displayName,
                        style: context.type.cardTitleSecondary.copyWith(
                          color: colors.ink,
                          decoration: taken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        sub,
                        style: context.type.meta
                            .copyWith(color: missed ? colors.warmD : colors.ink3),
                      ),
                      if (lowStock)
                        Text(
                          context.tr(
                            'ঘরে আর ${context.num(lowCount)}টি আছে',
                            '$lowCount left at home', hi: 'घर में $lowCount बची', es: 'quedan $lowCount en casa',
                          ),
                          style: context.type.meta.copyWith(color: colors.warmD),
                        ),
                    ],
                  ),
                ),
                _ConfirmCircle(
                  status: dwm.dose.status,
                  highRisk: med.highRisk,
                  medicineName: med.displayName,
                  onTaken: onTaken,
                  onUndo: onUndo,
                  onMissed: () => _missedActions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoseIdentity extends StatelessWidget {
  const _DoseIdentity({required this.dwm, required this.titleStyle});

  final DoseWithMedicine dwm;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        MedicineMark(
          shape: dwm.medicine.mark,
          color: Color(dwm.medicine.markColor),
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dwm.medicine.displayName, style: titleStyle.copyWith(color: colors.ink)),
              Text(
                [dwm.medicine.strength, dwm.medicine.form]
                    .where((s) => s.trim().isNotEmpty)
                    .join(' · '),
                style: context.type.meta.copyWith(color: colors.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status, required this.med});

  final DoseStatus status;
  final Medicine med;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final taken = status.isTaken;
    final background = taken
        ? colors.calm
        : status == DoseStatus.missed
            ? colors.warmSoft
            : status == DoseStatus.skipped
                ? colors.sage
                : colors.calmSoft;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: taken
          ? Icon(Icons.check, size: 23, color: colors.paper)
          : status == DoseStatus.missed
              ? Icon(Icons.warning_amber_rounded, size: 23, color: colors.warmD)
              : status == DoseStatus.skipped
                  ? Icon(Icons.remove, size: 23, color: colors.ink2)
                  : MedicineMark(shape: med.mark, color: Color(med.markColor), size: 27),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: Dimens.doseConfirm,
          height: Dimens.doseConfirm,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(Dimens.radiusButton),
            border: Border.all(color: colors.line, width: 1.5),
          ),
          child: Icon(icon, size: 22, color: colors.ink2),
        ),
      ),
    );
  }
}

class _DayComplete extends StatelessWidget {
  const _DayComplete({required this.taken, required this.skipped, required this.streak});

  final int taken;
  final int skipped;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.calm,
            borderRadius: BorderRadius.circular(Dimens.radiusLargeCard),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Springs in once, when the last dose of the day is confirmed. The only moment in
              // the app that is allowed to celebrate — everywhere else, motion stays out of the way.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 620),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: child),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.calmD,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.check, size: 38, color: colors.paper),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('আজকের সব ওষুধ শেষ', 'All done for today'),
                style: context.type.titleHero.copyWith(color: colors.paper),
                textAlign: TextAlign.center,
              ),
              Text(
                context.tr('${context.num(taken)}টি ডোজ নেওয়া হয়েছে', '$taken doses taken', hi: '$taken खुराक ली गईं', es: '$taken dosis tomadas'),
                style: context.type.body.copyWith(color: colors.paper.withValues(alpha: 0.9)),
              ),
              if (streak >= 2) ...[
                const SizedBox(height: 12),
                StreakChip(days: streak, onDark: true),
              ],
              if (skipped > 0)
                Text(
                  context.tr(
                    '${context.num(skipped)}টি ডোজ বাদ দেওয়া হয়েছে',
                    '$skipped doses skipped', hi: '$skipped खुराक छोड़ी गईं', es: '$skipped dosis omitidas',
                  ),
                  style: context.type.meta.copyWith(color: colors.paper.withValues(alpha: 0.8)),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.groupGap),
        TintPanel(
          background: colors.sage,
          child: Text(
            context.tr(
              'রাত ৯:৩০-এ পরিবারকে আজকের হিসাব পাঠানো হবে।',
              "Today's summary goes to your family at 9:30 PM.",
            ),
            style: context.type.body.copyWith(color: colors.ink2),
          ),
        ),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          context.tr(
            'এখানে আপনার আজকের ওষুধ দেখা যাবে',
            'Your medicines for today will appear here',
          ),
          style: context.type.titleHero.copyWith(color: colors.ink),
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('শুরু করতে একটি ওষুধ যোগ করুন।', 'Add a medicine to get started.'),
          style: context.type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          text: context.tr('পাতা স্ক্যান করে শুরু করুন', 'Scan a pack to start'),
          onPressed: context.nav.startScan,
          leftAligned: true,
        ),
        const SizedBox(height: 14),
        SecondaryButton(
          text: context.tr('নাম দিয়ে খুঁজুন', 'Search by name'),
          onPressed: context.nav.startSearch,
          leftAligned: true,
        ),
        const SizedBox(height: 14),
        TintPanel(
          background: colors.sage,
          child: Text(
            context.tr(
              'পরিবারের কেউ আপনার হয়ে ওষুধ যোগ করে দিতে পারেন।',
              'A family member can add your medicines for you.',
            ),
            style: context.type.body.copyWith(color: colors.ink2),
          ),
        ),
      ],
    );
  }
}

/// The next dose still waiting, and the one control that answers it.
///
/// This replaces the old progress panel, which restated a count the list below already showed while
/// the thing a patient actually needed — a way to record the dose — was unavailable until the block
/// time had passed. The count survives as a quiet line at the foot.
class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard({
    required this.next,
    required this.now,
    required this.taken,
    required this.total,
    required this.onTaken,
    required this.onSnooze,
  });

  final DoseWithMedicine next;
  final TimeOfDay now;
  final int taken;
  final int total;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;

  /// "৪৫ মিনিট পরে" / "১ ঘণ্টা ১৫ মিনিট পরে", or "এখন সময়" once the dose is due.
  String _lede(BuildContext context) {
    final minutes =
        (next.dose.hour * 60 + next.dose.minute) - (now.hour * 60 + now.minute);
    if (minutes <= 0) return context.tr('এখন সময়', 'Due now');
    final h = minutes ~/ 60, m = minutes % 60;
    final within = h == 0
        ? context.tr('${context.num(m)} মিনিট', '$m min', hi: '$m मिनट', es: '$m min')
        : m == 0
            ? context.tr('${context.num(h)} ঘণ্টা', '$h hr', hi: '$h घंटे', es: '$h h')
            : context.tr(
                '${context.num(h)} ঘণ্টা ${context.num(m)} মিনিট',
                '$h hr $m min', hi: '$h घंटे $m मिनट', es: '$h h $m min',
              );
    return context.tr('পরবর্তী ডোজ · $within পরে', 'Next dose · in $within', hi: 'अगली खुराक · $within में', es: 'Próxima dosis · en $within');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final med = next.medicine;
    final food = switch (med.foodRelation) {
      FoodRelation.before => context.tr('খাবারের আগে', 'before food'),
      FoodRelation.after => context.tr('খাবারের পরে', 'after food'),
      FoodRelation.none => '',
    };
    final amount =
        [ '${context.qty(med.dosePerIntake)} ${med.form}'.trim(), food]
            .where((s) => s.isNotEmpty)
            .join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: colors.calm,
        borderRadius: BorderRadius.circular(Dimens.radiusLargeCard),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _lede(context),
            style: context.type.meta.copyWith(color: colors.calmSoft),
          ),
          const SizedBox(height: 2),
          Text(
            context.clock(next.dose.hour, next.dose.minute),
            style: context.type.titleHero.copyWith(color: colors.paper),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // On this dark fill the stored mark colour loses contrast, so it lightens — the same
              // substitution the alarm screen makes.
              MedicineMark(shape: med.mark, color: colors.markCalmOnDark, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.displayName,
                      style: context.type.cardTitlePrimary.copyWith(color: colors.paper),
                    ),
                    if (amount.isNotEmpty)
                      Text(
                        amount,
                        style: context.type.meta.copyWith(color: colors.calmSoft),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (med.highRisk)
            HoldToConfirmButton(
              onConfirm: onTaken,
              height: Dimens.doseConfirm,
              container: colors.paper,
              content: colors.calm,
              progress: colors.markCalmOnDark,
            )
          else
            PrimaryButton(
              text: context.tr('এখনই খেয়েছি', "I've taken it"),
              onPressed: onTaken,
              height: Dimens.doseConfirm,
              container: colors.paper,
              content: colors.calm,
            ),
          TextButton(
            onPressed: onSnooze,
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Dimens.tapMin)),
            child: Text(
              context.tr('পরে মনে করাও', 'Remind me later'),
              style: context.type.cardTitleSecondary.copyWith(color: colors.calmSoft),
            ),
          ),
          Text(
            context.tr(
              '${context.num(total)}টির মধ্যে ${context.num(taken)}টি ডোজ নেওয়া হয়েছে',
              '$taken of $total doses taken', hi: '$total में से $taken खुराक ली गईं', es: '$taken de $total dosis tomadas',
            ),
            style: context.type.meta.copyWith(color: colors.calmSoft),
          ),
        ],
      ),
    );
  }
}

/// The per-row control that records a dose. Tapping the row still opens the medicine; this is the
/// one thing on the row that changes the record.
class _ConfirmCircle extends StatelessWidget {
  const _ConfirmCircle({
    required this.status,
    required this.highRisk,
    required this.medicineName,
    required this.onTaken,
    required this.onUndo,
    required this.onMissed,
  });

  final DoseStatus status;
  final bool highRisk;
  final String medicineName;
  final VoidCallback onTaken;
  final VoidCallback onUndo;
  final VoidCallback onMissed;

  /// A high-risk medicine keeps its press-and-hold gate — it just moves into a sheet, because a
  /// 44px circle is too small to hold accurately.
  Future<void> _confirmHighRisk(BuildContext context) async {
    final colors = context.colors;
    await showNbSheet<void>(context, (sheetContext) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            medicineName,
            style: sheetContext.type.cardTitlePrimary.copyWith(color: colors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            sheetContext.tr(
              'এই ওষুধটি নিশ্চিত করতে বোতামটি চেপে ধরে রাখুন।',
              'Press and hold to confirm this medicine.',
            ),
            style: sheetContext.type.body.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: 16),
          HoldToConfirmButton(
            height: Dimens.flowButton,
            onConfirm: () {
              Navigator.of(sheetContext).pop();
              onTaken();
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final taken = status.isTaken;

    final (bg, border, icon, iconColor, label) = switch (status) {
      DoseStatus.taken || DoseStatus.takenLate => (
          colors.calm,
          colors.calm,
          Icons.check,
          colors.paper,
          context.tr('ফিরিয়ে নিন', 'Undo'),
        ),
      DoseStatus.missed => (
          Colors.transparent,
          colors.warm,
          Icons.priority_high,
          colors.warmD,
          context.tr('কী হয়েছিল জানান', 'Say what happened'),
        ),
      DoseStatus.skipped => (
          colors.sage,
          colors.sage,
          Icons.remove,
          colors.ink2,
          context.tr('কী হয়েছিল জানান', 'Say what happened'),
        ),
      DoseStatus.upcoming => (
          Colors.transparent,
          colors.calm,
          Icons.check,
          colors.calm,
          context.tr('খেয়েছি', 'Mark as taken'),
        ),
    };

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (taken) {
            onUndo();
          } else if (status == DoseStatus.missed || status == DoseStatus.skipped) {
            onMissed();
          } else if (highRisk) {
            _confirmHighRisk(context);
          } else {
            onTaken();
          }
        },
        child: Padding(
          // Keeps the visible circle at 34px while the tap target stays at the 48px minimum.
          padding: const EdgeInsets.all(7),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
