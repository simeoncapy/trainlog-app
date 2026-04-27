import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/trainlog/inbox_page.dart';
import 'package:trainlog_app/features/trainlog/trainlog_status_page.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

enum TrainlogStatus {
  ok, trouble, down;

  Color toColor() {
    switch(this) {
      case ok:
        return Colors.green;
      case trouble:
        return Colors.orange;
      case down:
        return Colors.red;
    }
  }

  String toEmoji() {
    switch(this) {
      case ok:
        return "🟢";
      case trouble:
        return "⚠️";
      case down:
        return "❌";
    }
  }

  Icon toIcon(double? size) {
    switch(this) {
      case ok:
        return Icon( AdaptiveIcons.ok, size: size, color: ok.toColor(),);
      case trouble:
        return Icon( AdaptiveIcons.warning, size: size, color: trouble.toColor(),);
      case down:
        return Icon( AdaptiveIcons.error, size: size, color: down.toColor(),);
    }
  }
}

class MenuHeader extends StatefulWidget {
  const MenuHeader({super.key});

  @override
  State<MenuHeader> createState() => _MenuHeaderState();
}

class _MenuHeaderState extends State<MenuHeader> {
  final _status = TrainlogStatus.ok;
  int? _newMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getNewsCountAndStatus();
    });
  }

  Future<void> _getNewsCountAndStatus() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    final count = await trainlog.fetchNewsCount(settings);
  
    if (mounted) {
    setState(() {
      _newMessage = count;
    });
  }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<TrainlogProvider>();
    final isConnected = auth.isAuthenticated;
    final settings = context.read<SettingsProvider>();
    final trips = context.read<TripsProvider>();
    final scaffMsg = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);    

    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/logo/t_logo.svg",
                height: 48,
              ),
              SizedBox(width: 12,),         
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trainlog',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Berlin Sans FB"
                    ),
                  ),
                  const SizedBox(height: 8),              
             
                  if (isConnected) ...[
                    Text(loc.menuHello(auth.username ?? ''),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _logoutButtonHelper(loc, context, settings, trips, scaffMsg),
              const Spacer(),
              //_statusButtonHelper(loc, context, theme),
              _statusIconButtonHelper(theme),
              const SizedBox(width: 10,),
              _mailboxButtonHelper(loc, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutButtonHelper(AppLocalizations loc, BuildContext context, SettingsProvider settings, TripsProvider trips, ScaffoldMessengerState scaffMsg) {
    return AdaptiveButton.build(
      context: context,
      size: AdaptiveButton.small,
      icon: AdaptiveIcons.logout,
      label: Text(loc.logoutButton),
      onPressed: () async {
        await context.read<TrainlogProvider>().logout(settings, trips);
        scaffMsg.showSnackBar(
          SnackBar(content: Text(loc.loggedOut)),
        );
      },
    );
  }

  Widget _statusIconButtonHelper(ThemeData theme) {
    return IconButton(
          icon: _status.toIcon(14),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            _openPage(TrainlogStatusPage.pageTitle(context), const TrainlogStatusPage());
          },
        );
  }

  Widget _mailboxButtonHelper(AppLocalizations loc, ThemeData theme) {
    bool isNewMessage = (_newMessage != null && _newMessage! > 0);
    String badgeLabel = isNewMessage ? (_newMessage! > 9 ? "9+" : _newMessage.toString()) 
                                     : "";

    return Badge(
      isLabelVisible: isNewMessage,
      backgroundColor: Colors.red,
      smallSize: 10, // Small dot size
      label: Text(badgeLabel),
      textColor: Colors.white,
      child: IconButton(
        icon: Icon(AdaptiveIcons.inbox),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
        ),
        onPressed: () {
          _openPage(InboxPage.pageTitle(context), const InboxPage());
        },
      ),
    );
  }

  void _openPage(String title, Widget page) {
    if(AppPlatform.isApple) {
      final navBg = CupertinoTheme.of(context).scaffoldBackgroundColor;
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: navBg,
              middle: Text(title),
            ),
            child: page,
          ),
        ),
      );
    } else {
      Navigator.pop(context); // close the menu before opening the page
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => null,
          child: page,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ));
    }
  }
}