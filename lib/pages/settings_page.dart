import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          children: [
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  settings.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
