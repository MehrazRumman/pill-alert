import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

/// The Nirbhor button family. Height is passed per context (README > Touch targets): 56 home
/// dose-confirm, 60–68 add-medicine/alarm flow, 80 alarm confirm. Primary = calm fill; secondary =
/// outlined. Labels can be centred or left-aligned with a leading icon (the first-run actions).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = Dimens.flowButton,
    this.enabled = true,
    this.container,
    this.content,
    this.leftAligned = false,
    this.leading,
    this.trailing,
  });

  final String text;
  final VoidCallback onPressed;
  final double height;
  final bool enabled;
  final Color? container;
  final Color? content;
  final bool leftAligned;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A disabled button used to be the enabled one at 50% opacity, which put a white label on pale
    // green at 1.5:1 — the label all but vanished. An explicit disabled palette keeps it readable
    // (4.8:1) while still reading as unavailable.
    final background = enabled ? (container ?? colors.calm) : colors.sage;
    final foreground = enabled ? (content ?? colors.paper) : colors.ink3;
    return _ButtonSurface(
        height: height,
        enabled: enabled,
        background: background,
        lifted: true,
        onPressed: onPressed,
        child: _ButtonRow(
          leftAligned: leftAligned,
          leading: leading,
          trailing: trailing,
          label: Text(
            text,
            style: context.type.buttonLabel.copyWith(color: foreground),
            textAlign: leftAligned ? TextAlign.start : TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = Dimens.flowButton,
    this.enabled = true,
    this.borderColor,
    this.content,
    this.container,
    this.leftAligned = false,
    this.leading,
  });

  final String text;
  final VoidCallback onPressed;
  final double height;
  final bool enabled;
  final Color? borderColor;
  final Color? content;

  /// Fill colour. Defaults to the card surface; the alarm passes a translucent white instead,
  /// because a white-filled button on the dark alarm surface left its pale label at 1.1:1.
  final Color? container;
  final bool leftAligned;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = enabled ? (content ?? colors.calm) : colors.ink3;
    return _ButtonSurface(
        height: height,
        enabled: enabled,
        background: container ?? colors.card,
        border: Border.all(color: borderColor ?? colors.line, width: 1.5),
        onPressed: onPressed,
        child: _ButtonRow(
          leftAligned: leftAligned,
          leading: leading,
          label: Text(
            text,
            style: context.type.buttonLabel.copyWith(color: foreground),
            textAlign: leftAligned ? TextAlign.start : TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
  }
}

class _ButtonSurface extends StatefulWidget {
  const _ButtonSurface({
    required this.height,
    required this.enabled,
    required this.background,
    required this.onPressed,
    required this.child,
    this.border,
    this.lifted = false,
  });

  final double height;
  final bool enabled;
  final Color background;
  final BoxBorder? border;
  final VoidCallback onPressed;
  final Widget child;

  /// Filled buttons carry a shadow tinted from their own fill, so the primary action sits above
  /// the card it is on. Outlined buttons stay flat — a border and a shadow together read as two
  /// separate attempts to say the same thing.
  final bool lifted;

  @override
  State<_ButtonSurface> createState() => _ButtonSurfaceState();
}

class _ButtonSurfaceState extends State<_ButtonSurface> {
  bool _down = false;

  static const _press = Duration(milliseconds: 110);

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(Dimens.radiusButton);
    final lift = widget.lifted && widget.enabled;

    return AnimatedScale(
      // Small enough to feel like the surface gave way under the finger rather than that the
      // layout moved. Anything past ~4% starts to look like a bug on a 64px button.
      scale: _down ? 0.975 : 1,
      duration: _press,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _press,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: lift
              ? [
                  BoxShadow(
                    color: widget.background.withValues(alpha: _down ? 0.18 : 0.28),
                    blurRadius: _down ? 8 : 16,
                    offset: Offset(0, _down ? 2 : 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: widget.background,
          borderRadius: shape,
          child: InkWell(
            borderRadius: shape,
            onTap: widget.enabled
                ? () {
                    // Confirming a dose is the app's most consequential tap; a physical tick makes
                    // it land for a user who may not trust that the screen registered it.
                    HapticFeedback.selectionClick();
                    widget.onPressed();
                  }
                : null,
            onTapDown: widget.enabled ? (_) => _set(true) : null,
            onTapUp: widget.enabled ? (_) => _set(false) : null,
            onTapCancel: widget.enabled ? () => _set(false) : null,
            child: Container(
              height: widget.height < Dimens.tapMin ? Dimens.tapMin : widget.height,
              decoration: BoxDecoration(borderRadius: shape, border: widget.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({
    required this.leftAligned,
    required this.label,
    this.leading,
    this.trailing,
  });

  final bool leftAligned;
  final Widget label;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: leftAligned ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: leftAligned ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          leftAligned ? Flexible(child: label) : Flexible(child: label),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      );
}

/// How long the patient must hold before a high-risk dose is confirmed.
const Duration _holdDuration = Duration(milliseconds: 900);

/// Press-and-hold confirmation for high-risk medicines. It fills as you hold, names what it wants
/// while you are holding, and says so again if you let go too early — a plain tap is the one
/// interaction this control is most likely to be met with, and it must never fail silently.
///
/// Assistive technology gets a plain activation: a screen-reader double-tap is already deliberate,
/// so making those users hold would gate them without adding any safety.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.onConfirm,
    this.height = Dimens.doseConfirm,
    this.container,
    this.content,
    this.progress,
  });

  final VoidCallback onConfirm;
  final double height;
  final Color? container;
  final Color? content;
  final Color? progress;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill =
      AnimationController(vsync: this, duration: _holdDuration)..addStatusListener(_onStatus);

  bool _pressed = false;
  bool _releasedEarly = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _confirmed = true;
    HapticFeedback.heavyImpact();
    _fill.value = 0;
    widget.onConfirm();
  }

  void _onPressStart() {
    setState(() {
      _releasedEarly = false;
      _confirmed = false;
      _pressed = true;
    });
    _fill.forward(from: 0);
  }

  void _onPressEnd() {
    if (!_pressed) return;
    setState(() {
      _pressed = false;
      // A tap so brief that the fill never left zero is precisely the case this control exists to
      // answer, so the hint keys off "was there a press at all", not off how far the fill got.
      _releasedEarly = !_confirmed;
    });
    _fill.animateBack(0, duration: const Duration(milliseconds: 160));
    if (_releasedEarly) {
      Future<void>.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _releasedEarly) setState(() => _releasedEarly = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final containerColor = widget.container ?? colors.calm;
    final contentColor = widget.content ?? colors.paper;
    final progressColor = widget.progress ?? colors.calmD;

    final idleLabel = context.tr('চেপে ধরুন', 'Hold to confirm');
    final label = _pressed
        ? context.tr('ধরে রাখুন…', 'Keep holding…')
        : _releasedEarly
            ? context.tr('আরেকটু ধরে রাখুন', 'Hold a little longer')
            : idleLabel;

    final shape = BorderRadius.circular(Dimens.radiusButton);
    return Semantics(
      button: true,
      label: idleLabel,
      onTap: widget.onConfirm,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _onPressStart(),
        onTapUp: (_) => _onPressEnd(),
        onTapCancel: _onPressEnd,
        child: ClipRRect(
          borderRadius: shape,
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.height < Dimens.tapMin ? Dimens.tapMin : widget.height,
            ),
            color: containerColor,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _fill.value,
                      child: ColoredBox(color: progressColor),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      label,
                      style: context.type.buttonLabel.copyWith(color: contentColor),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
