import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// One operator line of a grouped card: logo, name (with optional subtitle)
/// and a trailing action or indicator.
class OperatorRow extends StatelessWidget {
  const OperatorRow({
    super.key,
    required this.name,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            OperatorLogo(name: name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Operator logo, falling back to the app [Monogram] when no logo is known
/// (e.g. custom operators created by the user).
class OperatorLogo extends StatelessWidget {
  const OperatorLogo({super.key, required this.name});

  static const double _size = 40;

  final String name;

  @override
  Widget build(BuildContext context) {
    final trainlog = context.read<TrainlogProvider>();

    if (trainlog.hasOperatorLogo(name)) {
      return SizedBox(
        width: _size,
        height: _size,
        child: withOperatorLogoBg(
          context,
          trainlog.getOperatorImage(name, maxWidth: _size, maxHeight: _size),
          radius: 8,
        ),
      );
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: FittedBox(child: Monogram(username: name, highlight: false)),
    );
  }
}
