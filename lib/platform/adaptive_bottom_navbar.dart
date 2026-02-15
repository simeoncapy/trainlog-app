import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0..(items.length-1)
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
    if (AppPlatform.isApple) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        activeColor: CupertinoTheme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      );
    }

    // Material 3
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: item.icon,
            selectedIcon: item.activeIcon ?? item.icon,
            label: item.label ?? '',
          ),
      ],
    );
  }
}
