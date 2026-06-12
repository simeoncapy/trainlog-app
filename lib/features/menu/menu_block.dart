import 'package:flutter/material.dart';
import 'package:trainlog_app/features/menu/menu_item_data.dart';

/// A grouped list block used in the full-screen menu MENU section.
///
/// The caller builds and passes [items]; this widget only handles
/// layout, theming, and dividers — it has no knowledge of what the
/// items do.
class MenuBlock extends StatelessWidget {
  final List<MenuItemData> items;

  const MenuBlock({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(
              data: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16 + 28 + 12, // aligns with label start
                endIndent: 0,
                color: cs.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuItemData data;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    required this.data,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedTextColor = data.labelColor ?? cs.onSurface;
    final badgeCount = data.badgeCount ?? 0;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: resolvedTextColor,
                ),
              ),
            ),
            if (!data.isDestructive)
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
