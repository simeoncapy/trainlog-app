import 'package:flutter/material.dart';

/// A rounded card that groups a list of widgets with auto-inserted dividers.
/// The divider indent aligns with the title column (16 + 40 + 12 = 68).
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            // Only insert a divider if this isn't the last child and the child
            // is not a SettingsTile with noDivider == true.
            if (i < children.length - 1 &&
                !(children[i] is SettingsTile && (children[i] as SettingsTile).noDivider))
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 0,
                color: cs.outline,
              ),
          ],
        ],
      ),
    );
  }
}

/// A single settings row with a neutral icon badge, bold title,
/// optional subtitle, and an optional trailing widget.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool noDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.noDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fgColor = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);
    final cs = Theme.of(context).colorScheme;
    final disabledColor = cs.onSurface.withValues(alpha: 0.38);

    final effectiveFg = enabled ? fgColor : disabledColor;
    final effectiveBg = enabled ? bgColor : cs.onSurface.withValues(alpha: 0.12);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveFg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: enabled ? null : disabledColor,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabled ? cs.onSurfaceVariant : disabledColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
