import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/buttons.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';

/// Join by code (6d). The four boxes are a styled overlay on one hidden field, so the platform
/// keyboard, selection and paste all behave normally.
class CaregiverCodeScreen extends StatefulWidget {
  const CaregiverCodeScreen({super.key});

  @override
  State<CaregiverCodeScreen> createState() => _CaregiverCodeScreenState();
}

class _CaregiverCodeScreenState extends State<CaregiverCodeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _joinAttempted = false;
  bool _showCodeHelp = false;

  String get _code => _controller.text;
  bool get _matched => _code.length == 4;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('কোড দিয়ে যুক্ত হোন', 'Join by code'),
            onBack: context.nav.back,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 20,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr(
                        'রোগীর অ্যাপে দেখানো ৪-অক্ষরের কোডটি লিখুন',
                        "Enter the 4-character code shown in the patient's app",
                      ),
                      style: context.type.body.copyWith(color: colors.ink2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimens.groupGap),
                    Center(
                      child: Stack(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < 4; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Container(
                                  width: 70,
                                  height: 70,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: i == _code.length ? colors.calm : colors.line,
                                      width: i == _code.length ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    i < _code.length ? _code[i] : '',
                                    // The code is Latin in both locales.
                                    style: context.type
                                        .asLatin(context.type.titleHero)
                                        .copyWith(fontSize: 28, color: colors.ink),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                autofocus: true,
                                showCursor: false,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  TextInputFormatter.withFunction(
                                    (_, next) => next.copyWith(text: next.text.toUpperCase()),
                                  ),
                                ],
                                onChanged: (_) => setState(() => _joinAttempted = false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_matched) ...[
                      const SizedBox(height: Dimens.groupGap),
                      TintPanel(
                        background: colors.calmSoft,
                        radius: Dimens.radiusLargeCard,
                        // Nothing has resolved this code yet, so name no one here.
                        child: Text(
                          context.tr(
                            'রোগীর হিসাবের সঙ্গে যুক্ত হচ্ছেন',
                            "Connecting to the patient's record",
                          ),
                          style: context.type.cardTitlePrimary.copyWith(color: colors.calmD),
                        ),
                      ),
                      const SizedBox(height: Dimens.cardGap),
                      TintPanel(
                        background: colors.sage,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in [
                              context.tr(
                                '• আপনি শুধু দেখতে পারবেন, বদলাতে পারবেন না',
                                '• You can only view, not change anything',
                              ),
                              context.tr(
                                '• রোগী চাইলে যেকোনো সময় সরাতে পারবেন',
                                '• The patient can remove you any time',
                              ),
                              context.tr(
                                '• আপনি যা দেখছেন, রোগীও তা জানেন',
                                '• The patient sees what you see',
                              ),
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: context.type.body.copyWith(color: colors.ink2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_joinAttempted) ...[
                      TintPanel(
                        background: colors.warmSoft,
                        child: Text(
                          context.tr(
                            'কোড দিয়ে যুক্ত হওয়া এখনও চালু হয়নি। এই সংস্করণে হিসাব শুধু রোগীর ফোনেই থাকে।',
                            "Joining by code isn't switched on yet. In this version the record stays on the patient's phone.",
                          ),
                          style: context.type.body.copyWith(color: colors.warmD),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      text: context.tr('যুক্ত হোন', 'Join'),
                      height: 68,
                      enabled: _matched,
                      onPressed: () => setState(() => _joinAttempted = true),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showCodeHelp = !_showCodeHelp),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(Dimens.tapMin),
                      ),
                      child: Text(
                        context.tr('কোড নেই?', 'No code?'),
                        style: context.type.buttonLabel.copyWith(color: colors.calm),
                      ),
                    ),
                    if (_showCodeHelp)
                      TintPanel(
                        background: colors.sage,
                        child: Text(
                          context.tr(
                            'রোগীর ফোনে নির্ভর খুলে “আরও → পরিবার ও যত্নকারী”-তে যেতে বলুন। সেখানে ৪-অক্ষরের কোডটি দেখা যাবে।',
                            'Ask the patient to open Nirbhor and go to More → Family & caregivers. The 4-character code is shown there.',
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
