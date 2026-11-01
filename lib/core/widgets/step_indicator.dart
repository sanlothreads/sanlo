import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A compact progress header used at the top of the three-step order flow.
///
/// Renders [totalSteps] horizontal segments — filled indigo for steps up to and
/// including [currentStep], muted grey for the remaining steps — followed by a
/// caption line such as "Step 1 of 3 · Your details".
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.label,
  });

  /// The 1-based index of the active step.
  final int currentStep;

  /// Total number of steps in the flow.
  final int totalSteps;

  /// Short label describing the current step (e.g. "Your details").
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < totalSteps; i++) ...<Widget>[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: (i < currentStep)
                        ? AppColors.primary
                        : AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
              ),
              if (i < totalSteps - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Step $currentStep of $totalSteps · $label',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
