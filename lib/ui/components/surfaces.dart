import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Card shadow (README): calm cards get a soft ink shadow; urgent cards get a stronger amber one.
List<BoxShadow> nbCardShadow({bool elevated = false}) => [
      // Wider and fainter than the design's original: a card should read as lifted without the
      // shadow itself being visible. The contact shadow underneath keeps the edge from floating.
      BoxShadow(
        color: elevated ? nbColors.warm.withValues(alpha: 0.16) : nbColors.ink.withValues(alpha: 0.05),
        blurRadius: elevated ? 28 : 22,
        offset: Offset(0, elevated ? 8 : 6),
      ),
      BoxShadow(
        color: nbColors.ink.withValues(alpha: 0.03),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];

/// Standard white card.
class NbCard extends StatelessWidget {
  const NbCard({
    super.key,
    required this.child,
    this.padding = Dimens.cardPadding,
    this.radius = Dimens.radiusCard,
    this.onTap,
    this.border,
    this.background,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget child;
  final double padding;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Color? background;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final body = Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [child],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? context.colors.card,
        borderRadius: shape,
        border: border,
        boxShadow: nbCardShadow(),
      ),
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: shape, onTap: onTap, child: body),
            ),
    );
  }
}

/// Due-now / urgent card: 2px warm border + amber shadow.
class UrgentCard extends StatelessWidget {
  const UrgentCard({
    super.key,
    required this.child,
    this.padding = Dimens.cardPadding,
    this.radius = Dimens.radiusCard,
  });

  final Widget child;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: context.colors.warm, width: 2),
          boxShadow: nbCardShadow(elevated: true),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [child],
          ),
        ),
      );
}

/// A flat tinted panel (sage / calm-soft / warm-soft info panels). No shadow.
class TintPanel extends StatelessWidget {
  const TintPanel({
    super.key,
    required this.background,
    required this.child,
    this.padding = Dimens.cardPadding,
    this.radius = Dimens.radiusCard,
    this.border,
  });

  final Color background;
  final Widget child;
  final double padding;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: border,
        ),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [child],
        ),
      );
}
