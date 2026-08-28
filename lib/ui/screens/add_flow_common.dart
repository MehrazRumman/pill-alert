import 'package:flutter/material.dart';

import '../../domain/add_medicine_draft.dart';
import '../../domain/models.dart';
import '../../theme/theme.dart';

export '../../domain/add_medicine_draft.dart';

/// Holds the in-progress add-medicine draft above the flow so every step is back-navigable without
/// losing what was entered.
class AddDraftScope extends InheritedNotifier<AddMedicineDraft> {
  const AddDraftScope({super.key, required AddMedicineDraft draft, required super.child})
      : super(notifier: draft);

  static AddMedicineDraft of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AddDraftScope>();
    assert(scope != null, 'AddDraftScope is missing above this widget');
    return scope!.notifier!;
  }
}

extension AddDraftContext on BuildContext {
  AddMedicineDraft get draft => AddDraftScope.of(this);
}

/// The three-segment progress header used by the timing → quantity → review steps.
class AddFlowHeader extends StatelessWidget {
  const AddFlowHeader({super.key, required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.paper,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.denseHeaderPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: context.tr('পিছনে যান', 'Back'),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: SizedBox(
                    width: Dimens.tapMin,
                    height: Dimens.tapMin,
                    child: Icon(Icons.arrow_back, color: colors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < step ? colors.calm : colors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Assigns a stable mark + colour from a medicine's name, so the same medicine always looks the
/// same wherever it appears. Marks are stored on the record, never re-derived after creation.
const List<(MarkShape, int)> markPalette = [
  (MarkShape.filledCircle, 0xFF2F6B5B),
  (MarkShape.ring, 0xFF2F6B5B),
  (MarkShape.roundedSquare, 0xFF7D94A8),
  (MarkShape.triangle, 0xFFB9975B),
  (MarkShape.capsule, 0xFFA8788F),
  (MarkShape.halfFilled, 0xFF2F6B5B),
];

(MarkShape, int) markForName(String name) {
  if (name.trim().isEmpty) return (MarkShape.filledCircle, 0xFF2F6B5B);
  var hash = 0;
  for (final unit in name.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return markPalette[hash % markPalette.length];
}
