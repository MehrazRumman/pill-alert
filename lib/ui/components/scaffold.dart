import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

import 'surfaces.dart';

/// Header bar for pushed screens: back chevron + title on a card surface with a hairline bottom
/// border.
class NirbhorTopBar extends StatelessWidget {
  const NirbhorTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.card,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.denseHeaderPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  if (onBack != null) ...[
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
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: context.type.header.copyWith(color: colors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
          Container(height: 1, color: colors.line),
        ],
      ),
    );
  }
}

/// One bottom-nav tab.
class NavTab {
  const NavTab(this.route, this.icon, this.labelBn, this.labelEn);

  final String route;
  final IconData icon;
  final String labelBn;
  final String labelEn;
}

/// Four-tab bottom nav. A floating pill rather than a flat edge-to-edge bar: it sits on the paper
/// with a gap beneath it, and a single calm-filled indicator slides between tabs instead of
/// appearing and disappearing under each one.
///
/// Every label stays visible in both states. Collapsing inactive tabs to bare icons is the usual
/// way to make a bar like this feel lighter, and it is exactly the wrong trade here — the word is
/// what an elderly user reads, and it is already the smallest type in the app.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.tabs,
    required this.currentRoute,
    required this.onSelect,
  });

  final List<NavTab> tabs;
  final String? currentRoute;
  final ValueChanged<NavTab> onSelect;

  static const _slide = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = tabs.indexWhere((t) => t.route == currentRoute);

    return ColoredBox(
      color: colors.paper,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(Dimens.radiusNavBar),
              boxShadow: nbCardShadow(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / tabs.length;
                  return Stack(
                    children: [
                      // The indicator. Drawn once and moved, so switching tabs reads as one
                      // object travelling rather than two separate fills blinking.
                      if (index >= 0)
                        AnimatedPositioned(
                          duration: _slide,
                          curve: _curve,
                          left: index * itemWidth,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.calm,
                              borderRadius: BorderRadius.circular(Dimens.radiusNavPill),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          for (final tab in tabs)
                            Expanded(
                              child: _NavItem(
                                tab: tab,
                                active: currentRoute == tab.route,
                                onTap: () => onSelect(tab),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.active, required this.onTap});

  final NavTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Cross-faded rather than switched, so the colour change lands with the sliding indicator
    // instead of a frame ahead of it.
    final target = active ? colors.card : colors.ink3;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.radiusNavPill),
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          height: Dimens.bottomNavItem,
          child: TweenAnimationBuilder<Color?>(
            duration: BottomNavBar._slide,
            curve: BottomNavBar._curve,
            tween: ColorTween(end: target),
            builder: (context, color, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The icon grows very slightly into the active state, so the indicator arriving
                // and the tab responding read as one movement.
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: BottomNavBar._slide,
                  curve: BottomNavBar._curve,
                  child: Icon(tab.icon, size: Dimens.navIcon, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(tab.labelBn, tab.labelEn),
                  // The meta role, not the status-pill role. A pill's fill already carries its
                  // meaning, so 12px is defensible there; in the nav the word *is* the meaning, and
                  // it was the smallest type in an app built for elderly eyes.
                  style: context.type.meta.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
