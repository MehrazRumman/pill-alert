import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/scaffold.dart';
import '../components/surfaces.dart';
import '../marks/medicine_mark.dart';
import 'add_flow_common.dart';

/// Add by name (3g). Free-text entry — the patient types exactly what's on the pack; no catalog.
class AddSearchScreen extends StatefulWidget {
  const AddSearchScreen({super.key});

  @override
  State<AddSearchScreen> createState() => _AddSearchScreenState();
}

class _AddSearchScreenState extends State<AddSearchScreen> {
  final _controller = TextEditingController();

  String get _query => _controller.text;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continueWithName() {
    final name = _query.trim();
    if (name.isEmpty) return;
    final (mark, color) = markForName(_query);
    final draft = context.draft;
    draft.update(() {
      draft.displayName = name;
      draft.packName = name;
      draft.strength = '';
      draft.form = context.tr('ট্যাবলেট', 'tablet');
      draft.condition = '';
      draft.mark = mark;
      draft.markColor = color;
    });
    context.nav.addTiming();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (mark, color) = markForName(_query);

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          NirbhorTopBar(
            title: context.tr('নাম দিয়ে যোগ করুন', 'Add by name'),
            onBack: context.nav.back,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.screenPadding,
                vertical: 12,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.calm, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: colors.ink3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              maxLines: 1,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              cursorColor: colors.calm,
                              inputFormatters: [LengthLimitingTextInputFormatter(80)],
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _continueWithName(),
                              style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: context.tr(
                                  'ওষুধের নাম লিখুন',
                                  'Type the medicine name',
                                ),
                                hintStyle: context.type.cardTitleSecondary
                                    .copyWith(color: colors.ink3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimens.cardGap),
                    if (_query.trim().isNotEmpty)
                      Material(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(Dimens.radiusCard),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _continueWithName,
                          child: Padding(
                            padding: const EdgeInsets.all(Dimens.cardPadding),
                            child: Row(
                              children: [
                                MedicineMark(shape: mark, color: Color(color), size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _query.trim(),
                                        style: context.type.cardTitlePrimary
                                            .copyWith(color: colors.ink),
                                      ),
                                      Text(
                                        context.tr(
                                          'এই নামে যোগ করুন',
                                          'Add with this name',
                                        ),
                                        style: context.type.meta
                                            .copyWith(color: colors.calm),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      TintPanel(
                        background: colors.calmSoft,
                        child: Text(
                          context.tr(
                            'পাতায় যে নাম লেখা আছে ঠিক সেটাই লিখুন — পরের ধাপে সময় ও পরিমাণ বেছে নেবেন।',
                            "Type the exact name printed on the pack — you'll set the time and amount next.",
                          ),
                          style: context.type.body.copyWith(color: colors.calmD),
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
