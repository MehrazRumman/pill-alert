import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/app_scope.dart';
import '../../data/repository.dart';
import '../../navigation/nav_actions.dart';
import '../../domain/patient_profile.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/controls.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';

/// Doctor report (6c) — a scaled preview of the PDF, then send or save it.
class DoctorReportScreen extends StatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  int _rangeIdx = 0;
  bool _latinNames = true;
  String? _exportMessage;

  int get _days => const [30, 90, 365][_rangeIdx];

  void _setRange(int i) => setState(() {
        _rangeIdx = i;
        // A "Report saved" note from the previous range would be stale once the range changes.
        _exportMessage = null;
      });

  Future<void> _send(AdherenceWindow window, List<MedAdherence> perMed) async {
    setState(() => _exportMessage = null);
    try {
      final bytes = await _buildReportPdf(
        days: _days,
        window: window,
        medicines: perMed,
        latinNames: _latinNames,
        profile: context.settingsStore.profile,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nirbhor-medication-report.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _exportMessage =
            context.tr('রিপোর্ট বানানো যায়নি', "Couldn't create the report"));
      }
    }
  }

  Future<void> _save(AdherenceWindow window, List<MedAdherence> perMed) async {
    setState(() => _exportMessage = null);
    try {
      final bytes = await _buildReportPdf(
        days: _days,
        window: window,
        medicines: perMed,
        latinNames: _latinNames,
        profile: context.settingsStore.profile,
      );
      final saved = await FilePicker.saveFile(
        fileName: 'nirbhor-medication-report-$_days-days.pdf',
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );
      if (!mounted) return;
      // A null result means the patient backed out of the picker, which is not a failure.
      if (saved != null) {
        setState(() =>
            _exportMessage = context.tr('রিপোর্ট সেভ হয়েছে', 'Report saved'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _exportMessage =
            context.tr('রিপোর্ট সেভ করা যায়নি', "Couldn't save the report"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('ডাক্তারের রিপোর্ট', 'Doctor report'),
            onBack: context.nav.back,
          ),
          Expanded(
            child: RepoBuilder<(AdherenceWindow, List<MedAdherence>)>(
              key: ValueKey(_days),
              query: (repo) async =>
                  (await repo.adherenceOver(_days), await repo.perMedicineAdherence(_days)),
              builder: (context, data) {
                final (window, perMed) = data;
                final reported = perMed.where((m) => m.total > 0).toList();
                final hasSomethingToReport = window.total > 0;

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
                        SegmentedControl(
                          options: [
                            context.tr('১ মাস', '1 month'),
                            context.tr('৩ মাস', '3 months'),
                            context.tr('১ বছর', '1 year'),
                          ],
                          selectedIndex: _rangeIdx,
                          onSelect: _setRange,
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        // Scaled PDF page preview.
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.line),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.tr(
                                  'নির্ভর · ওষুধের হিসাব',
                                  'Nirbhor · Medication record',
                                ),
                                style: context.type.cardTitleSecondary.copyWith(
                                  fontSize: 16,
                                  color: colors.ink,
                                ),
                              ),
                              Text(
                                context.tr(
                                  'রোগীর নিজের হিসাব · গত ${context.num(_days)} দিন',
                                  "Patient's own record · last $_days days", hi: 'रोगी का अपना रिकॉर्ड · पिछले $_days दिन', es: 'Registro del propio paciente · últimos $_days días',
                                ),
                                style: context.type.meta.copyWith(
                                  fontSize: 12,
                                  color: colors.ink2,
                                ),
                              ),
                              // Same patient block the PDF prints, so the preview is honest about
                              // what the doctor will actually receive.
                              Builder(
                                builder: (context) {
                                  final p = context.settingsStore.profile;
                                  if (p.isEmpty) return const SizedBox.shrink();
                                  final age = p.ageOn(DateTime.now());
                                  final rows = <(String, String, bool)>[
                                    if (p.name.trim().isNotEmpty)
                                      (context.tr('রোগী', 'Patient'), p.name.trim(), false),
                                    if (age != null)
                                      (context.tr('বয়স', 'Age'), context.num(age), false),
                                    if (p.bloodGroup.isNotEmpty)
                                      (context.tr('রক্তের গ্রুপ', 'Blood group'), p.bloodGroup, false),
                                    if (p.allergies.trim().isNotEmpty)
                                      (context.tr('অ্যালার্জি', 'Allergies'), p.allergies.trim(), true),
                                    if (p.conditions.trim().isNotEmpty)
                                      (context.tr('অবস্থা', 'Conditions'), p.conditions.trim(), false),
                                  ];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colors.line),
                                        borderRadius: BorderRadius.circular(Dimens.radiusChip),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (final r in rows)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 96,
                                                    child: Text(
                                                      r.$1,
                                                      style: context.type.meta
                                                          .copyWith(color: colors.ink3),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      r.$2,
                                                      style: context.type.meta.copyWith(
                                                        color: r.$3 ? colors.warmD : colors.ink,
                                                        fontWeight:
                                                            r.$3 ? FontWeight.w700 : null,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatTile(
                                      bg: colors.calmSoft,
                                      fg: colors.calmD,
                                      value: context.num(window.taken),
                                      label: context.tr('নেওয়া', 'Taken'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _StatTile(
                                      bg: colors.warmSoft,
                                      fg: colors.warmD,
                                      value: context.num(window.missed),
                                      label: context.tr('বাদ', 'Missed'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _StatTile(
                                      bg: colors.sage,
                                      fg: colors.ink,
                                      value: context.percent(window.percent),
                                      label: context.tr('সময়মতো', 'On time'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              for (final m in reported)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      MedicineMark(
                                        shape: m.medicine.mark,
                                        color: Color(m.medicine.markColor),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          _latinNames && m.medicine.packName.trim().isNotEmpty
                                              ? m.medicine.packName
                                              : m.medicine.displayName,
                                          // The locale face carries per-glyph fallback to the
                                          // other scripts; a Hindi or Bangla display name must not
                                          // be forced into a single family.
                                          style: (_latinNames && m.medicine.packName.trim().isNotEmpty
                                                  ? context.type.asLatin(context.type.meta)
                                                  : context.type.meta)
                                              .copyWith(
                                            fontSize: 12,
                                            color: colors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: SizedBox(
                                            height: 9,
                                            child: ColoredBox(
                                              color: colors.sage,
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor:
                                                    (m.percent / 100).clamp(0.0, 1.0),
                                                child: ColoredBox(
                                                  color: m.percent >= 80
                                                      ? colors.calm
                                                      : colors.warm,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.percent(m.percent),
                                        style: context.type.meta.copyWith(
                                          fontSize: 12,
                                          color: colors.ink2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr(
                                  'এটি রোগীর নিজের রাখা হিসাব — কোনো ক্লিনিক্যাল পরিমাপ নয়।',
                                  "This is the patient's own record, not a clinical measurement.",
                                ),
                                style: context.type.meta.copyWith(
                                  fontSize: 11,
                                  color: colors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        NbCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(
                                        'ওষুধের নাম ইংরেজিতে',
                                        'Medicine names in English',
                                      ),
                                      style: context.type.cardTitleSecondary
                                          .copyWith(color: colors.ink),
                                    ),
                                    Text(
                                      context.tr(
                                        'ডাক্তার সাধারণত ল্যাটিন নাম পড়েন',
                                        'Doctors usually read the Latin names',
                                      ),
                                      style:
                                          context.type.meta.copyWith(color: colors.ink3),
                                    ),
                                  ],
                                ),
                              ),
                              NbSwitch(
                                checked: _latinNames,
                                onChanged: (v) => setState(() => _latinNames = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimens.groupGap),

                        if (!hasSomethingToReport) ...[
                          TintPanel(
                            background: colors.sage,
                            child: Text(
                              context.tr(
                                'এই সময়ে হিসাব করার মতো কোনো ডোজ নেই — রিপোর্টে দেখানোর কিছু থাকবে না।',
                                'No doses were counted in this period, so there is nothing to put in the report.',
                              ),
                              style: context.type.body.copyWith(color: colors.ink2),
                            ),
                          ),
                          const SizedBox(height: Dimens.groupGap),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: context.tr('পাঠান', 'Send'),
                                height: 60,
                                enabled: hasSomethingToReport,
                                onPressed: () => _send(window, perMed),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 112,
                              child: SecondaryButton(
                                text: context.tr('সেভ করুন', 'Save'),
                                height: 60,
                                enabled: hasSomethingToReport,
                                onPressed: () => _save(window, perMed),
                              ),
                            ),
                          ],
                        ),
                        if (_exportMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _exportMessage!,
                            style: context.type.meta.copyWith(color: colors.calmD),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.bg,
    required this.fg,
    required this.value,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.type.bigStat.copyWith(fontSize: 30, color: fg)),
            Text(label, style: context.type.meta.copyWith(fontSize: 11, color: fg)),
          ],
        ),
      );
}

/// Builds the A4 report. Medicine names can be Bangla when the Latin toggle is off, so the bundled
/// Anek Bangla face is embedded — the PDF standard fonts carry no Bengali glyphs at all.
Future<Uint8List> _buildReportPdf({
  required int days,
  required AdherenceWindow window,
  required List<MedAdherence> medicines,
  required bool latinNames,
  required PatientProfile profile,
}) async {
  final bangla = pw.Font.ttf(await rootBundle.load('assets/fonts/AnekBangla.ttf'));
  final latin = pw.Font.ttf(await rootBundle.load('assets/fonts/Archivo.ttf'));
  final devanagari = pw.Font.ttf(await rootBundle.load('assets/fonts/AnekDevanagari.ttf'));

  // Mirrors NirbhorColors; PdfColor cannot take the token directly.
  const ink = PdfColor.fromInt(0xFF14262A);
  const ink2 = PdfColor.fromInt(0xFF42585D);
  const line = PdfColor.fromInt(0xFFD2DADA);
  const warmD = PdfColor.fromInt(0xFF7C4218);

  final today = DateTime.now();
  final stamp = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  final reported = medicines.where((m) => m.total > 0).toList();

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: latin, bold: latin, fontFallback: [bangla, devanagari]),
  );

  pw.Widget headerCell(String text) => pw.Text(
        text,
        style: pw.TextStyle(font: latin, fontSize: 12, color: ink2, fontWeight: pw.FontWeight.bold),
      );

  // (label, value, emphasise). Allergies are emphasised: they are the one line on this sheet that
  // changes what a doctor should not prescribe.
  final age = profile.ageOn(today);
  final patientRows = <(String, String, bool)>[
    if (profile.name.trim().isNotEmpty) ('Patient', profile.name.trim(), false),
    if (age != null) ('Age', '$age', false),
    if (profile.bloodGroup.isNotEmpty) ('Blood group', profile.bloodGroup, false),
    if (profile.allergies.trim().isNotEmpty) ('Allergies', profile.allergies.trim(), true),
    if (profile.conditions.trim().isNotEmpty) ('Conditions', profile.conditions.trim(), false),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 48),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Nirbhor - Medication record',
            style: pw.TextStyle(font: latin, fontSize: 22, fontWeight: pw.FontWeight.bold, color: ink),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Patient-maintained record - last $days days - $stamp',
            style: pw.TextStyle(font: latin, fontSize: 12, color: ink2),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: line, height: 1),
          pw.SizedBox(height: 12),
        ],
      ),
      build: (context) => [
        // Who the record belongs to. Printed first: a sheet of adherence numbers with no patient
        // on it is of no use to a doctor holding several of them.
        if (!profile.isEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: line, width: 0.8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final row in patientRows) ...[
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 92,
                          child: pw.Text(
                            row.$1,
                            style: pw.TextStyle(font: latin, fontSize: 11, color: ink2),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            row.$2,
                            style: pw.TextStyle(
                              font: latin,
                              fontSize: 11.5,
                              color: row.$3 ? warmD : ink,
                              fontWeight: row.$3 ? pw.FontWeight.bold : pw.FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            headerCell('Taken: ${window.taken}'),
            headerCell('Missed: ${window.missed}'),
            // Late doses count in "Taken" but not in this percentage, so it is labelled for what
            // it is; "Adherence" beside a Taken count that includes them read as a contradiction.
            headerCell('On time: ${window.percent}%'),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            pw.Expanded(flex: 5, child: headerCell('Medicine')),
            pw.Expanded(flex: 3, child: headerCell('Taken / counted')),
            pw.Expanded(flex: 2, child: headerCell('On time')),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: line, height: 1),
        if (reported.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'No completed doses in this period.',
              style: pw.TextStyle(font: latin, fontSize: 12, color: ink2),
            ),
          ),
        for (final item in reported)
          pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        _clip(latinNames
                            ? (item.medicine.packName.trim().isEmpty
                                ? item.medicine.displayName
                                : item.medicine.packName)
                            : item.medicine.displayName),
                        style: pw.TextStyle(
                          // A Bangla or Hindi display name needs its own face, not the Latin one.
                          font: latin,
                          fontFallback: [bangla, devanagari],
                          fontSize: 12,
                          color: ink2,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '${item.taken} / ${item.total}',
                        style: pw.TextStyle(font: latin, fontSize: 12, color: ink2),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '${item.percent}%',
                        style: pw.TextStyle(
                          font: latin,
                          fontSize: 12,
                          color: ink,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(color: line, height: 1),
            ],
          ),
        pw.SizedBox(height: 20),
        pw.Text(
          "This is the patient's own record, not a clinical measurement.",
          style: pw.TextStyle(font: latin, fontSize: 10, color: ink2),
        ),
      ],
    ),
  );

  return doc.save();
}

String _clip(String name) => name.length > 42 ? '${name.substring(0, 39)}...' : name;
