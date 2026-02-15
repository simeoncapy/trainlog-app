import 'package:flutter/widgets.dart';
import 'package:trainlog_app/navigation/cupertino_shell.dart';
import 'package:trainlog_app/navigation/material_shell.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class PlatformShell extends StatelessWidget {
  const PlatformShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isApple ? const CupertinoShell() : const MaterialShell();
  }
}
