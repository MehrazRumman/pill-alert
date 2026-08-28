import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../domain/patient_profile.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/labels.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Your details — the patient's own record of who they are. Everything is optional; the screen
/// never validates a field into being required, because a patient who cannot finish this form must
/// still be able to leave it and take their medicine.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _birthYear = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  String _bloodGroup = '';
  bool _dirty = false;
  bool _loaded = false;

  // Seeded here rather than in initState: AppScope is an InheritedWidget, and looking one up before
  // initState completes throws.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final p = AppScope.of(context).settings.profile;
    _name.text = p.name;
    _birthYear.text = p.yearOfBirth?.toString() ?? '';
    _allergies.text = p.allergies;
    _conditions.text = p.conditions;
    _emergencyName.text = p.emergencyName;
    _emergencyPhone.text = p.emergencyPhone;
    _bloodGroup = p.bloodGroup;
  }

  @override
  void dispose() {
    _name.dispose();
    _birthYear.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    // A year outside living memory is far more likely to be a typo than a real birth year, so it is
    // dropped rather than stored and shown back as a nonsense age.
    final year = int.tryParse(_birthYear.text.trim());
    final now = DateTime.now();
    final validYear = (year != null && year >= now.year - 129 && year <= now.year) ? year : null;

    await AppScope.of(context).settings.saveProfile(
          PatientProfile(
            name: _name.text,
            yearOfBirth: validYear,
            bloodGroup: _bloodGroup,
            allergies: _allergies.text,
            conditions: _conditions.text,
            emergencyName: _emergencyName.text,
            emergencyPhone: _emergencyPhone.text,
          ),
        );
    if (mounted) context.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('আপনার তথ্য', 'Your details'),
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
                    Text(
                      context.tr(
                        'কিছুই বাধ্যতামূলক নয়। যা লিখবেন তা কেবল এই ফোনে থাকে, আর ডাক্তারের রিপোর্টে যোগ হয়।',
                        "Nothing here is required. What you enter stays on this phone, and is added "
                        'to your doctor report.',
                      ),
                      style: context.type.body.copyWith(color: colors.ink2),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    SectionLabel(context.tr('পরিচয়', 'About you')),
                    const SizedBox(height: 8),
                    NbCard(
                      radius: Dimens.radiusLargeCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: _name,
                            label: context.tr('নাম', 'Name'),
                            maxLength: 60,
                            onChanged: _touch,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _birthYear,
                            label: context.tr('জন্মের বছর', 'Year of birth'),
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            digitsOnly: true,
                            onChanged: _touch,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr('রক্তের গ্রুপ', 'Blood group'),
                            style: context.type.meta.copyWith(color: colors.ink3),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final g in kBloodGroups)
                                _ChoiceChip(
                                  label: g,
                                  selected: _bloodGroup == g,
                                  // Tapping the selected group clears it — otherwise a mis-tap is
                                  // permanent, and a wrong blood group is worse than none.
                                  onTap: () => setState(() {
                                    _bloodGroup = _bloodGroup == g ? '' : g;
                                    _dirty = true;
                                  }),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    SectionLabel(context.tr('স্বাস্থ্যের তথ্য', 'Health notes')),
                    const SizedBox(height: 8),
                    NbCard(
                      radius: Dimens.radiusLargeCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: _allergies,
                            label: context.tr('অ্যালার্জি', 'Allergies'),
                            hint: context.tr('যেমন: পেনিসিলিন, সালফা', 'e.g. penicillin, sulfa'),
                            maxLength: 200,
                            maxLines: 2,
                            onChanged: _touch,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'কমা দিয়ে আলাদা করুন। কোনো ওষুধের নামে এর একটি মিললে সেভ করার আগে সতর্ক করা হবে।',
                              'Separate with commas. If a medicine name matches one of these, '
                              "you'll be warned before it is saved.",
                            ),
                            style: context.type.meta.copyWith(color: colors.ink3),
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _conditions,
                            label: context.tr('রোগ বা শারীরিক অবস্থা', 'Conditions'),
                            hint: context.tr('যেমন: ডায়াবেটিস', 'e.g. diabetes'),
                            maxLength: 200,
                            maxLines: 2,
                            onChanged: _touch,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    SectionLabel(context.tr('জরুরি যোগাযোগ', 'Emergency contact')),
                    const SizedBox(height: 8),
                    NbCard(
                      radius: Dimens.radiusLargeCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: _emergencyName,
                            label: context.tr('নাম', 'Name'),
                            maxLength: 60,
                            onChanged: _touch,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _emergencyPhone,
                            label: context.tr('ফোন নম্বর', 'Phone number'),
                            maxLength: 20,
                            keyboardType: TextInputType.phone,
                            onChanged: _touch,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'নম্বর দিলে "আরও" পাতায় এক চাপে ফোন করার বোতাম আসবে।',
                              'With a number saved, a one-tap call button appears on the More page.',
                            ),
                            style: context.type.meta.copyWith(color: colors.ink3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.groupGap),

                    PrimaryButton(
                      text: context.tr('সংরক্ষণ করুন', 'Save'),
                      onPressed: _save,
                      enabled: _dirty,
                      height: Dimens.doseConfirm,
                    ),
                    const SizedBox(height: 16),
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

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: NbShapes.chip,
        onTap: onTap,
        // No `alignment` on the Container: with one set it expands to the Wrap's loose
        // constraints and every chip takes a full row. Center(widthFactor: 1) shrink-wraps instead.
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: Dimens.tapMin),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? colors.calm : colors.sage,
            borderRadius: NbShapes.chip,
          ),
          child: Center(
            widthFactor: 1,
            // Blood groups are Latin in both locales, so they take the Latin face either way.
            child: Text(
              label,
              style: context.type
                  .asLatin(context.type.buttonLabel)
                  .copyWith(color: selected ? colors.card : colors.ink2),
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
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLength;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool digitsOnly;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusChip),
      borderSide: BorderSide(color: colors.line, width: 1.5),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (_) => onChanged?.call(),
      style: context.type.body.copyWith(color: colors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: context.type.meta.copyWith(color: colors.ink3),
        hintStyle: context.type.meta.copyWith(color: colors.ink3),
        filled: true,
        fillColor: colors.paper,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
          borderSide: BorderSide(color: colors.calm, width: 2),
        ),
      ),
    );
  }
}
