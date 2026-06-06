import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/app/app_nav_bar_theme.dart';

/// Height of the nav bar pill + its top/bottom padding, excluding the system
/// safe area. Both shells expose this value as MediaQuery.padding.bottom so
/// scrollable pages can add the right clearance without knowing about the nav.
const double kNavBarClearance = 80.0;

/// Extra vertical space above the pill that the center menu button occupies.
const double _kMenuButtonOverhang = 22.0;

class AdaptiveBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  /// When provided, a circular menu button is rendered in the centre of the
  /// bar, protruding slightly above the pill. The [items] list must have
  /// exactly 4 entries (2 left + 2 right).
  final VoidCallback? onMenuTap;

  const AdaptiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;
    final mq = MediaQuery.of(context);

    final pill = Container(
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
      child: onMenuTap != null
          ? _rowWithGap(navColors)
          : _rowFull(navColors),
    );

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: mq.padding.bottom + 8,
        top: onMenuTap != null ? _kMenuButtonOverhang : 8,
      ),
      child: onMenuTap != null
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                pill,
                Positioned(
                  top: -_kMenuButtonOverhang,
                  child: _MenuButton(onTap: onMenuTap!),
                ),
              ],
            )
          : pill,
    );
  }

  Widget _rowFull(AppNavBarColors navColors) {
    return Row(
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
    );
  }

  Widget _rowWithGap(AppNavBarColors navColors) {
    final left = items.sublist(0, 2);
    final right = items.sublist(2, 4);
    return Row(
      children: [
        for (int i = 0; i < left.length; i++)
          Expanded(
            child: _NavBarItem(
              item: left[i],
              isSelected: i == currentIndex,
              activeColor: navColors.active,
              inactiveColor: navColors.inactive,
              onTap: () => onTap(i),
            ),
          ),
        // Gap in the centre for the protruding button
        const SizedBox(width: 60),
        for (int i = 0; i < right.length; i++)
          Expanded(
            child: _NavBarItem(
              item: right[i],
              isSelected: i + 2 == currentIndex,
              activeColor: navColors.active,
              inactiveColor: navColors.inactive,
              onTap: () => onTap(i + 2),
            ),
          ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.amber, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icon/trainlog_icon_foreground_only.svg',
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(AppColors.amber, BlendMode.srcIn),
          ),
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
