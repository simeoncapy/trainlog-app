import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/inbox_page.dart';
import 'package:trainlog_app/pages/trainlog_status_page.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/auth_dialog.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

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
    final scaffMsg = ScaffoldMessenger.of(context);
    final trainlog = context.read<TrainlogProvider>();
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
              
                  if (auth.loading) const CircularProgressIndicator(),
              
                  if (isConnected) ...[
                    Text(loc.menuHello(auth.username ?? ''),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          if (!isConnected && !auth.loading) ...[ // Should not be displayed now, it's done by the welcome page
            _loginButtonHelper(loc, context, trainlog, settings, scaffMsg),
            const SizedBox(height: 8),
            _createAccountButtonHelper(loc, context, scaffMsg),
          ] else if (isConnected) ...[
            Row(
              children: [
                _logoutButtonHelper(loc, context, settings, scaffMsg),
                const Spacer(),
                //_statusButtonHelper(loc, context, theme),
                _statusIconButtonHelper(theme),
                const SizedBox(width: 10,),
                _mailboxButtonHelper(theme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ElevatedButton _logoutButtonHelper(AppLocalizations loc, BuildContext context, SettingsProvider settings, ScaffoldMessengerState scaffMsg) {
    return ElevatedButton.icon(
      icon: Icon(AdaptiveIcons.logout),
      label: Text(loc.logoutButton),
      onPressed: () async {
        await context.read<TrainlogProvider>().logout(settings: settings);
        scaffMsg.showSnackBar(
          SnackBar(content: Text(loc.loggedOut)),
        );
      },
    );
  }

  // ElevatedButton _statusButtonHelper(AppLocalizations loc, BuildContext context, ThemeData theme) {
  //   return ElevatedButton.icon(
  //     icon: _status.toIcon(14),
  //     label: Text("Status", style: TextStyle(fontSize: 11)),
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
  //       foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
  //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //       minimumSize: Size(0, 28),
  //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //     ),
  //     onPressed: () async {
  //       debugPrint("TODO");
  //     },
  //   );
  // }

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
            Navigator.pop(context); // close the menu before opening the page
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => ChangeNotifierProvider(
                create: (_) => null,
                child: const TrainlogStatusPage(),
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          },
        );
  }

  Widget _mailboxButtonHelper(ThemeData theme) {
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
          Navigator.pop(context); // close the menu before opening the page
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChangeNotifierProvider(
              create: (_) => null,
              child: const InboxPage(),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ));
        },
      ),
    );
  }

  ElevatedButton _createAccountButtonHelper(AppLocalizations loc, BuildContext context, ScaffoldMessengerState scaffMsg) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add_alt),
      label: Text(loc.createAccountButton),
      onPressed: () async {
        final result = await AuthDialog.show(
          context,
          type: AuthFormType.createAccount,
        );
        if (result != null) {
          // TODO: call your sign-up endpoint when available
          scaffMsg.showSnackBar(
            const SnackBar(content: Text('Account creation not implemented yet')),
          );
        }
      },
    );
  }

  ElevatedButton _loginButtonHelper(AppLocalizations loc, BuildContext context, TrainlogProvider trainlog, SettingsProvider settings, ScaffoldMessengerState scaffMsg) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: Text(loc.loginButton),
      onPressed: () async {
        final result = await AuthDialog.show(
          context,
          type: AuthFormType.login,
        );
        if (result != null) {
          final ok = await trainlog.login(
                username: result.username,
                password: result.password,
                settings: settings
              );
          final msg = ok
              ? 'Logged in as ${result.username}'
              : (trainlog.error ?? loc.connectionError);
          scaffMsg.showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );
  }
}