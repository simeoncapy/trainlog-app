import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/menu/cupertino/menu_cupertino_view.dart';
import 'package:trainlog_app/features/menu/material/menu_material_view.dart';
import 'package:trainlog_app/features/menu/menu_actions.dart';
import 'package:trainlog_app/features/menu/menu_controller.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/ui/design.dart';

/// The "You" menu: a full-screen page on Android, a sheet on iOS. Provides
/// [AppMenuController] and picks the view.
class FullScreenMenuPage extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSettingsTap;
  final void Function(AppPageId id) onPageTap;
  final VoidCallback onInboxTap;
  final VoidCallback onTrainlogStatusTap;

  /// Controller of the menu's scroll view. On Apple the menu is shown in a
  /// sheet, which passes its controller so a pull-down at the top dismisses it.
  final ScrollController? scrollController;

  /// Shares the public profile link; the system share sheet by default.
  final void Function(Uri url)? onShareProfile;

  const FullScreenMenuPage({
    super.key,
    required this.onClose,
    required this.onSettingsTap,
    required this.onPageTap,
    required this.onInboxTap,
    required this.onTrainlogStatusTap,
    this.scrollController,
    this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AppMenuController(
        trainlog: c.read<TrainlogProvider>(),
        settings: c.read<SettingsProvider>(),
        trips: c.read<TripsProvider>(),
      )..load(),
      child: Builder(
        builder: (context) {
          final actions = MenuActions(
            onClose: onClose,
            onSettingsTap: onSettingsTap,
            onPageTap: onPageTap,
            onInboxTap: onInboxTap,
            onTrainlogStatusTap: onTrainlogStatusTap,
            scrollController: scrollController,
            onShareProfile: () {
              final url = context.read<AppMenuController>().publicProfileUrl;
              final share = onShareProfile;
              if (share != null) return share(url);
              SharePlus.instance.share(ShareParams(uri: url));
            },
            onLogout: () async {
              final loc = AppLocalizations.of(context)!;
              final controller = context.read<AppMenuController>();
              onClose();
              await controller.logout();
              AdaptiveInformationMessage.showInfo(loc.loggedOut);
            },
          );
          return PlatformView(
            material: (_) => MenuMaterialView(actions: actions),
            cupertino: (_) => MenuCupertinoView(actions: actions),
          );
        },
      ),
    );
  }
}
