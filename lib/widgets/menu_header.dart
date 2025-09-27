import 'package:flutter/material.dart';
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
    final appLocalization = AppLocalizations.of(context)!;
    final auth = context.watch<TrainlogProvider>();
    final isConnected = auth.isAuthenticated;
    final settings = context.read<SettingsProvider>();

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

          if (auth.loading) const CircularProgressIndicator(),

          if (!isConnected && !auth.loading) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: Text(appLocalization.loginButton),
              onPressed: () async {
                final result = await AuthDialog.show(
                  context,
                  type: AuthFormType.login,
                );
                if (result != null) {
                  final ok = await context.read<TrainlogProvider>().login(
                        username: result.username,
                        password: result.password,
                        settings: settings
                      );
                  final msg = ok
                      ? 'Logged in as ${result.username}'
                      : (context.read<TrainlogProvider>().error ?? 'Login failed');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: Text(appLocalization.createAccountButton),
              onPressed: () async {
                final result = await AuthDialog.show(
                  context,
                  type: AuthFormType.createAccount,
                );
                if (result != null) {
                  // TODO: call your sign-up endpoint when available
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account creation not implemented yet')),
                  );
                }
              },
            ),
          ] else if (isConnected) ...[
            Text(appLocalization.menuHello(auth.username ?? ''),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(appLocalization.logoutButton),
              onPressed: () async {
                await context.read<TrainlogProvider>().logout(settings: settings);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
