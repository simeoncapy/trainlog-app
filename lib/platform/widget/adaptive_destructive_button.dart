import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/widget/adaptive_widget_base.dart';


/// A compact trailing button for irreversible / destructive actions.
/// Renders a red [CupertinoButton] on Apple platforms and an [IconButton]
/// tinted with [ColorScheme.error] elsewhere.
class AdaptiveDestructiveButton extends AdaptiveWidget {
  final VoidCallback onPressed;

  const AdaptiveDestructiveButton({super.key, required this.onPressed});

  @override
  Widget buildMaterial(BuildContext context) => IconButton(
        icon: Icon(
          Icons.delete_forever_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: onPressed,
      );

  @override
  Widget buildCupertino(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.destructiveRed,
        ),
      );
}
