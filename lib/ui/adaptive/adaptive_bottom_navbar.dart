import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_nav_bar_theme.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassTab, GlassTabBar, GlassTabBarExtraButton;
import 'package:trainlog_app/utils/platform_utils.dart';

/// Height of the nav bar pill + its top/bottom padding, excluding the system
/// safe area. Both shells expose this value as MediaQuery.padding.bottom so
/// scrollable pages can add the right clearance without knowing about the nav.
const double kNavBarClearance = 80.0;

/// Apple: size of the page's main action ("New trip"), the round amber
/// button floating above the tab bar's trailing menu button: the same size
/// as that menu button.
const double kNavBarActionSize = _kGlassBarHeight;

/// Apple: distance from the right edge to the main action button, which
/// is centred above the tab bar's trailing menu button.
const double kNavBarActionRight =
    _kGlassBarSidePadding + (_kGlassBarHeight - kNavBarActionSize) / 2;

/// Apple: distance from the bottom of the screen to the main action
/// button: 12 px above the glass capsule (not its padding), the same gap as
/// between the button and the map's recenter / follow capsule.
double navBarActionBottom(BuildContext context) =>
    _glassBarBottom(MediaQuery.of(context)) +
    _kGlassBarVerticalPadding +
    _kGlassBarHeight +
    12;

/// Extra vertical space above the pill that the center menu button occupies.
const double _kMenuButtonOverhang = 22.0;

class AdaptiveBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  /// When provided, a menu button ("Home") is added: on Android a circular
  /// button in the centre of the bar, protruding slightly above the pill (the
  /// [items] list must then have exactly 4 entries, 2 left + 2 right); on
  /// Apple the round glass button at the trailing end of the tab bar.
  final VoidCallback? onMenuTap;

  /// Label shown under the menu button ("Home").
  final String? menuLabel;

  const AdaptiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onMenuTap,
    this.menuLabel,
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
            // Same layout as _NavBarItem (24 px icon slot, 3 px gap, label),
            // with an empty icon slot under the protruding button, so the
            // label lines up exactly with the other tabs' labels.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const SizedBox(height: 3),
                Text(
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
              ],
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
const double _kGlassBarSidePadding = 20.0;

/// Space the glass tab bar keeps above and below its capsule.
const double _kGlassBarVerticalPadding = 8.0;

/// Gap under the glass tab bar: close to the bottom edge like the system bar,
/// while staying clear of the home indicator. viewPadding, not padding:
/// padding.bottom shrinks while the keyboard animates, which made this go
/// negative and broke the tab bar layout.
double _glassBarBottom(MediaQueryData mq) {
  final inset = mq.viewPadding.bottom;
  return inset > 0 ? (inset - 10).clamp(0.0, inset) : 12.0;
}

/// iOS 26 tab bar, drawn by liquid_glass_widgets' [GlassTabBar]: a floating
/// glass capsule whose lens follows the finger, magnifies and refracts the
/// content behind it. The capsule holds the tabs only; the Trainlog menu
/// ("Home", the amber logo on navy) is the round glass button at its
/// trailing end, the same on every page. The pages' own main action ("New
/// trip") floats above the menu button ([navBarActionBottom]).
class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback? onMenuTap;
  final String? menuLabel;

  const _GlassTabBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.onMenuTap,
    required this.menuLabel,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Amber is too light on white glass for small labels: use the pressed
    // amber in light mode, the regular one in dark mode.
    final active = isDark ? AppColors.amber : AppColors.amberDk;
    final inactive = isDark ? AppColors.darkText : AppColors.lightText;

    final bottom = _glassBarBottom(mq);

    final tabs = <GlassTab>[
      for (final item in items)
        GlassTab(
          icon: item.icon,
          activeIcon: item.activeIcon,
          label: item.label,
        ),
    ];

    final onMenu = onMenuTap;
    final menuSemantics = (menuLabel?.isNotEmpty ?? false)
        ? menuLabel!
        : MaterialLocalizations.of(context).showMenuTooltip;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: GlassTabBar.bottom(
        tabs: tabs,
        selectedIndex: currentIndex,
        onTabSelected: onTap,
        horizontalPadding: _kGlassBarSidePadding,
        verticalPadding: _kGlassBarVerticalPadding,
        barHeight: _kGlassBarHeight,
        spacing: 10,
        iconSize: 24,
        labelFontSize: 10,
        selectedIconColor: active,
        selectedLabelColor: active,
        unselectedIconColor: inactive,
        unselectedLabelColor: inactive,
        extraButton: onMenu == null
            ? null
            : GlassTabBarExtraButton(
                icon: const _MenuLogo(),
                label: menuSemantics,
                onTap: onMenu,
                size: _kGlassBarHeight,
              ),
      ),
    );
  }
}

/// The Trainlog logo on a navy disc, the menu button's icon.
class _MenuLogo extends StatelessWidget {
  const _MenuLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: _BrandGlassFill(
        child: SvgPicture.asset(
          'assets/icon/trainlog_icon_foreground_only.svg',
          width: 20,
          height: 20,
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

