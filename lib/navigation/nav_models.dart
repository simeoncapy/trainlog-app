import 'package:flutter/widgets.dart';

class AppPrimaryAction {
  final IconData icon;
  final String? tooltip;
  final String? label;
  final VoidCallback onPressed;

  const AppPrimaryAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.label,
  });

  bool get isExtended => label != null && label!.trim().isNotEmpty;
}

enum AppPageId {
  map,
  trips,
  ranking,
  statistics,
  coverage,
  tags,
  tickets,
  friends,
  smartPrerecorder,
  settings,
  about,
}

class AppPage {
  final AppPageId id;
  final Widget view;
  final String Function(BuildContext context) titleBuilder;
  final IconData? icon;

  const AppPage({
    required this.id,
    required this.view,
    required this.titleBuilder,
    this.icon,
  });
}
