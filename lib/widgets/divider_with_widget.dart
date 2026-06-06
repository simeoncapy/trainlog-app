import 'package:flutter/material.dart';

class DividerWithWidget extends StatelessWidget {
  final Widget child;

  const DividerWithWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            endIndent: 8,
            color: cs.outlineVariant,
          ),
        ),
        child,
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            indent: 8,
            color: cs.outlineVariant,
          ),
        ),
      ],
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DividerWithWidget(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
      ),
    );
  }
}