import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// One choice of a Liquid Glass menu: a check mark when [checked], the
/// [label], and an optional [trailing] icon. With a [leading] icon (e.g. the
/// vehicles' icons), the icon takes the leading slot and the check mark
/// moves to the trailing side.
class AppMenuEntry {
  const AppMenuEntry({
    required this.label,
    required this.onTap,
    this.checked = false,
    this.trailing,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final bool checked;
  final Widget? trailing;
  final Widget? leading;
}

/// A group of [AppMenuEntry]s, with an optional caption above it (as in the
/// sort menus of Files or Mail). Sections are separated by a divider.
class AppMenuSection {
  const AppMenuSection({this.title, required this.entries});

  final String? title;
  final List<AppMenuEntry> entries;
}

List<Widget> _menuItems(BuildContext context, List<AppMenuSection> sections) {
  final label = CupertinoColors.label.resolveFrom(context);
  final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
  final caption = Theme.of(context).textTheme.bodySmall?.copyWith(
    color: secondary,
    letterSpacing: 0,
  );
  return [
    for (var i = 0; i < sections.length; i++) ...[
      if (i > 0) const lg.GlassMenuDivider(),
      if (sections[i].title != null)
        // The package's caption is upper case; iOS menus write it as is.
        lg.GlassMenuLabel(
          height: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(sections[i].title!, style: caption),
          ),
        ),
      for (final e in sections[i].entries)
        lg.GlassMenuItem(
          title: e.label,
          maxLines: 1,
          titleStyle: TextStyle(fontSize: 17, color: label),
          // Same slot width with or without the check, so labels line up.
          icon: SizedBox(
            width: 20,
            child: e.leading != null
                ? Center(child: e.leading)
                : e.checked
                ? const Icon(CupertinoIcons.checkmark, size: 17)
                : null,
          ),
          iconSize: 17,
          trailing: e.leading != null && e.checked
              ? const Icon(CupertinoIcons.checkmark, size: 17)
              : e.trailing,
          semanticsChecked: e.checked,
          onTap: e.onTap,
        ),
    ],
  ];
}

/// A [FilterCapsule] with a chevron that opens a Liquid Glass menu morphing
/// out of it (e.g. the Ranking page's "Vehicle" category).
class GlassMenuCapsule extends StatefulWidget {
  const GlassMenuCapsule({
    super.key,
    required this.label,
    required this.selected,
    required this.sections,
    required this.semanticLabel,
    this.leading,
    this.leadingColor,
    this.selectedColor,
    this.menuWidth = 230,
  });

  final String label;
  final bool selected;
  final List<AppMenuSection> sections;
  final String semanticLabel;
  final IconData? leading;
  final Color? leadingColor;
  final Color? selectedColor;
  final double menuWidth;

  @override
  State<GlassMenuCapsule> createState() => _GlassMenuCapsuleState();
}

class _GlassMenuCapsuleState extends State<GlassMenuCapsule> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      controller: _menu,
      triggerBuilder: (context, toggle) => FilterCapsule(
        label: widget.label,
        selected: widget.selected,
        onTap: toggle,
        leading: widget.leading,
        leadingColor: widget.leadingColor,
        selectedColor: widget.selectedColor,
        trailing: CupertinoIcons.chevron_down,
        semanticLabel: widget.semanticLabel,
      ),
      menuWidth: widget.menuWidth,
      menuAlignment: lg.GlassMenuAlignment.topLeft,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      menuSemanticLabel: widget.semanticLabel,
      items: _menuItems(context, widget.sections),
    );
  }
}

/// An icon for a [GlassButtonGroup] that opens a Liquid Glass menu (e.g. the
/// sort menu of a navigation bar).
class GlassMenuGroupItem extends StatefulWidget {
  const GlassMenuGroupItem({
    super.key,
    required this.icon,
    required this.sections,
    required this.semanticLabel,
    this.menuWidth = 250,
  });

  final IconData icon;
  final List<AppMenuSection> sections;
  final String semanticLabel;
  final double menuWidth;

  @override
  State<GlassMenuGroupItem> createState() => _GlassMenuGroupItemState();
}

class _GlassMenuGroupItemState extends State<GlassMenuGroupItem> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      controller: _menu,
      semanticLabel: widget.semanticLabel,
      trigger: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          widget.icon,
          size: 20,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
      menuWidth: widget.menuWidth,
      menuAlignment: lg.GlassMenuAlignment.topRight,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      menuSemanticLabel: widget.semanticLabel,
      items: _menuItems(context, widget.sections),
    );
  }
}

/// A round glass icon button (the app's [GlassIconButton], 44 pt) that opens
/// a Liquid Glass menu, for a single action where a [GlassButtonGroup] of one
/// item would be a narrow capsule.
class GlassMenuIconButton extends StatefulWidget {
  const GlassMenuIconButton({
    super.key,
    required this.icon,
    required this.sections,
    required this.semanticLabel,
    this.menuWidth = 250,
  });

  final IconData icon;
  final List<AppMenuSection> sections;
  final String semanticLabel;
  final double menuWidth;

  @override
  State<GlassMenuIconButton> createState() => _GlassMenuIconButtonState();
}

class _GlassMenuIconButtonState extends State<GlassMenuIconButton> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      controller: _menu,
      triggerBuilder: (context, toggle) => GlassIconButton(
        icon: widget.icon,
        shadow: false,
        tooltip: widget.semanticLabel,
        onPressed: toggle,
      ),
      menuWidth: widget.menuWidth,
      menuAlignment: lg.GlassMenuAlignment.topRight,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      menuSemanticLabel: widget.semanticLabel,
      items: _menuItems(context, widget.sections),
    );
  }
}
