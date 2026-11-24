import 'package:flutter/cupertino.dart';

/// One action of a [CupertinoContextMenu] in the app's font: Flutter's
/// [CupertinoContextMenuAction] draws San Francisco, the app uses Hanken
/// Grotesk on iOS too. Closes the menu, then runs [onPressed].
class AppContextMenuAction extends StatelessWidget {
  const AppContextMenuAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final family = CupertinoTheme.of(context).textTheme.textStyle.fontFamily;
    return CupertinoContextMenuAction(
      trailingIcon: icon,
      isDestructiveAction: isDestructive,
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        onPressed();
      },
      // Only the family: the action keeps its size and its colour (red when
      // destructive).
      child: Text(
        label,
        style: TextStyle(fontFamily: family, letterSpacing: 0),
      ),
    );
  }
}
