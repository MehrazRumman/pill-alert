import 'package:flutter/material.dart';

import '../../theme/theme.dart';

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

/// Four-tab bottom nav. Active item gets calm text on a calm-soft radius-12 pill.
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: colors.line),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
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
            ),
          ),
        ],
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
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: Dimens.bottomNavItem,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: active ? colors.calmSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Icon(
                  tab.icon,
                  size: Dimens.navIcon,
                  color: active ? colors.calm : colors.ink3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.isBangla ? tab.labelBn : tab.labelEn,
                style: context.type.statusPill.copyWith(
                  color: active ? colors.calm : colors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
