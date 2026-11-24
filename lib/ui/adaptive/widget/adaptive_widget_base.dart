import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Base class for widgets that render different implementations per platform.
/// Avoids scattering [Platform] checks throughout UI code.
abstract class AdaptiveWidget extends StatelessWidget {
  const AdaptiveWidget({super.key});

  Widget buildMaterial(BuildContext context);
  Widget buildCupertino(BuildContext context);

  static bool get isApple => AppPlatform.isApple;

  @override
  Widget build(BuildContext context) =>
      isApple ? buildCupertino(context) : buildMaterial(context);
}
