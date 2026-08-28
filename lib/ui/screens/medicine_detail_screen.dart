import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../data/repository.dart';
import '../../domain/dose_scheduler.dart';
import '../../domain/models.dart';
import '../../i18n/numerals.dart';
import '../../navigation/nav_actions.dart';
import '../../notifications/alarm_scheduler.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/overlays.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';

/// Medicine detail (5e) — identity, its times, its stock, the high-risk gate, pause and remove.
class MedicineDetailScreen extends StatefulWidget {
  const MedicineDetailScreen({super.key, required this.medicineId});

  final String medicineId;

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  bool _editingStock = false;
  double _stockDraft = 0;

  Future<void> _rearm() => AlarmScheduler.rescheduleAll(
        context.repo,
        settings: AppSettingsView.from(context.settingsStore, context.isBangla),
      );

  Future<void> _save(Medicine updated) async {
    await context.repo.upsertMedicine(updated);
    await _rearm();
  }

  Future<void> _remove(Medicine med) async {
    final ok = await confirmAction(
      context,
      title: context.tr('ওষুধটি সরিয়ে দেবেন?', 'Remove this medicine?'),
      message: context.tr(
        '${med.displayName}-এর ভবিষ্যৎ অ্যালার্ম ও ডোজের ইতিহাস স্থায়ীভাবে মুছে যাবে।',
        'Future alarms and dose history for ${med.displayName} will be permanently deleted.',
      ),
      confirmLabel: context.tr('সরিয়ে দিন', 'Remove'),
      cancelLabel: context.tr('রেখে দিন', 'Keep it'),
    );
    if (!ok || !mounted) return;
    // Cancel each removed dose's alarm and any reminder still on the shade before re-arming —
    // rescheduleAll only covers doses that still exist.
    final removed = await context.repo.deleteMedicine(med.id);
    await AlarmScheduler.clearForDoses(removed);
    if (!mounted) return;
    await _rearm();
    if (mounted) context.nav.back();
  }

  Future<void> _removeTime(Medicine med, int index) async {
    final ok = await confirmAction(
      context,
      title: context.tr('এই সময়টি সরাবেন?', 'Remove this time?'),
      message: context.tr(
        'এই সময়ের ভবিষ্যৎ অ্যালার্ম আর আসবে না।',
        'Future alarms for this time will be removed.',
      ),
      confirmLabel: context.tr('সরিয়ে দিন', 'Remove'),
      cancelLabel: context.tr('বাতিল', 'Cancel'),
    );
    if (!ok || !mounted) return;
    final tokens = List.of(med.timeTokens)..removeAt(index);
    final times = List.of(med.resolvedTimes);
    if (index < times.length) times.removeAt(index);
    await _save(med.copyWith(timeTokens: tokens, resolvedTimes: times));
  }

  Future<void> _addTime(Medicine med) async {
    TimeBlock? next;
    for (final b in TimeBlock.values) {
      if (!med.timeTokens.contains(b.token)) {
        next = b;
        break;
      }
    }
    if (next == null) return;
    final byToken = <String, String>{
      for (var i = 0; i < med.timeTokens.length; i++)
        med.timeTokens[i]: i < med.resolvedTimes.length
            ? med.resolvedTimes[i]
            : DoseScheduler.blockDefaultTime(TimeBlock.fromToken(med.timeTokens[i])),
      next.token: DoseScheduler.blockDefaultTime(next),
    };
    // Times are always stored in block order, so the timeline never reads them out of sequence.
    final ordered = TimeBlock.values.where((b) => byToken.containsKey(b.token)).toList();
    await _save(med.copyWith(
      timeTokens: ordered.map((b) => b.token).toList(),
      resolvedTimes: ordered.map((b) => byToken[b.token]!).toList(),
    ));
  }

  Future<void> _edit(Medicine med) async {
    final updated = await showDialog<Medicine>(
      context: context,
      barrierColor: const Color(0x6B1B2A26),
      builder: (context) => _EditMedicineDialog(medicine: med),
    );
    if (updated != null && mounted) await _save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: RepoBuilder<(Medicine?, MedAdherence?)>(
        query: (repo) async {
          final med = await repo.medicine(widget.medicineId);
          final all = await repo.perMedicineAdherence(30);
          MedAdherence? adherence;
          for (final a in all) {
            if (a.medicine.id == widget.medicineId) adherence = a;
          }
          return (med, adherence);
        },
        loading: Column(
          children: [
            NirbhorTopBar(title: context.tr('ওষুধ', 'Medicine'), onBack: context.nav.back),
          ],
        ),
        builder: (context, data) {
          final (med, adherence) = data;
          if (med == null) {
            return Column(
              children: [
                NirbhorTopBar(
                  title: context.tr('ওষুধ', 'Medicine'),
                  onBack: context.nav.back,
                ),
              ],
            );
          }

          final identity = [med.strength, med.form, med.condition]
              .where((s) => s.trim().isNotEmpty)
              .join(' · ');
          final hasFreeBlock =
              TimeBlock.values.any((b) => !med.timeTokens.contains(b.token));

          return Column(
            children: [
              NirbhorTopBar(title: med.displayName, onBack: context.nav.back),
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
                        NbCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  MedicineMark(
                                    shape: med.mark,
                                    color: Color(med.markColor),
                                    size: 46,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.displayName,
                                          style: context.type.cardTitlePrimary
                                              .copyWith(color: colors.ink),
                                        ),
                                        if (identity.isNotEmpty)
                                          Text(
                                            identity,
                                            style: context.type.meta
                                                .copyWith(color: colors.ink3),
                                          ),
                                        Text(
                                          context.tr(
                                            'প্রতিবার ${context.qty(med.dosePerIntake)} ${med.form}',
                                            '${context.qty(med.dosePerIntake)} ${med.form} each time',
                                          ),
                                          style: context.type.meta
                                              .copyWith(color: colors.calmD),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SecondaryButton(
                                text: context.tr('ওষুধ সম্পাদনা করুন', 'Edit medicine'),
                                onPressed: () => _edit(med),
                                height: 52,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        // Times
                        SectionLabel(context.tr('সময়', 'Times')),
                        const SizedBox(height: 8),
                        NbCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < med.timeTokens.length; i++)
                                _TimeRow(
                                  med: med,
                                  index: i,
                                  hhmm: i < med.resolvedTimes.length
                                      ? med.resolvedTimes[i]
                                      : '08:00',
                                  onChanged: (newTime) {
                                    final updated = List.of(med.resolvedTimes);
                                    while (updated.length <= i) {
                                      updated.add('08:00');
                                    }
                                    updated[i] = newTime;
                                    _save(med.copyWith(resolvedTimes: updated));
                                  },
                                  onRemove: med.timeTokens.length > 1
                                      ? () => _removeTime(med, i)
                                      : null,
                                ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: hasFreeBlock ? () => _addTime(med) : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, size: 20, color: colors.calm),
                                      const SizedBox(width: 10),
                                      Text(
                                        hasFreeBlock
                                            ? context.tr(
                                                'আরও একটি সময় যোগ করুন',
                                                'Add another time',
                                              )
                                            : context.tr(
                                                'সব সময় যোগ করা হয়েছে',
                                                'All times added',
                                              ),
                                        style: context.type.cardTitleSecondary.copyWith(
                                          color: hasFreeBlock ? colors.calm : colors.ink3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        // Stock
                        SectionLabel(context.tr('ঘরে আছে', 'In stock')),
                        const SizedBox(height: 8),
                        NbCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.tr(
                                        '${context.num(med.stockCount)}টি ${med.form}',
                                        '${med.stockCount} ${med.form}',
                                      ),
                                      style: context.type.cardTitleSecondary
                                          .copyWith(color: colors.ink),
                                    ),
                                  ),
                                  SecondaryButton(
                                    text: context.tr('সংখ্যা ঠিক করুন', 'Fix count'),
                                    height: 44,
                                    onPressed: () => setState(() {
                                      _stockDraft = med.stockCount.toDouble();
                                      _editingStock = true;
                                    }),
                                  ),
                                ],
                              ),
                              if (_editingStock) ...[
                                const SizedBox(height: 14),
                                QuantityStepper(
                                  value: _stockDraft,
                                  onChanged: (v) =>
                                      setState(() => _stockDraft = v.clamp(0, 10000)),
                                  valueLabel: context.num(_stockDraft.toInt()),
                                  unitLabel: context.tr('টি', 'in stock'),
                                  size: 52,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PrimaryButton(
                                        text: context.tr('সেভ করুন', 'Save'),
                                        height: 48,
                                        onPressed: () async {
                                          await context.repo
                                              .setStock(med.id, _stockDraft.toInt());
                                          if (mounted) {
                                            setState(() => _editingStock = false);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SecondaryButton(
                                        text: context.tr('বাদ দিন', 'Cancel'),
                                        height: 48,
                                        onPressed: () =>
                                            setState(() => _editingStock = false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 8,
                                  child: ColoredBox(
                                    color: colors.sage,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          (med.stockCount / 60).clamp(0.0, 1.0),
                                      child: ColoredBox(color: colors.calm),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        // High-risk gate + adherence
                        NbCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr(
                                            'চেপে ধরে নিশ্চিত করা',
                                            'Press-and-hold to confirm',
                                          ),
                                          style: context.type.cardTitleSecondary
                                              .copyWith(color: colors.ink),
                                        ),
                                        Text(
                                          context.tr(
                                            'ভুলবশত চাপ এড়াতে',
                                            'Avoids accidental taps',
                                          ),
                                          style: context.type.meta
                                              .copyWith(color: colors.ink3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  NbSwitch(
                                    checked: med.highRisk,
                                    onChanged: (v) => context.repo
                                        .upsertMedicine(med.copyWith(highRisk: v)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr(
                                  'গত ৩০ দিনে ${context.percent(adherence?.percent ?? 0)} সময়মতো নেওয়া হয়েছে',
                                  '${context.percent(adherence?.percent ?? 0)} on time over 30 days',
                                ),
                                style: context.type.meta.copyWith(color: colors.ink2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        // Footer: pause + remove (no red).
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: med.paused
                                    ? context.tr('আবার চালু করুন', 'Resume')
                                    : context.tr('সাময়িক বন্ধ', 'Pause'),
                                height: 56,
                                onPressed: () => _save(med.copyWith(paused: !med.paused)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SecondaryButton(
                                text: context.tr('তালিকা থেকে সরান', 'Remove'),
                                height: 56,
                                borderColor: colors.warm,
                                content: colors.warmD,
                                onPressed: () => _remove(med),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimens.groupGap),
                        TintPanel(
                          background: colors.sage,
                          child: Text(
                            context.tr(
                              'নির্ভর কোনো পরামর্শ দেয় না। ওষুধ নিয়ে প্রশ্ন থাকলে ডাক্তারের সঙ্গে কথা বলুন।',
                              'Nirbhor gives no medical advice. Ask your doctor about any medicine question.',
                            ),
                            style: context.type.meta.copyWith(color: colors.ink2),
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

class _TimeRow extends StatefulWidget {
  const _TimeRow({
    required this.med,
    required this.index,
    required this.hhmm,
    required this.onChanged,
    required this.onRemove,
  });

  final Medicine med;
  final int index;
  final String hhmm;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_TimeRow> createState() => _TimeRowState();
}

class _TimeRowState extends State<_TimeRow> {
  late String _displayed = widget.hhmm;

  @override
  void didUpdateWidget(_TimeRow old) {
    super.didUpdateWidget(old);
    if (old.hhmm != widget.hhmm) _displayed = widget.hhmm;
  }

  /// Nudging past midnight wraps rather than clamping, so a 00:05 dose can be pulled back to 23:50.
  String _shift(int h, int m, int delta) {
    final total = (h * 60 + m + delta + 24 * 60) % (24 * 60);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parsed = DoseScheduler.parseHhmm(_displayed) ?? (8, 0);
    final (h, m) = parsed;
    final block = TimeBlock.fromToken(
      widget.index < widget.med.timeTokens.length
          ? widget.med.timeTokens[widget.index]
          : 'morning',
    );
    final label = switch (block) {
      TimeBlock.morning => context.tr('সকাল', 'Morning'),
      TimeBlock.noon => context.tr('দুপুর', 'Afternoon'),
      TimeBlock.night => context.tr('রাত', 'Night'),
    };

    void nudge(int delta) {
      final next = _shift(h, m, delta);
      setState(() => _displayed = next);
      widget.onChanged(next);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                ),
              ),
              Text(
                context.clock(h, m),
                style: context.type.cardTitlePrimary.copyWith(color: colors.calmD),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: context.tr('সময় সরান', 'Remove time'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onRemove,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.warmSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.remove, size: 18, color: colors.warmD),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _NudgeButton(
                label: '−${context.num(15)}',
                semanticLabel: context.tr('১৫ মিনিট আগে', '15 minutes earlier'),
                onTap: () => nudge(-15),
              ),
              const SizedBox(width: 8),
              _NudgeButton(
                label: '+${context.num(15)}',
                semanticLabel: context.tr('১৫ মিনিট পরে', '15 minutes later'),
                onTap: () => nudge(15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
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
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sage,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: context.type.cardTitleSecondary.copyWith(color: colors.ink2),
          ),
        ),
      ),
    );
  }
}

class _EditMedicineDialog extends StatefulWidget {
  const _EditMedicineDialog({required this.medicine});

  final Medicine medicine;

  @override
  State<_EditMedicineDialog> createState() => _EditMedicineDialogState();
}

class _EditMedicineDialogState extends State<_EditMedicineDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.medicine.displayName);
  late final TextEditingController _strength =
      TextEditingController(text: widget.medicine.strength);
  late final TextEditingController _form =
      TextEditingController(text: widget.medicine.form);
  late final TextEditingController _condition =
      TextEditingController(text: widget.medicine.condition);
  late double _dose = widget.medicine.dosePerIntake.clamp(0.5, 10);

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _form.dispose();
    _condition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canSave = _name.text.trim().isNotEmpty && _form.text.trim().isNotEmpty;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('ওষুধ সম্পাদনা করুন', 'Edit medicine'),
                  style: context.type.header.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'নাম, শক্তি, ধরন ও প্রতিবারের পরিমাণ বদলান।',
                    'Update the name, strength, form, and amount taken each time.',
                  ),
                  style: context.type.body.copyWith(color: colors.ink2),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _name,
                  label: context.tr('ওষুধের নাম', 'Medicine name'),
                  maxLength: 80,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _strength,
                  label: context.tr('শক্তি', 'Strength'),
                  maxLength: 40,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _form,
                  label: context.tr('ধরন', 'Form'),
                  maxLength: 40,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _condition,
                  label: context.tr('কেন খান (ঐচ্ছিক)', 'Used for (optional)'),
                  maxLength: 60,
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('প্রতিবার কতটা', 'How much each time'),
                  style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 8),
                QuantityStepper(
                  value: _dose,
                  onChanged: (v) => setState(() => _dose = v.clamp(0.5, 10)),
                  valueLabel: Numerals.quantity(_dose, context.isBangla),
                  unitLabel: _form.text.trim().isEmpty
                      ? context.tr('ট্যাবলেট', 'tablet')
                      : _form.text.trim(),
                  size: 56,
                  step: 0.5,
                  min: 0.5,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: context.tr('পরিবর্তন সেভ করুন', 'Save changes'),
                  height: 56,
                  enabled: canSave,
                  onPressed: () => Navigator.of(context).pop(
                    widget.medicine.copyWith(
                      displayName: _name.text.trim(),
                      strength: _strength.text.trim(),
                      form: _form.text.trim(),
                      condition: _condition.text.trim(),
                      dosePerIntake: _dose,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  text: context.tr('বাতিল', 'Cancel'),
                  height: 56,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      maxLines: 1,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      onChanged: (_) => onChanged?.call(),
      style: context.type.body.copyWith(color: colors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: context.type.meta.copyWith(color: colors.ink3),
        filled: true,
        fillColor: colors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
          borderSide: BorderSide(color: colors.calm, width: 2),
        ),
      ),
    );
  }
}
