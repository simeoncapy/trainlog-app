import 'package:flutter/material.dart';

/// Data for a single row in a [MenuBlock].
class MenuItemData {
  final IconData icon;
  final Color iconBg;
  final String label;

  /// Override the label colour — useful for destructive actions (red).
  final Color? labelColor;

  final VoidCallback onTap;

  /// Destructive items show no trailing chevron.
  final bool isDestructive;

  const MenuItemData({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.isDestructive = false,
  });
}
