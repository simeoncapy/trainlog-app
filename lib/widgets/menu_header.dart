import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/auth_dialog.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({
    super.key,
  });
  final isConnected = false;

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trainlog.me',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          if (!isConnected) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AuthDialog.show(
                  context,
                  type: AuthDialogType.login,
                );
                if (result != null) {
                  // TODO: handle login with result.username & result.password
                }
              },
              label: Text(appLocalization.loginButton), 
              icon: Icon(Icons.login),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AuthDialog.show(
                  context,
                  type: AuthDialogType.createAccount,
                );
                if (result != null) {
                  // TODO: handle account creation with result.email, result.username, result.password
                }
              },
              label: Text(appLocalization.createAccountButton), 
              icon: Icon(Icons.person_add_alt),
            ),
          ]
          else
          ElevatedButton.icon(
            onPressed: () {
                // TODO: logout
            },
            label: Text(appLocalization.logoutButton), 
            icon: Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}