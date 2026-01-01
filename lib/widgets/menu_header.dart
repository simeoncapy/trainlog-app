import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/widgets/auth_dialog.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({super.key});

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
          if (!isConnected && !auth.loading) ...[
            _loginButtonHelper(loc, context, trainlog, settings, scaffMsg),
            const SizedBox(height: 8),
            _createAccountButtonHelper(loc, context, scaffMsg),
          ] else if (isConnected) ...[
            _logoutButtonHelper(loc, context, settings, scaffMsg),
          ],
        ],
      ),
    );
  }

  ElevatedButton _logoutButtonHelper(AppLocalizations loc, BuildContext context, SettingsProvider settings, ScaffoldMessengerState scaffMsg) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: Text(loc.logoutButton),
      onPressed: () async {
        await context.read<TrainlogProvider>().logout(settings: settings);
        scaffMsg.showSnackBar(
          SnackBar(content: Text(loc.loggedOut)),
        );
      },
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
