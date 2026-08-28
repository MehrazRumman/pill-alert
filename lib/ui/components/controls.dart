import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 50×30 toggle, 24px white knob. Track goes calm when on (or warmD for the amber override row).
class NbSwitch extends StatelessWidget {
  const NbSwitch({
    super.key,
    required this.checked,
    required this.onChanged,
    this.onColor,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final track = checked ? (onColor ?? colors.calm) : colors.line;
    return Semantics(
      toggled: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: SizedBox(
          width: Dimens.tapMin,
          height: Dimens.tapMin,
          child: Center(
            child: Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(15)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control: paper track, active segment calm-filled. Week/Month, range selectors, etc.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: colors.paper, borderRadius: BorderRadius.circular(11)),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Semantics(
                selected: i == selectedIndex,
                inMutuallyExclusiveGroup: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selectedIndex ? colors.calm : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      options[i],
                      style: context.type.cardTitleSecondary.copyWith(
                        color: i == selectedIndex ? colors.paper : colors.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quantity stepper (README > 3d): [size]px −/+ buttons (minus outlined on paper, plus solid calm),
/// a centred 46/700 value and a unit label below. Steps by [step] (supports halves).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.valueLabel,
    required this.unitLabel,
    this.size = Dimens.stepper,
    this.step = 1,
    this.min = 0,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String valueLabel;
  final String unitLabel;
  final double size;
  final double step;
  final double min;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _StepperButton(
          size: size,
          filled: false,
          semanticLabel: context.tr('কমান', 'Decrease'),
          onTap: () {
            final next = (value - step) < min ? min : value - step;
            if (next != value) onChanged(next);
          },
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valueLabel,
                style: context.type.bigStat.copyWith(color: colors.ink),
              ),
              Text(unitLabel, style: context.type.meta.copyWith(color: colors.ink3)),
            ],
          ),
        ),
        _StepperButton(
          size: size,
          filled: true,
          semanticLabel: context.tr('বাড়ান', 'Increase'),
          onTap: () => onChanged(value + step),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.size,
    required this.filled,
    required this.semanticLabel,
    required this.onTap,
  });

  final double size;
  final bool filled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final side = size < Dimens.tapMin ? Dimens.tapMin : size;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: filled ? colors.calm : colors.paper,
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: colors.line, width: 1.5),
          ),
          child: Icon(
            filled ? Icons.add : Icons.remove,
            size: 28,
            color: filled ? colors.paper : colors.ink2,
          ),
        ),
      ),
    );
  }
}

/// Quick chip (আধা / ১ / ২ / ৩). Selected chip must always match the stepper value.
class QuickChip extends StatelessWidget {
  const QuickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 52,
    this.multiSelect = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      checked: multiSelect ? selected : null,
      inMutuallyExclusiveGroup: multiSelect ? null : true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height < Dimens.tapMin ? Dimens.tapMin : height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.calm : colors.sage,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: context.type.cardTitleSecondary
                .copyWith(color: selected ? colors.paper : colors.ink2),
          ),
        ),
      ),
    );
  }
}

/// A large selectable row (README > 3c timing rows, 4a channel cards): icon + title (+ subtitle) and
/// a trailing check circle. Selected = calm fill, white text, filled check. Supports multi-select.
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.height = 88,
    this.leading,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final double height;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      checked: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? colors.calm : colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.calm : colors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.type.cardTitlePrimary
                          .copyWith(color: selected ? colors.paper : colors.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.type.meta.copyWith(
                          color: selected
                              ? colors.paper.withValues(alpha: 0.85)
                              : colors.ink2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CheckCircle(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.selected, this.size = 34});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.card : Colors.transparent,
        border: selected ? null : Border.all(color: colors.line, width: 2),
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.62, color: colors.calm)
          : null,
    );
  }
}
