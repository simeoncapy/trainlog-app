import 'package:flutter/material.dart';
import 'package:trainlog_app/app/app_nav_bar_theme.dart';

/// Height of the nav bar pill + its top/bottom padding, excluding the system
/// safe area. Both shells expose this value as MediaQuery.padding.bottom so
/// scrollable pages can add the right clearance without knowing about the nav.
const double kNavBarClearance = 80.0;

class AdaptiveBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const AdaptiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;
    final mq = MediaQuery.of(context);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: mq.padding.bottom + 8,
        top: 8,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: navColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: navColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavBarItem(
                  item: items[i],
                  isSelected: i == currentIndex,
                  activeColor: navColors.active,
                  inactiveColor: navColors.inactive,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavigationBarItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: color, size: 24),
            child: isSelected && item.activeIcon != item.icon
                ? item.activeIcon
                : item.icon,
          ),
          const SizedBox(height: 3),
          Text(
            item.label ?? '',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
