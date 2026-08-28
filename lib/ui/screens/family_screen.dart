import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/labels.dart';
import '../components/overlays.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Family & caregivers (2v/2h) — who follows the record, what they are told, and the invite code.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  String _inviteCode = newInviteCode();

  Future<void> _edit(BuildContext context, Caregiver? existing) async {
    final updated = await showDialog<Caregiver>(
      context: context,
      barrierColor: nbColors.ink.withValues(alpha: 0.42),
      builder: (context) => _CaregiverDialog(existing: existing),
    );
    if (updated != null && context.mounted) await context.repo.upsertCaregiver(updated);
  }

  Future<void> _remove(BuildContext context, Caregiver existing) async {
    final ok = await confirmAction(
      context,
      title: context.tr('যত্নকারীকে সরাবেন?', 'Remove this caregiver?'),
      message: context.tr(
        '${existing.name} আর আপনার ওষুধের হিসাব পাবেন না। চাইলে পরে আবার যুক্ত করতে পারবেন।',
        '${existing.name} will stop following your medicine record. You can add them again later.', hi: '${existing.name} अब आपकी दवा का हिसाब नहीं देख पाएँगे। बाद में दोबारा जोड़ सकते हैं।', es: '${existing.name} dejará de ver su registro de medicación. Puede añadirle otra vez más adelante.',
      ),
      confirmLabel: context.tr('সরিয়ে দিন', 'Remove'),
      cancelLabel: context.tr('রেখে দিন', 'Keep them'),
    );
    if (ok && context.mounted) await context.repo.deleteCaregiver(existing.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('পরিবার ও যত্নকারী', 'Family & caregivers'),
            onBack: context.nav.back,
          ),
          Expanded(
            child: RepoBuilder<(Caregiver?, List<AlertLogItem>)>(
              query: (repo) async => (await repo.primaryCaregiver(), await repo.alertLog()),
              builder: (context, data) {
                final (cg, alerts) = data;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.screenPadding,
                    vertical: 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stated first, not buried at the foot of the screen. Everything below
                        // saves correctly, but nothing is delivered to anyone yet, and a patient
                        // relying on family alerts that never arrive is the worst way to find out.
                        const _ComingSoonPanel(),
                        const SizedBox(height: Dimens.groupGap),
                        if (cg != null) ...[
                          _CaregiverCard(
                            cg: cg,
                            onEdit: () => _edit(context, cg),
                            onRemove: () => _remove(context, cg),
                          ),
                          const SizedBox(height: Dimens.groupGap),
                          SectionLabel(context.tr("তাকে জানানো হবে যখন", "They'll be told when")),
                          const SizedBox(height: 8),
                          NbCard(
                            child: Column(
                              children: [
                                _ToggleLine(
                                  title: context.tr(
                                    'পরপর দুবার বাদ পড়লে',
                                    'Missed twice in a row',
                                  ),
                                  checked: cg.notifyOnMissedTwice,
                                  onChanged: (v) => context.repo
                                      .upsertCaregiver(cg.copyWith(notifyOnMissedTwice: v)),
                                ),
                                _ToggleLine(
                                  title: context.tr('ওষুধ ফুরিয়ে গেলে', 'Out of stock'),
                                  checked: cg.notifyOnOutOfStock,
                                  onChanged: (v) => context.repo
                                      .upsertCaregiver(cg.copyWith(notifyOnOutOfStock: v)),
                                ),
                                _ToggleLine(
                                  title: context.tr('সাপ্তাহিক হিসাব', 'Weekly summary'),
                                  checked: cg.weeklySummary,
                                  onChanged: (v) => context.repo
                                      .upsertCaregiver(cg.copyWith(weeklySummary: v)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            text: context.tr(
                              'কীভাবে জানানো হবে ঠিক করুন',
                              "Choose how they're told",
                            ),
                            onPressed: context.nav.openCaregiverNotify,
                            height: 52,
                          ),
                          const SizedBox(height: Dimens.groupGap),
                        ],

                        // Invite block.
                        TintPanel(
                          background: colors.calmSoft,
                          radius: Dimens.radiusLargeCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.tr('নতুন কাউকে যুক্ত করুন', 'Invite someone new'),
                                style:
                                    context.type.cardTitlePrimary.copyWith(color: colors.calmD),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr(
                                  'এই কোডটি তাদের অ্যাপে দিতে বলুন',
                                  'Ask them to enter this code in their app',
                                ),
                                style: context.type.meta.copyWith(color: colors.ink2),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (final c in _inviteCode.split('')) ...[
                                    Container(
                                      width: 52,
                                      height: 60,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: colors.card,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        c,
                                        // The code is Latin in both locales.
                                        style: context.type
                                            .asLatin(context.type.titleHero)
                                            .copyWith(fontSize: 28, color: colors.ink),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  'কোডটি ২৪ ঘণ্টা কার্যকর থাকবে',
                                  'The code works for 24 hours',
                                ),
                                style: context.type.meta.copyWith(color: colors.ink3),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      text: context.tr('কোড পাঠান', 'Send code'),
                                      height: 52,
                                      onPressed: () {
                                        final message = context.isBangla
                                            ? 'নির্ভরে যুক্ত হতে এই কোডটি দিন: $_inviteCode'
                                            : 'Use this code to connect in Nirbhor: $_inviteCode';
                                        SharePlus.instance.share(ShareParams(text: message));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 112,
                                    child: SecondaryButton(
                                      text: context.tr('নতুন কোড', 'New code'),
                                      height: 52,
                                      onPressed: () =>
                                          setState(() => _inviteCode = newInviteCode()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SecondaryButton(
                                text: context.tr('আমার কাছে কোড আছে', 'I already have a code'),
                                onPressed: context.nav.openCaregiverCode,
                                height: 52,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),


                        if (alerts.isNotEmpty) ...[
                          const SizedBox(height: Dimens.groupGap),
                          SectionLabel(context.tr('সাম্প্রতিক বার্তা', 'Recent alerts')),
                          const SizedBox(height: 8),
                          NbCard(
                            child: Column(
                              children: [for (final a in alerts) _AlertLine(item: a)],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard({required this.cg, required this.onEdit, required this.onRemove});

  final Caregiver cg;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = [cg.relationship, cg.phone, cg.email]
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
    return NbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  cg.name.isEmpty ? '?' : cg.name.characters.first,
                  style: context.type.asBangla(context.type.header).copyWith(color: colors.calmD),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cg.name,
                      style: context.type
                          .asBangla(context.type.cardTitlePrimary)
                          .copyWith(color: colors.ink),
                    ),
                    if (detail.isNotEmpty)
                      // The relationship is typed by the patient and will be Bangla, while the
                      // phone and email are Latin. Anek covers both scripts; Archivo would have
                      // turned "ছেলে" into boxes.
                      Text(
                        detail,
                        style: context.type
                            .asBangla(context.type.meta)
                            .copyWith(color: colors.ink3),
                      ),
                  ],
                ),
              ),
              StatusPill(
                text: context.tr('সক্রিয়', 'Active'),
                background: colors.calmSoft,
                contentColor: colors.calmD,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: context.tr('তথ্য বদলান', 'Edit details'),
                  onPressed: onEdit,
                  height: 48,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SecondaryButton(
                  text: context.tr('সরিয়ে দিন', 'Remove'),
                  onPressed: onRemove,
                  height: 48,
                  borderColor: colors.warm,
                  content: colors.warmD,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Add / edit the person who follows the patient's record. Name is the only required field.
class _CaregiverDialog extends StatefulWidget {
  const _CaregiverDialog({required this.existing});

  final Caregiver? existing;

  @override
  State<_CaregiverDialog> createState() => _CaregiverDialogState();
}

class _CaregiverDialogState extends State<_CaregiverDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _relationship =
      TextEditingController(text: widget.existing?.relationship ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.existing?.email ?? '');

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final existing = widget.existing;
    final trimmedEmail = _email.text.trim();
    final caregiver = existing != null
        ? existing.copyWith(
            name: _name.text.trim(),
            relationship: _relationship.text.trim(),
            phone: _phone.text.trim(),
            email: trimmedEmail,
            // Verification is a delivery-side step; changing the address undoes it.
            emailVerified: existing.emailVerified && trimmedEmail == existing.email,
          )
        : Caregiver(
            id: 'cg-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
            name: _name.text.trim(),
            relationship: _relationship.text.trim(),
            email: trimmedEmail,
            emailVerified: false,
            phone: _phone.text.trim(),
            channels: trimmedEmail.isNotEmpty ? {CaregiverChannel.email} : <CaregiverChannel>{},
            digestFrequency: DigestFrequency.dailyDigest,
            escalateOnSecondMiss: true,
            notifyOnMissedTwice: true,
            notifyOnOutOfStock: true,
            weeklySummary: false,
          );
    Navigator.of(context).pop(caregiver);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  widget.existing == null
                      ? context.tr('যত্নকারী যোগ করুন', 'Add a caregiver')
                      : context.tr('তথ্য বদলান', 'Edit details'),
                  style: context.type.header.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'তাঁর নাম দিন। ফোন বা ইমেইল না দিলেও চলবে।',
                    'Give their name. Phone and email are optional.',
                  ),
                  style: context.type.body.copyWith(color: colors.ink2),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _name,
                  label: context.tr('নাম', 'Name'),
                  maxLength: 60,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _relationship,
                  label: context.tr(
                    'সম্পর্ক (যেমন ছেলে, মেয়ে)',
                    'Relationship (e.g. son, daughter)',
                  ),
                  maxLength: 40,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _phone,
                  label: context.tr('ফোন নম্বর (ঐচ্ছিক)', 'Phone number (optional)'),
                  maxLength: 24,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _email,
                  label: context.tr('ইমেইল (ঐচ্ছিক)', 'Email (optional)'),
                  maxLength: 80,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: context.tr('সেভ করুন', 'Save'),
                  onPressed: _save,
                  enabled: _name.text.trim().isNotEmpty,
                  height: 56,
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  text: context.tr('বাতিল', 'Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  height: 56,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final TextInputType? keyboardType;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

/// Ambiguous characters (I, O, 0, 1) are left out so a code read aloud over the phone survives.
String newInviteCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = math.Random();
  return List.generate(4, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
}

class _ToggleLine extends StatelessWidget {
  const _ToggleLine({required this.title, required this.checked, required this.onChanged});

  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.type.cardTitleSecondary.copyWith(color: colors.ink),
            ),
          ),
          NbSwitch(checked: checked, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.item});

  final AlertLogItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dot = item.kind == 'missed' ? colors.warm : colors.calm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.message, style: context.type.meta.copyWith(color: colors.ink2)),
          ),
          Text(item.outcome, style: context.type.meta.copyWith(color: colors.ink3)),
        ],
      ),
    );
  }
}


/// The standing notice on this screen: caregivers can be set up, but nothing is delivered yet.
class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TintPanel(
      background: colors.warmSoft,
      radius: Dimens.radiusLargeCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: colors.warmD),
              const SizedBox(width: 8),
              Text(
                context.tr('শীঘ্রই আসছে', 'Coming soon'),
                style: context.type.cardTitlePrimary.copyWith(color: colors.warmD),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'পরিবারকে জানানোর সুবিধাটি এখনও চালু হয়নি। এখানে যা যোগ করবেন তা সেভ থাকবে, কিন্তু আপাতত কোনো ইমেইল, এসএমএস বা খবর পাঠানো হয় না।',
              "Telling your family isn't switched on yet. Anything you set up here is saved, but for "
              'now no email, SMS or alert is actually sent.',
            ),
            style: context.type.body.copyWith(color: colors.warmD),
          ),
        ],
      ),
    );
  }
}
