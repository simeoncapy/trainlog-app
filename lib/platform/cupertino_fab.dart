
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/navigation/nav_models.dart';

class CupertinoFloatingActionButton extends StatelessWidget {
  final AppPrimaryAction action;

  const CupertinoFloatingActionButton({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final hasLabel = action.label != null && action.label!.trim().isNotEmpty;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: action.onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hasLabel ? 14 : 10,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 20),
              if (hasLabel) ...[
                const SizedBox(width: 8),
                Text(
                  action.label!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
