import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Reusable wizard progress header.
///
/// Shows a fractional "STEP x / y" label (optionally flanked by [leading] and
/// [trailing] widgets, e.g. back/close buttons) above a segmented horizontal
/// bar mapping total steps vs. the active step. Both the label and the bar
/// are derived from [currentStep] / [totalSteps], so the widget adapts
/// automatically when steps are added or removed.
class WizardStepIndicator extends StatelessWidget {
  const WizardStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.leading,
    this.trailing,
  })  : assert(totalSteps > 0),
        assert(currentStep >= 0 && currentStep < totalSteps);

  /// Zero-based index of the active step.
  final int currentStep;

  /// Total number of steps in the wizard.
  final int totalSteps;

  /// Optional widget shown on the left of the step label (e.g. back button).
  final Widget? leading;

  /// Optional widget shown on the right of the step label (e.g. close button).
  final Widget? trailing;

  static const double _segmentHeight = 4;
  static const double _segmentSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final label = Text(
      loc.addTripStepProgress(currentStep + 1, totalSteps),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (leading != null) leading!,
            Expanded(child: Center(child: label)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < totalSteps; i++) ...[
              if (i > 0) const SizedBox(width: _segmentSpacing),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _segmentHeight,
                  decoration: BoxDecoration(
                    color: i <= currentStep ? cs.primary : cs.outline,
                    borderRadius: BorderRadius.circular(_segmentHeight / 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
