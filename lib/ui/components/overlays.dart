import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'buttons.dart';

/// Bottom-sheet container: card surface, 24px top corners, grab handle.
///
/// The full-screen scrim the Compose original drew by hand is Flutter's modal barrier here —
/// [showNbSheet] sets it to the same rgba(27,42,38,0.42), and tapping it dismisses.
class SheetSurface extends StatelessWidget {
  const SheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colors.card, borderRadius: NbShapes.sheetTop),
      padding: EdgeInsets.fromLTRB(
        Dimens.sheetPadding,
        Dimens.sheetPadding,
        Dimens.sheetPadding,
        Dimens.sheetPadding + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Shows [builder] in a Nirbhor bottom sheet with the design's scrim.
Future<T?> showNbSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1B2A26), // rgba(27,42,38,0.42)
      isScrollControlled: true,
      builder: (context) => SheetSurface(child: builder(context)),
    );

/// Undo toast (README > 4f): dark calm-d fill, radius 14, check tile + message + undo button,
/// pinned 16px from the bottom. Auto-dismiss (~5s) is the caller's job.
class UndoToast extends StatelessWidget {
  const UndoToast({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: colors.calmD,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.calm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check, size: 20, color: colors.paper),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: context.type.cardTitleSecondary.copyWith(color: colors.paper),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    actionLabel,
                    style: context.type.buttonLabel.copyWith(color: colors.markCalmOnDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.warmSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 25, color: colors.warmD),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent confirmation for destructive or irreversible actions. Resolves true on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x6B1B2A26),
    builder: (context) => _DialogShell(
      children: [
        Text(title, style: context.type.header.copyWith(color: colors.ink)),
        const SizedBox(height: 8),
        Text(message, style: context.type.body.copyWith(color: colors.ink2)),
        const SizedBox(height: 22),
        PrimaryButton(
          text: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          height: 56,
          container: colors.warmD,
          content: colors.paper,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          text: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          height: 56,
        ),
      ],
    ),
  );
  return result ?? false;
}

/// What the patient chose in the missed-dose recovery dialog.
enum MissedDoseChoice { taken, skip, details }

/// Recovery choices shown when a missed dose is selected from the timeline.
Future<MissedDoseChoice?> showMissedDoseDialog(
  BuildContext context, {
  required String medicineName,
}) {
  final colors = context.colors;
  return showDialog<MissedDoseChoice>(
    context: context,
    barrierColor: const Color(0x6B1B2A26),
    builder: (context) => _DialogShell(
      children: [
        Text(
          context.tr('$medicineName আপডেট করবেন?', 'Update $medicineName?'),
          style: context.type.header.copyWith(color: colors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'এই ডোজটি বাদ পড়েছে হিসেবে দেখানো হয়েছে। আজকের হিসাব ঠিক রাখতে কী হয়েছিল তা বেছে নিন।',
            "This dose was marked missed. Choose what happened so today's count stays accurate.",
          ),
          style: context.type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          text: context.tr('খেয়েছি হিসেবে দিন', 'Mark as taken'),
          onPressed: () => Navigator.of(context).pop(MissedDoseChoice.taken),
          height: 56,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          text: context.tr('এই ডোজ বাদ দিন', 'Skip this dose'),
          onPressed: () => Navigator.of(context).pop(MissedDoseChoice.skip),
          height: 56,
          borderColor: colors.warm,
          content: colors.warmD,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(Dimens.tapMin),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(MissedDoseChoice.details),
            child: Text(
              context.tr('ওষুধের বিস্তারিত দেখুন', 'View medicine details'),
              style: context.type.buttonLabel.copyWith(color: colors.calm),
            ),
          ),
        ),
      ],
    ),
  );
}
