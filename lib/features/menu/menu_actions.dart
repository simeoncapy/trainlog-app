import 'package:flutter/widgets.dart';
import 'package:trainlog_app/navigation/nav_models.dart';

/// What the menu's rows do, given by the shell and shared by both views.
class MenuActions {
  const MenuActions({
    required this.onClose,
    required this.onSettingsTap,
    required this.onPageTap,
    required this.onInboxTap,
    required this.onTrainlogStatusTap,
    required this.onLogout,
    required this.onShareProfile,
    this.scrollController,
  });

  final VoidCallback onClose;
  final VoidCallback onSettingsTap;
  final void Function(AppPageId id) onPageTap;
  final VoidCallback onInboxTap;
  final VoidCallback onTrainlogStatusTap;

  /// Closes the menu, logs out and says so.
  final VoidCallback onLogout;

  /// Shares the link to the user's public profile.
  final VoidCallback onShareProfile;

  /// Controller of the menu's scroll view. On Apple the menu is shown in a
  /// sheet, which passes its controller so a pull-down at the top dismisses it.
  final ScrollController? scrollController;
}
