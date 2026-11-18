import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_nav_bar_theme.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassTab, GlassTabBar, GlassTabBarExtraButton;
import 'package:trainlog_app/utils/platform_utils.dart';

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

  /// Label shown under the menu button ("Home").
  final String? menuLabel;

  /// Apple only: the current page's main action (e.g. "New trip"), shown as a
  /// round prominent glass button at the trailing end of the tab bar. The
  /// capsule takes the full width when there is none.
  final AppPrimaryAction? trailingAction;

  const AdaptiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onMenuTap,
    this.menuLabel,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return _GlassTabBar(
        currentIndex: currentIndex,
        items: items,
        onTap: onTap,
        onMenuTap: onMenuTap,
        menuLabel: menuLabel,
        trailingAction: trailingAction,
      );
    }

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
      child: onMenuTap != null ? _rowWithGap(navColors) : _rowFull(navColors),
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
        // Gap in the centre for the protruding button, with its label at the
        // same height as the other tabs' labels.
        SizedBox(
          width: 60,
          child: GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Text(
                  menuLabel ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: navColors.inactive,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
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
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icon/trainlog_icon_foreground_only.svg',
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(
              AppColors.amber,
              BlendMode.srcIn,
            ),
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

// ── Apple: Liquid Glass tab bar ───────────────────────────────────────────────

const double _kGlassBarHeight = 62.0;

/// iOS 26 tab bar, drawn by liquid_glass_widgets' [GlassTabBar]: a floating
/// glass capsule whose lens follows the finger, magnifies and refracts the
/// content behind it. The Trainlog menu ("Home", the amber logo on navy) is
/// the middle item; tapping it opens the menu instead of selecting it. The
/// trailing round glass button holds the current page's main action ("New
/// trip" on Map and Trips), and disappears on pages without one.
class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback? onMenuTap;
  final String? menuLabel;
  final AppPrimaryAction? trailingAction;

  const _GlassTabBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.onMenuTap,
    required this.menuLabel,
    required this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Amber is too light on white glass for small labels: use the pressed
    // amber in light mode, the regular one in dark mode.
    final active = isDark ? AppColors.amber : AppColors.amberDk;
    final inactive = isDark ? AppColors.darkText : AppColors.lightText;

    // Sit close to the bottom edge like the system bar does, while staying
    // clear of the home indicator.
    final bottom = mq.padding.bottom > 0 ? mq.padding.bottom - 10 : 12.0;

    // The menu takes the middle slot: tabs 0..half-1, menu, then the rest.
    final hasMenu = onMenuTap != null;
    final half = items.length ~/ 2;
    final menuSlot = hasMenu ? half : -1;
    final selectedSlot =
        hasMenu && currentIndex >= half ? currentIndex + 1 : currentIndex;

    GlassTab tab(BottomNavigationBarItem item) => GlassTab(
          icon: item.icon,
          activeIcon: item.activeIcon,
          label: item.label,
        );

    final tabs = <GlassTab>[
      for (int i = 0; i < (hasMenu ? half : items.length); i++) tab(items[i]),
      if (hasMenu)
        GlassTab(
          icon: const _MenuLogo(),
          label: menuLabel ?? '',
          semanticLabel: (menuLabel?.isNotEmpty ?? false)
              ? menuLabel
              : MaterialLocalizations.of(context).showMenuTooltip,
        ),
      if (hasMenu)
        for (int i = half; i < items.length; i++) tab(items[i]),
    ];

    final action = trailingAction;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: GlassTabBar.bottom(
        tabs: tabs,
        selectedIndex: selectedSlot,
        onTabSelected: (slot) {
          if (slot == menuSlot) {
            onMenuTap!();
          } else {
            onTap(hasMenu && slot > menuSlot ? slot - 1 : slot);
          }
        },
        horizontalPadding: 20,
        verticalPadding: 8,
        barHeight: _kGlassBarHeight,
        spacing: 10,
        iconSize: 24,
        labelFontSize: 10,
        selectedIconColor: active,
        selectedLabelColor: active,
        unselectedIconColor: inactive,
        unselectedLabelColor: inactive,
        extraButton: action == null
            ? null
            : GlassTabBarExtraButton(
                icon: Icon(action.icon),
                iconColor: active,
                label: action.tooltip ?? action.label ?? '',
                onTap: action.onPressed,
                size: _kGlassBarHeight,
              ),
      ),
    );
  }
}

/// The Trainlog logo on a small navy disc, used as the menu tab's icon.
class _MenuLogo extends StatelessWidget {
  const _MenuLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 26,
      child: _BrandGlassFill(
        child: SvgPicture.asset(
          'assets/icon/trainlog_icon_foreground_only.svg',
          width: 16,
          height: 16,
          colorFilter: const ColorFilter.mode(
            AppColors.amber,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// Navy wash filling the round menu button so it reads as the brand mark
/// while the glass rim and sheen stay visible on top.
class _BrandGlassFill extends StatelessWidget {
  final Widget child;
  const _BrandGlassFill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy.withValues(alpha: 0.92),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

