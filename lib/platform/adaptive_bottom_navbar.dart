import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

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
    return _FloatingNavBar(
      currentIndex: currentIndex,
      items: items,
      onTap: onTap,
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;

    final isDark = AppPlatform.isApple
        ? CupertinoTheme.of(context).brightness == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    final activeColor = AppPlatform.isApple
        ? CupertinoTheme.of(context).primaryColor
        : Theme.of(context).colorScheme.primary;

    const inactiveColor = Color(0xFF8E8E93);

    final bgColor = isDark
        ? (AppPlatform.isApple ? const Color(0xFF1C1C1E) : const Color(0xFF1E1E2E))
        : Colors.white;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 8,
        top: 8,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
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
